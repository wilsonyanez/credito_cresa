"""Inventario de lectura de notebooks y metadatos; nunca ejecuta SQL ni ETL."""
import base64
import json
import re
import subprocess
from pathlib import Path
from urllib.parse import urlencode

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tests' / 'contexto_03' / 'remoto'


def get(profile, endpoint, params=None):
    url = endpoint + ('?' + urlencode(params) if params else '')
    result = subprocess.run(['databricks', 'api', 'get', url, '--profile', profile, '--output', 'json'], capture_output=True, text=True, encoding='utf-8', timeout=60)
    if result.returncode:
        raise RuntimeError(result.stderr.strip())
    return json.loads(result.stdout)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    evidence = []
    for profile, folder in [('dlh_cresa', 'DLHCRESA01'), ('dev-dlh_cresa', 'DEV-DLHCRESA01')]:
        for domain in ['PERSONA_DIM', 'PRODUCTO_DIM']:
            path = f'/Shared/{folder}/TRANSFORMACIONES/DIMENSIONES_GENERALES/{domain}'
            for directory in [path, path + '/PROCESOS']:
                item = {'profile': profile, 'path': directory}
                try:
                    listing = get(profile, '/api/2.0/workspace/list', {'path': directory})
                    item['listing'] = listing
                    for obj in listing.get('objects', []):
                        if obj['object_type'] != 'NOTEBOOK':
                            continue
                        notebook = {'profile': profile, 'path': obj['path']}
                        try:
                            exported = get(profile, '/api/2.0/workspace/export', {'path': obj['path']})
                            source = base64.b64decode(exported['content']).decode('utf-8')
                            if re.search(r'dapi-[\w-]+|(?i:password|client_secret|access_token)\s*[=:]\s*[\x22\x27][^\x22\x27]+', source):
                                notebook['error'] = 'Posible secreto: no se guarda el codigo; requiere revision segura.'
                            else:
                                local = OUT / profile / domain / (Path(obj['path']).name + '.txt')
                                local.parent.mkdir(parents=True, exist_ok=True)
                                local.write_text(source, encoding='utf-8')
                                notebook['local'] = str(local.relative_to(ROOT))
                        except Exception as exc:
                            notebook['error'] = str(exc)
                        evidence.append(notebook)
                except Exception as exc:
                    item['error'] = str(exc)
                evidence.append(item)
                (OUT / 'inventario.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf-8')
                print(profile, directory, 'ERROR' if 'error' in item else 'OK', flush=True)


if __name__ == '__main__':
    main()
