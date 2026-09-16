"""Validacion local: limites y barreras ante borrados ajenos, sin APIs reales."""
import argparse
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'lib'))
import cresa_credicresa_pilot as pilot


class PilotTest(unittest.TestCase):
    def resume_session(self):
        session = self.session('resume')
        session.state['status'] = 'PREPARING'
        session.state.pop('job_id')
        session.load_manifest = Mock()
        session.finish_deploy = Mock()
        marker = session.state['marker']
        session.api = Mock(return_value={'comment': marker})
        def pages(path, key):
            if 'schema_name=audit01' in path:
                return [{'full_name': pilot.AUDIT, 'comment': marker, 'data_source_format': 'DELTA'}]
            return []
        session.all_pages = Mock(side_effect=pages)
        return session

    def test_resume_preserves_existing_structure(self):
        session = self.resume_session()
        session.resume()
        session.finish_deploy.assert_called_once()
        self.assertTrue(all(call.args[0] == 'GET' for call in session.api.call_args_list))

    def test_resume_rejects_existing_job(self):
        session = self.resume_session()
        session.state['job_id'] = 1
        with self.assertRaisesRegex(ValueError, 'RESUME_STATE_UNSUPPORTED'):
            session.resume()
        session.api.assert_not_called()
        session.finish_deploy.assert_not_called()

    def test_resume_rejects_foreign_owner(self):
        session = self.resume_session()
        session.api.return_value = {'comment': 'other'}
        with self.assertRaisesRegex(ValueError, 'RESUME_OWNER_MISMATCH'):
            session.resume()
        session.finish_deploy.assert_not_called()

    def test_api_large_body_uses_temporary_file_and_cleans_it(self):
        import json
        session = self.session()
        session.directory = pilot.ROOT / '.deployment'
        session.args.auth_name = 'test'
        observed = []
        def run(command, **kwargs):
            argument = command[command.index('--json') + 1]
            self.assertTrue(argument.startswith('@'))
            path = Path(argument[1:])
            observed.append(path)
            self.assertEqual(json.loads(path.read_text())['content'], 'x' * 50000)
            self.assertLess(len(' '.join(command)), 2000)
            return argparse.Namespace(returncode=0, stdout='{}')
        with patch.object(pilot.subprocess, 'run', side_effect=run):
            session.api = pilot.Pilot.api.__get__(session)
            session.api('POST', '/test', {'content': 'x' * 50000})
        self.assertFalse(observed[0].exists())

    def test_safe_failure_detail(self):
        self.assertEqual(pilot.failure_detail(ValueError('Existe manifiesto: revisar antes de desplegar')),
                         'Existe manifiesto: revisar antes de desplegar')
        self.assertEqual(pilot.failure_detail(RuntimeError('untrusted credential output')), 'RuntimeError')

    @classmethod
    def setUpClass(cls):
        cls.plan = pilot.make_plan(None, lambda *a, **k: None)

    def session(self, mode='reverse-plan'):
        s = object.__new__(pilot.Pilot)
        s.args = argparse.Namespace(command=mode)
        marker = 'CRESA_PILOT_' + 'a'*32
        s.state = {'marker':marker, 'workspace_path':'/Workspace/Shared/cresa_credito',
                   'notebook':'/Workspace/Shared/cresa_credito/notebooks/'+'a'*32+'/'+pilot.PIPELINE,
                   'plan':copy.deepcopy(self.plan), 'job_id':123}
        s.event = Mock()
        s.api = Mock(side_effect=AssertionError('No API esperada'))
        s.ready = Mock()
        s.save = Mock()
        return s

    def test_coverage_and_physical_limit(self):
        self.assertEqual(len(self.plan['inventory']), 34)
        self.assertEqual(sum(r['attributes'] for r in self.plan['inventory']), 451)
        self.assertEqual(self.plan['database_objects'], 43)
        self.assertEqual(sum(r['selected'] for r in self.plan['inventory']), 14)

    def test_requested_naming(self):
        self.assertEqual(self.plan['catalog'], 'cresa')
        self.assertEqual(self.plan['job'], 'JOB_CRE_00_CARGA_DATOS_CREDI_CRESA')
        self.assertEqual(set(pilot.SCHEMAS), {'audit01', 'landing', 'bronze', 'silver', 'gold'})
        for entity in self.plan['entities']:
            for layer, name in entity['objects'].items():
                self.assertEqual(name, f"cresa.{layer}.credicresa_{entity['entity']}_{layer}")
        self.assertTrue(pilot.WORKSPACE.endswith('/.git/cresa/credicresa'))

    def test_deploy_creates_requested_schemas_and_workspace_layout(self):
        session = self.session('deploy')
        session.run = 'a' * 32
        session.manifest = Mock()
        session.manifest.exists.return_value = False
        session.args = argparse.Namespace(cluster_id=None, workspace_path=pilot.WORKSPACE,
                                          workspace_url='https://example.invalid')
        session.all_pages = Mock(return_value=[])
        session.sql = Mock()
        def api(method, path, body=None):
            if path == '/api/2.2/jobs/create':
                self.assertEqual(body['name'], 'JOB_CRE_00_CARGA_DATOS_CREDI_CRESA')
                self.assertIn('/credicresa/notebooks/', body['tasks'][0]['notebook_task']['notebook_path'])
                raise RuntimeError('STOP_BEFORE_REMOTE_RUN')
            return {}
        session.api = Mock(side_effect=api)
        with self.assertRaisesRegex(RuntimeError, 'STOP_BEFORE_REMOTE_RUN'):
            session.deploy(self.plan)
        schemas = [c.args[0].split()[2] for c in session.sql.call_args_list
                   if c.args[0].startswith('CREATE SCHEMA')]
        self.assertEqual(set(schemas), {'cresa.' + name for name in pilot.SCHEMAS})
        folders = {c.args[2]['path'] for c in session.api.call_args_list
                   if c.args[1] == '/api/2.0/workspace/mkdirs'}
        for name in ('config/ingestion', 'config/jobs', 'config/sources', 'notebooks'):
            self.assertIn(pilot.WORKSPACE + '/' + name, folders)
        self.assertFalse(any('/pre_productiva/' in folder for folder in folders))

    def test_over_limit(self):
        names = ','.join(r['entity'] for r in self.plan['inventory'][:15])
        with self.assertRaises(ValueError):
            pilot.make_plan(names, Mock())

    def test_missing_entity_logged(self):
        emit = Mock()
        with self.assertRaises(ValueError):
            pilot.make_plan('inexistente', emit)
        emit.assert_any_call(3, 'ERROR', 'ENTITY_MISSING', entity='inexistente')

    def test_duplicate_rejected(self):
        with self.assertRaises(ValueError):
            pilot.make_plan('cat_almacen,cat_almacen', Mock())

    def test_preserve_existing_types(self):
        self.assertEqual(pilot.resolved_type('DECIMAL(19,4)', 'numerico'), 'DECIMAL(19,4)')
        self.assertEqual(pilot.resolved_type('VARCHAR(6)', 'numerico'), 'STRING')
        self.assertEqual(pilot.resolved_type('BIGINT', None), 'BIGINT')

    def test_default_requires_metadata(self):
        self.assertEqual(pilot.resolved_type(None, 'numerico'), 'DECIMAL(10,2)')
        self.assertEqual(pilot.resolved_type(None, 'alfanumerico'), 'STRING')
        self.assertEqual(pilot.resolved_type(None, None), 'STRING')
        with self.assertRaises(ValueError):
            pilot.resolved_type(None, 'inventada')

    def test_local_reverse_no_api(self):
        s = self.session()
        s.reverse()
        s.api.assert_not_called()
        s.ready.assert_not_called()

    def historical_session(self):
        session = self.session()
        session.state['plan']['job'] = 'credicresa_job_credito_oro'
        for entity in session.state['plan']['entities']:
            entity['objects'] = {layer: f"{pilot.CATALOG}.credicresa_datos_{layer}.credicresa_{entity['entity']}_{layer}"
                                 for layer in ('bronce', 'plata', 'oro')}
        session.state['notebook'] = session.state['notebook'].replace('/notebooks/', '/')
        session.state['notebook_sha256'] = 'b' * 64
        return session

    def test_historical_local_reverse_accepted_without_api(self):
        session = self.historical_session()
        session.reverse()
        session.ready.assert_not_called()
        session.api.assert_not_called()

    def test_historical_missing_hash_rejected(self):
        session = self.historical_session()
        del session.state['notebook_sha256']
        with self.assertRaisesRegex(ValueError, 'hash original'):
            session.reverse()
        session.api.assert_not_called()

    def test_historical_foreign_object_rejected(self):
        session = self.historical_session()
        session.state['plan']['entities'][0]['objects']['oro'] = 'other.schema.table'
        with self.assertRaisesRegex(ValueError, 'MANIFEST_PLAN_MISMATCH'):
            session.reverse()
        session.api.assert_not_called()

    def test_missing_manifest_explains_failure_without_remote_calls(self):
        session = self.session()
        session.manifest = Mock()
        session.manifest.is_file.return_value = False
        with patch('builtins.print') as output:
            with self.assertRaisesRegex(FileNotFoundError, 'MANIFEST_MISSING'):
                session.load_manifest()
        session.event.assert_called_once_with(6, 'ERROR', 'MANIFEST_MISSING',
                                              manifest=str(session.manifest))
        self.assertIn('falta el manifiesto', output.call_args.args[0])
        session.manifest.read_text.assert_not_called()
        session.api.assert_not_called()
        session.ready.assert_not_called()

    def test_load_manifest_preserves_original_state(self):
        session = self.session()
        session.manifest = Mock()
        session.manifest.is_file.return_value = True
        session.manifest.read_text.return_value = '{"marker": "original"}'
        session.load_manifest()
        self.assertEqual(session.state, {'marker': 'original'})
        session.api.assert_not_called()

    def test_tampered_manifest_rejected(self):
        s = self.session()
        s.state['plan']['entities'][0]['objects']['gold'] = 'other.schema.table'
        with self.assertRaises(ValueError):
            s.reverse()
        s.api.assert_not_called()

    def test_historical_job_reports_manifest_mismatch_before_remote_calls(self):
        session = self.session('reverse')
        session.state['plan']['job'] = 'credicresa_job_credito_oro'
        with patch('builtins.print') as output:
            with self.assertRaisesRegex(ValueError, 'MANIFEST_PLAN_MISMATCH'):
                session.reverse()
        session.event.assert_called_once_with(6, 'ERROR', 'MANIFEST_PLAN_MISMATCH', fields=['job'])
        self.assertIn('Campos diferentes: job', output.call_args.args[0])
        session.ready.assert_not_called()
        session.api.assert_not_called()

    def test_tampered_notebook_path_rejected(self):
        s = self.session()
        s.state['notebook'] = '/Workspace/Shared/other'
        with self.assertRaises(ValueError):
            s.reverse()

    def test_foreign_catalog_rejected(self):
        s = self.session('inspect')
        s.all_pages = Mock(return_value=[{'name':pilot.CATALOG}])
        s.api = Mock(return_value={'comment':'otro'})
        with self.assertRaises(ValueError):
            s.owned_views()

    def test_active_run_prevents_mutation(self):
        s = self.session('reverse')
        s.owned_views = Mock(return_value={})
        job = {'job_id':123, 'settings':{'name':pilot.JOB,'tags':{'cresa_owner':s.state['marker']}}}
        s.all_pages = Mock(side_effect=[[job], [{'run_id':456}]])
        with self.assertRaises(ValueError):
            s.reverse()
        s.api.assert_not_called()

    def test_job_lost_owner_prevents_mutation(self):
        s = self.session('reverse')
        s.owned_views = Mock(return_value={})
        s.all_pages = Mock(return_value=[{'job_id':123,'settings':{'name':pilot.JOB}}])
        with self.assertRaises(ValueError):
            s.reverse()
        s.api.assert_not_called()

    def test_missing_catalog_is_known_absence(self):
        s = self.session('inspect')
        s.all_pages = Mock(return_value=[])
        self.assertEqual(s.owned_views(), {})
        s.api.assert_not_called()

    def test_inventory_failure_is_not_absence(self):
        s = self.session('inspect')
        s.all_pages = Mock(side_effect=RuntimeError('API failed'))
        with self.assertRaises(RuntimeError):
            s.owned_views()

    def test_requested_catalog_is_used_in_plan_and_notebook(self):
        with patch.object(pilot, 'CATALOG', 'credicresa'):
            plan = pilot.make_plan('cat_almacen', Mock())
        self.assertEqual(plan['catalog'], 'credicresa')
        self.assertTrue(all(n.startswith('credicresa.') for n in plan['entities'][0]['objects'].values()))
        session = self.session()
        session.state['plan'] = plan
        rendered = session.render()
        self.assertIn("PLAN['catalog']", rendered)
        self.assertNotIn('/Volumes/cresa_credito/', rendered)
        compile(rendered, '<rendered>', 'exec')

    def test_pagination(self):
        s = self.session()
        s.api = Mock(side_effect=[{'jobs':[1], 'next_page_token':'abc'}, {'jobs':[2]}])
        self.assertEqual(s.all_pages('/jobs', 'jobs'), [1,2])
        self.assertEqual(s.api.call_args.args[1], '/jobs?page_token=abc')


if __name__ == '__main__':
    unittest.main()
