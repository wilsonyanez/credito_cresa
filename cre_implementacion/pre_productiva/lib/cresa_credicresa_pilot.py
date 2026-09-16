"""CRESA: plan local, bootstrap Medallion y reversa conservando datos.

Mutaciones sin reintentos; manifiesto previo, propiedad exclusiva y LOG JSONL.
"""
import argparse
import base64
from datetime import datetime, timezone
import json
import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import traceback
import tempfile
from urllib.parse import urlencode, urlparse
import uuid

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'lib'))
import cresa_contracts as contracts
import yaml

CATALOG = 'cresa'
JOB = 'JOB_CRE_00_CARGA_DATOS_CREDI_CRESA'
PIPELINE = 'credicresa_pip_credito_oro'
LAYERS = ('bronze', 'silver', 'gold')
SCHEMAS = ('audit01', 'landing', *LAYERS)
WORKSPACE = '/Workspace/Users/wilsonyanez@hotmail.com/.git/cresa/credicresa'
AUDIT = CATALOG + '.audit01.credicresa_ejecuciones_bronce'

# Solo mensajes propios; no registrar salidas de CLI ni valores de credenciales.
SAFE_ERRORS = {
    'Existe manifiesto: revisar antes de desplegar', 'WorkspaceUrl HTTPS requerido',
    'Perfil y warehouse requeridos', 'Perfil no coincide con WorkspaceUrl',
    'Destino no coincide con manifiesto', 'WorkspacePath no coincide con manifiesto',
    'ClusterId requerido', 'WorkspacePath invalido', 'Catalogo existente: no se adopta',
    'AUTH_PROFILE_FAILED', 'MANIFEST_PLAN_MISMATCH', 'MANIFEST_MISSING',
    'DATABRICKS_API_FAILED', 'SQL_FAILED', 'JOB_FAILED',
}


def failure_detail(exc):
    message = str(exc)
    if isinstance(exc, FileNotFoundError):
        return 'Archivo o ejecutable no encontrado: ' + (str(exc.filename) if exc.filename else 'ruta no disponible')
    return message if message in SAFE_ERRORS or re.fullmatch(r'RESUME_[A-Z_]+', message) else type(exc).__name__


def resolved_type(original, classification):
    if original:
        return contracts.spark_type(original)
    if classification not in (None, 'numerico', 'alfanumerico'):
        raise ValueError('Clasificacion desconocida')
    return 'DECIMAL(10,2)' if classification == 'numerico' else 'STRING'


def make_plan(selection, event):
    contracts.sync_types(check=True)
    configurations = sorted(contracts.entities(), key=lambda item: item[1]['source_table'])
    names = [cfg['source_table'] for _, cfg in configurations]
    chosen = selection.split(',') if selection else names[:14]
    if not chosen or len(chosen) > 14 or len(set(chosen)) != len(chosen):
        raise ValueError('Seleccion debe contener entre 1 y 14 entidades unicas')
    for name in chosen:
        if name not in names:
            event(3, 'ERROR', 'ENTITY_MISSING', entity=name)
            raise ValueError('Entidad sin contrato')
    inventory, entities = [], []
    for _, cfg in configurations:
        name = cfg['source_table']
        contracts.quote(name)
        columns = dict(contracts.contract(cfg))
        item = dict(entity=name, selected=name in chosen, attributes=len(columns))
        inventory.append(item)
        event(4, 'SELECTED' if item['selected'] else 'EXCLUDED', 'CONTRACT_VALIDATED', **item)
        if item['selected']:
            entities.append(dict(entity=name, columns=columns, objects={
                layer: f'{CATALOG}.{layer}.credicresa_{name}_{layer}'
                for layer in LAYERS}))
    return dict(catalog=CATALOG, entities=entities, inventory=inventory,
                database_objects=len(entities)*3+1, job=JOB, pipeline=PIPELINE)


def atomic_json(path, value):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value, indent=2), encoding='utf-8')
    os.replace(temporary, path)


class Pilot:
    def __init__(self, args):
        self.args, self.run, self.state = args, uuid.uuid4().hex, {}
        self.directory = ROOT / '.deployment'
        self.directory.mkdir(exist_ok=True)
        self.manifest = self.directory / ('cresa_credito_' + CATALOG + '.json')
        self.log_path = Path(args.log_path).resolve() if args.log_path else ROOT / 'scripts/cresa_credicresa_desplegar.log'
        if not self.log_path.is_relative_to(ROOT):
            raise ValueError('LogPath fuera del paquete')
        self.log_path.parent.mkdir(parents=True, exist_ok=True)

    def event(self, phase, status, code, **fields):
        record = dict(utc=datetime.now(timezone.utc).isoformat(), run=self.run,
                      mode=self.args.command, phase=phase, status=status, code=code, **fields)
        with self.log_path.open('a', encoding='utf-8') as stream:
            stream.write(json.dumps(record, ensure_ascii=False) + '\n')

    def save(self):
        atomic_json(self.manifest, self.state)

    def load_manifest(self):
        if not self.manifest.is_file():
            self.event(6, 'ERROR', 'MANIFEST_MISSING', manifest=str(self.manifest))
            print(f'CRESA: falta el manifiesto de despliegue: {self.manifest}. '
                  'La reversa requiere el manifiesto original del destino. '
                  'No se ejecutaron operaciones remotas. No renombrar manifiestos de otros destinos.',
                  flush=True)
            raise FileNotFoundError('MANIFEST_MISSING')
        self.state = json.loads(self.manifest.read_text(encoding='utf-8'))

    def api(self, method, path, body=None):
        command = ['databricks', 'api', method.lower(), path, '--profile', self.args.auth_name, '--output', 'json']
        payload_path = None
        try:
            if body is not None:
                with tempfile.NamedTemporaryFile(mode='w', suffix='.json', dir=self.directory,
                                                 encoding='utf-8', delete=False) as stream:
                    json.dump(body, stream)
                    payload_path = Path(stream.name)
                command += ['--json', '@' + str(payload_path)]
            result = subprocess.run(command, capture_output=True, text=True, encoding='utf-8', timeout=120)
        finally:
            if payload_path is not None:
                payload_path.unlink(missing_ok=True)
        if result.returncode:
            self.event(5, 'ERROR', 'API_FAILED', method=method, endpoint=path.split('?')[0])
            raise RuntimeError('DATABRICKS_API_FAILED')
        return json.loads(result.stdout) if result.stdout.strip() else {}

    def all_pages(self, path, key):
        items, seen, base = [], set(), path
        while True:
            response = self.api('GET', path)
            items.extend(response.get(key, []))
            token = response.get('next_page_token')
            if not token:
                if response.get('has_more'):
                    raise RuntimeError('INCOMPLETE_INVENTORY')
                return items
            if token in seen:
                raise RuntimeError('REPEATED_PAGE_TOKEN')
            seen.add(token)
            path = base + ('&' if '?' in base else '?') + urlencode({'page_token':token})

    def ready(self):
        args = self.args
        parsed = urlparse(args.workspace_url or '')
        if parsed.scheme != 'https' or not parsed.hostname or parsed.path not in ('', '/') or parsed.username or parsed.query or parsed.fragment:
            raise ValueError('WorkspaceUrl HTTPS requerido')
        if not args.auth_name or not re.fullmatch(r'[A-Za-z0-9_-]+', args.sql_warehouse_id or ''):
            raise ValueError('Perfil y warehouse requeridos')
        result = subprocess.run(['databricks', 'auth', 'describe', '--profile', args.auth_name, '--output', 'json'],
                                capture_output=True, text=True, encoding='utf-8', timeout=30)
        if result.returncode:
            raise RuntimeError('AUTH_PROFILE_FAILED')
        description = json.loads(result.stdout)
        host = description.get('host') or description.get('details', {}).get('host')
        if not isinstance(host, str) or host.rstrip('/') != args.workspace_url.rstrip('/'):
            raise ValueError('Perfil no coincide con WorkspaceUrl')
        if self.state.get('workspace_url') and self.state['workspace_url'] != args.workspace_url.rstrip('/'):
            raise ValueError('Destino no coincide con manifiesto')
        if self.state.get('workspace_path') and self.state['workspace_path'] != args.workspace_path:
            raise ValueError('WorkspacePath no coincide con manifiesto')

    def sql(self, statement):
        response = self.api('POST', '/api/2.0/sql/statements', dict(
            warehouse_id=self.args.sql_warehouse_id, statement=statement, wait_timeout='0s'))
        statement_id = response['statement_id']
        self.event(3, 'STARTED', 'SQL_STATEMENT', statement_id=statement_id)
        deadline = time.monotonic() + self.args.timeout_seconds
        while response['status']['state'] in ('PENDING', 'RUNNING'):
            if time.monotonic() > deadline:
                raise TimeoutError('SQL_TIMEOUT')
            time.sleep(2)
            response = self.api('GET', '/api/2.0/sql/statements/' + statement_id)
        if response['status']['state'] != 'SUCCEEDED':
            raise RuntimeError('SQL_FAILED')
        self.event(3, 'VERIFIED', 'SQL_SUCCEEDED', statement_id=statement_id)

    def render(self):
        source = (ROOT / 'notebooks' / (PIPELINE + '.py')).read_text(encoding='utf-8-sig')
        return source.replace('PLAN = None  # injected', 'PLAN = ' + repr(self.state['plan'])).replace(
            'MARKER = None  # injected', 'MARKER = ' + repr(self.state['marker']))

    def owned_views(self):
        catalogs = self.all_pages('/api/2.1/unity-catalog/catalogs', 'catalogs')
        if CATALOG not in {c['name'] for c in catalogs}:
            return {}
        catalog = self.api('GET', '/api/2.1/unity-catalog/catalogs/' + CATALOG)
        if catalog.get('comment') != self.state['marker']:
            raise ValueError('Catalogo ajeno')
        expected = {name for entity in self.state['plan']['entities'] for name in entity['objects'].values()}
        views = {}
        schemas = self.all_pages('/api/2.1/unity-catalog/schemas?' + urlencode({'catalog_name':CATALOG}), 'schemas')
        for schema in schemas:
            if schema['name'] not in {name.split('.')[1] for name in expected}:
                continue
            tables = self.all_pages('/api/2.1/unity-catalog/tables?' + urlencode(
                {'catalog_name':CATALOG, 'schema_name':schema['name']}), 'tables')
            for table in tables:
                name = table['full_name']
                if name in expected:
                    if table.get('comment') != self.state['marker'] or table.get('table_type') != 'VIEW':
                        raise ValueError('Vista ajena o tipo inesperado')
                    views[name] = table
        return views

    def deploy(self, plan):
        if self.manifest.exists():
            raise ValueError('Existe manifiesto: revisar antes de desplegar')
        # Leer los artefactos y validar el notebook antes de modificar el destino.
        notebook_source = (ROOT / 'notebooks' / (PIPELINE + '.py')).read_text(encoding='utf-8-sig')
        compile(notebook_source, PIPELINE + '.py', 'exec')
        artifacts = [(artifact.relative_to(ROOT).as_posix(), artifact.read_bytes())
                     for folder in ('config', 'lib', 'sql')
                     for artifact in sorted((ROOT / folder).rglob('*'))
                     if artifact.is_file() and artifact.suffix in ('.yml', '.json', '.py', '.sql')]
        self.ready()
        if self.args.cluster_id and not re.fullmatch(r'[A-Za-z0-9_-]+', self.args.cluster_id):
            raise ValueError('ClusterId requerido')
        workspace = self.args.workspace_path
        if not workspace or not workspace.startswith('/Workspace/') or any(c in workspace for c in "'\\<>\n\r") or '..' in workspace.split('/'):
            raise ValueError('WorkspacePath invalido')
        if CATALOG in {c['name'] for c in self.all_pages('/api/2.1/unity-catalog/catalogs', 'catalogs')}:
            raise ValueError('Catalogo existente: no se adopta')
        self.state = dict(marker='CRESA_PILOT_' + self.run, plan=plan,
                          workspace_url=self.args.workspace_url.rstrip('/'), workspace_path=workspace,
                          notebook=workspace + '/notebooks/' + self.run + '/' + PIPELINE, status='PREPARING')
        self.save()
        marker = self.state['marker']
        rendered = notebook_source.replace('PLAN = None  # injected', 'PLAN = ' + repr(plan)).replace(
            'MARKER = None  # injected', 'MARKER = ' + repr(marker))
        self.sql(f"CREATE CATALOG {CATALOG} COMMENT '{marker}'")
        for schema_name in SCHEMAS:
            self.sql(f"CREATE SCHEMA {CATALOG}.{schema_name} COMMENT '{marker}'")
        for layer in LAYERS:
            schema = f'{CATALOG}.{layer}'
            self.sql(f"CREATE VOLUME {schema}.credicresa_archivos_{layer} COMMENT '{marker}'")
        self.sql(f"CREATE TABLE {AUDIT} (run STRING, utc TIMESTAMP, entity STRING, layer STRING, status STRING, code STRING) USING DELTA COMMENT '{marker}'")
        self.finish_deploy(plan, artifacts, rendered)

    def finish_deploy(self, plan, artifacts, rendered, existing=None):
        workspace = self.state['workspace_path']
        marker = self.state['marker']
        existing = existing or set()
        # Configuracion y codigo directamente bajo el proyecto; sin pre_productiva remoto.
        for folder in ('config/ingestion', 'config/jobs', 'config/sources', 'notebooks', 'lib', 'sql'):
            self.api('POST', '/api/2.0/workspace/mkdirs', {'path':workspace + '/' + folder})
        for relative_path, content in artifacts:
            destination = workspace + '/' + relative_path
            if destination.removeprefix('/Workspace') in existing:
                continue
            self.api('POST', '/api/2.0/workspace/mkdirs', {'path':destination.rsplit('/', 1)[0]})
            self.api('POST', '/api/2.0/workspace/import', dict(path=destination, format='AUTO',
                overwrite=False, content=base64.b64encode(content).decode()))
        self.api('POST', '/api/2.0/workspace/mkdirs', {'path':self.state['notebook'].rsplit('/', 1)[0]})
        self.state['notebook_sha256'] = hashlib.sha256(rendered.replace('\r\n', '\n').strip().encode()).hexdigest()
        self.save()
        self.api('POST', '/api/2.0/workspace/import', dict(path=self.state['notebook'], format='SOURCE',
                 language='PYTHON', overwrite=False, content=base64.b64encode(rendered.encode()).decode()))
        task = dict(task_key=PIPELINE, max_retries=0, notebook_task={'notebook_path':self.state['notebook']})
        if self.args.cluster_id:
            task['existing_cluster_id'] = self.args.cluster_id
        job = self.api('POST', '/api/2.2/jobs/create', dict(name=JOB, max_concurrent_runs=1,
            tags={'cresa_owner':marker, 'client':'cresa', 'project':'credicresa'}, tasks=[task]))
        self.state['job_id'] = job['job_id']
        self.save()
        run = self.api('POST', '/api/2.2/jobs/run-now', {'job_id':job['job_id'], 'idempotency_token':self.run})
        self.state['run_id'] = run['run_id']
        self.save()
        self.event(6, 'STARTED', 'JOB_RUN', job_id=job['job_id'], run_id=run['run_id'])
        deadline = time.monotonic() + self.args.timeout_seconds
        while True:
            result = self.api('GET', '/api/2.2/jobs/runs/get?' + urlencode({'run_id':run['run_id']}))
            state = result['state']
            if state['life_cycle_state'] in ('TERMINATED', 'SKIPPED', 'INTERNAL_ERROR'):
                if state.get('result_state') != 'SUCCESS':
                    raise RuntimeError('JOB_FAILED')
                break
            if time.monotonic() > deadline:
                raise TimeoutError('JOB_TIMEOUT_RUN_NOT_CANCELLED')
            time.sleep(5)
        if len(self.owned_views()) != len(plan['entities'])*3:
            raise RuntimeError('VIEWS_INCOMPLETE')
        for layer in LAYERS:
            volume = f'{CATALOG}.{layer}.credicresa_archivos_{layer}'
            if self.api('GET', '/api/2.1/unity-catalog/volumes/' + volume).get('comment') != marker:
                raise RuntimeError('VOLUME_VERIFICATION_FAILED')
        control = self.api('GET', '/api/2.1/unity-catalog/tables/' + AUDIT)
        if control.get('comment') != marker or control.get('data_source_format') != 'DELTA':
            raise RuntimeError('CONTROL_VERIFICATION_FAILED')
        self.state['status'] = 'VERIFIED'
        self.save()
        self.event(6, 'VERIFIED', 'DEPLOY_VERIFIED', objects=plan['database_objects'])

    def resume(self):
        self.load_manifest()
        state = self.state
        plan = make_plan(','.join(e['entity'] for e in state['plan']['entities']), lambda *a, **k: None)
        marker = state['marker']
        if (state.get('status') != 'PREPARING' or state.get('job_id') or state.get('run_id')
                or state['plan'] != plan or not re.fullmatch(r'CRESA_PILOT_[a-f0-9]{32}', marker)):
            raise ValueError('RESUME_STATE_UNSUPPORTED')
        expected = state['workspace_path'] + '/notebooks/' + marker.removeprefix('CRESA_PILOT_') + '/' + PIPELINE
        if state['notebook'] != expected:
            raise ValueError('RESUME_NOTEBOOK_PATH_MISMATCH')
        rendered = self.render()
        compile(rendered, PIPELINE + '.py', 'exec')
        artifacts = [(p.relative_to(ROOT).as_posix(), p.read_bytes())
                     for folder in ('config', 'lib', 'sql') for p in sorted((ROOT / folder).rglob('*'))
                     if p.is_file() and p.suffix in ('.yml', '.json', '.py', '.sql')
                     and p.name != 'cresa_credicresa_pilot.py']
        self.ready()
        for endpoint in ['catalogs/' + CATALOG] + ['schemas/' + CATALOG + '.' + layer for layer in SCHEMAS] + [
                'volumes/' + CATALOG + '.' + layer + '.credicresa_archivos_' + layer for layer in LAYERS]:
            if self.api('GET', '/api/2.1/unity-catalog/' + endpoint).get('comment') != marker:
                raise ValueError('RESUME_OWNER_MISMATCH')
        for layer in SCHEMAS:
            tables = self.all_pages('/api/2.1/unity-catalog/tables?' + urlencode(
                {'catalog_name': CATALOG, 'schema_name': layer}), 'tables')
            if layer == 'audit01':
                if (len(tables) != 1 or tables[0].get('full_name') != AUDIT
                        or tables[0].get('comment') != marker or tables[0].get('data_source_format') != 'DELTA'):
                    raise ValueError('RESUME_AUDIT_MISMATCH')
            elif tables:
                raise ValueError('RESUME_TABLES_EXIST')
        jobs = self.all_pages('/api/2.2/jobs/list', 'jobs')
        if any(j.get('settings', {}).get('name') == JOB or
               j.get('settings', {}).get('tags', {}).get('cresa_owner') == marker for j in jobs):
            raise ValueError('RESUME_JOB_EXISTS')
        existing = {}
        pending = [state['workspace_path'].removeprefix('/Workspace')]
        visited = set()
        while pending:
            folder = pending.pop()
            if folder in visited:
                raise ValueError('RESUME_WORKSPACE_INVENTORY_INVALID')
            visited.add(folder)
            listing = self.api('GET', '/api/2.0/workspace/list?' + urlencode({'path': folder}))
            if listing.get('has_more') or listing.get('next_page_token'):
                raise ValueError('RESUME_WORKSPACE_INVENTORY_INVALID')
            for obj in listing.get('objects', []):
                path = obj['path'].removeprefix('/Workspace')
                if not path.startswith(folder + '/'):
                    raise ValueError('RESUME_WORKSPACE_INVENTORY_INVALID')
                if obj['object_type'] == 'DIRECTORY':
                    pending.append(path)
                else:
                    existing[path] = obj['object_type']
        if state['notebook'].removeprefix('/Workspace') in existing:
            raise ValueError('RESUME_NOTEBOOK_EXISTS')
        for relative, content in artifacts:
            target = state['workspace_path'].removeprefix('/Workspace') + '/' + relative
            if target in existing:
                if existing[target] != 'FILE':
                    raise ValueError('RESUME_FILE_TYPE_MISMATCH')
                exported = self.api('GET', '/api/2.0/workspace/export?' + urlencode({'path': target, 'format': 'AUTO'}))
                if base64.b64decode(exported['content']) != content:
                    raise ValueError('RESUME_FILE_CONTENT_MISMATCH')
        self.event(6, 'VERIFIED', 'RESUME_PREFLIGHT_VERIFIED', existing_files=len(existing))
        self.finish_deploy(plan, artifacts, rendered, set(existing))

    def reverse(self):
        plan = self.state['plan']
        selection = ','.join(e['entity'] for e in plan['entities'])
        expected_plan = make_plan(selection, lambda *a, **k: None)
        # Variante historica cerrada: solo cambia la ontologia conocida, nunca los contratos.
        import copy
        historical_plan = copy.deepcopy(expected_plan)
        historical_plan['job'] = 'credicresa_job_credito_oro'
        historical_layers = ('bronce', 'plata', 'oro')
        for entity in historical_plan['entities']:
            entity['objects'] = {
                layer: f"{CATALOG}.credicresa_datos_{layer}.credicresa_{entity['entity']}_{layer}"
                for layer in historical_layers}
        historical = plan == historical_plan
        if historical:
            expected_plan = historical_plan
        if plan != expected_plan:
            differences = sorted(key for key in set(plan) | set(expected_plan)
                                 if plan.get(key) != expected_plan.get(key))
            self.event(6, 'ERROR', 'MANIFEST_PLAN_MISMATCH', fields=differences)
            print('CRESA: el manifiesto no coincide con la convencion o los contratos actuales. '
                  'Campos diferentes: ' + ', '.join(differences) + '. '
                  'La reversa se detuvo antes de acceder a Databricks. '
                  'Un despliegue historico requiere una reversa compatible con sus nombres originales; '
                  'no editar el manifiesto para sustituirlos por los nombres nuevos.', flush=True)
            raise ValueError('MANIFEST_PLAN_MISMATCH')
        marker = self.state['marker']
        if not re.fullmatch(r'CRESA_PILOT_[a-f0-9]{32}', marker):
            raise ValueError('Marca invalida')
        expected = self.state['workspace_path'] + ('/' if historical else '/notebooks/') + marker.removeprefix('CRESA_PILOT_') + '/' + PIPELINE
        if self.state['notebook'] != expected:
            raise ValueError('Ruta de notebook alterada')
        if historical and not re.fullmatch(r'[a-f0-9]{64}', self.state.get('notebook_sha256', '')):
            raise ValueError('La reversa historica requiere el hash original del notebook')
        if self.args.command == 'reverse-plan':
            self.event(6, 'PLANNED', 'LOCAL_REVERSE_PLAN', entities=len(plan['entities']))
            print(f"Plan local de reversa validado: catalogo {CATALOG}, job {expected_plan['job']}. Sin operaciones remotas.")
            return
        self.ready()
        views = self.owned_views()
        jobs = self.all_pages('/api/2.2/jobs/list', 'jobs')
        own = []
        for job in jobs:
            settings = job.get('settings', {})
            owned = settings.get('tags', {}).get('cresa_owner') == marker
            if job['job_id'] == self.state.get('job_id') and not owned:
                raise ValueError('Job perdio propiedad')
            if owned:
                if settings.get('name') != expected_plan['job']:
                    raise ValueError('Nombre de job alterado')
                own.append(job['job_id'])
        for job_id in own:
            if self.all_pages('/api/2.2/jobs/runs/list?' + urlencode({'job_id':job_id, 'active_only':'true'}), 'runs'):
                raise ValueError('Job con run activo')
        parent = self.state['notebook'].rsplit('/', 1)[0]
        listing = self.api('GET', '/api/2.0/workspace/list?' + urlencode({'path':parent}))
        present = any(o['path'].removeprefix('/Workspace') == self.state['notebook'].removeprefix('/Workspace') for o in listing.get('objects', []))
        if present:
            exported = self.api('GET', '/api/2.0/workspace/export?' + urlencode({'path':self.state['notebook'], 'format':'SOURCE'}))
            actual_hash = hashlib.sha256(base64.b64decode(exported['content']).decode().replace('\r\n', '\n').strip().encode()).hexdigest()
            expected_hash = self.state.get('notebook_sha256') or hashlib.sha256(self.render().replace('\r\n', '\n').strip().encode()).hexdigest()
            if actual_hash != expected_hash:
                raise ValueError('Notebook modificado')
        self.event(6, 'PLANNED', 'REVERSE_INVENTORY', views=sorted(views), jobs=own, notebook=present,
                   retained=['catalog', 'schemas', 'volumes', 'parquet',
                             CATALOG + '.credicresa_control_bronce.credicresa_ejecuciones_bronce' if historical else AUDIT])
        if self.args.command == 'inspect':
            return
        for job_id in own:
            self.api('POST', '/api/2.2/jobs/delete', {'job_id':job_id})
        for layer in reversed(historical_layers if historical else LAYERS):
            for entity in plan['entities']:
                name = entity['objects'][layer]
                if name in views:
                    self.sql('DROP VIEW ' + name)
        if present:
            self.api('POST', '/api/2.0/workspace/delete', {'path':self.state['notebook'], 'recursive':False})
        remaining_jobs = self.all_pages('/api/2.2/jobs/list', 'jobs')
        listing = self.api('GET', '/api/2.0/workspace/list?' + urlencode({'path':parent}))
        if self.owned_views() or any(j['job_id'] in own for j in remaining_jobs) or any(
            o['path'].removeprefix('/Workspace') == self.state['notebook'].removeprefix('/Workspace') for o in listing.get('objects', [])):
            raise RuntimeError('REVERSE_INCOMPLETE')
        self.state['status'] = 'REVERSED_DATA_RETAINED'
        self.save()
        self.event(6, 'VERIFIED', 'REVERSE_VERIFIED')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['plan', 'deploy', 'reverse-plan', 'inspect', 'reverse', 'resume'])
    for argument in ('auth-name', 'workspace-url', 'workspace-path', 'sql-warehouse-id', 'cluster-id', 'entities'):
        parser.add_argument('--' + argument)
    parser.add_argument('--catalog-name', default='cresa')
    parser.set_defaults(workspace_path=WORKSPACE)
    parser.add_argument('--log-path')
    parser.add_argument('--timeout-seconds', type=int, default=7200)
    args = parser.parse_args()
    global CATALOG, AUDIT
    contracts.quote(args.catalog_name)
    CATALOG = args.catalog_name
    AUDIT = CATALOG + '.audit01.credicresa_ejecuciones_bronce'
    pilot = Pilot(args)
    lock = pilot.directory / 'cresa_credito.lock'
    acquired = False
    try:
        with lock.open('x') as stream:
            stream.write(str(os.getpid()))
        acquired = True
        pilot.event(1, 'STARTED', 'LOCAL_PATHS_NORMALIZED')
        if args.command in ('plan', 'deploy'):
            if not (ROOT.parent / 'muestras_consultas_bases_datos/consultas_bases_datos').exists():
                pilot.event(1, 'WARNING', 'FLAT_FILES_MISSING_BOOTSTRAP_ONLY')
            plan = make_plan(args.entities, pilot.event)
            atomic_json(pilot.directory / 'cresa_credito_plan.json', plan)
            (pilot.directory / 'cresa_credito_plan.yml').write_text(yaml.safe_dump(plan, sort_keys=False), encoding='utf-8')
            if args.command == 'deploy':
                pilot.deploy(plan)
            else:
                pilot.event(6, 'VERIFIED', 'LOCAL_PLAN_ONLY', objects=plan['database_objects'])
                print('Plan local: 34 contratos; ' + str(plan['database_objects']) + ' objetos. Sin ejecucion remota.')
        elif args.command == 'resume':
            pilot.resume()
        else:
            pilot.load_manifest()
            pilot.reverse()
        return 0
    except Exception as exc:
        detail = failure_detail(exc)
        frames = traceback.extract_tb(exc.__traceback__)
        location = [{'file':Path(frame.filename).name, 'line':frame.lineno, 'function':frame.name}
                    for frame in frames]
        pilot.event(6, 'ERROR', 'OPERATION_FAILED', error_type=type(exc).__name__, detail=detail,
                    location=location)
        print('CRESA: ' + detail + '. LOG: ' + str(pilot.log_path), flush=True)
        return 1
    finally:
        if acquired:
            lock.unlink()


if __name__ == '__main__':
    sys.exit(main())
