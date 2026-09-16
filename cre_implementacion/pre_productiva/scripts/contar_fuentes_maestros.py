"""Cuenta filas de fuentes identificadas mediante un SELECT, sin escrituras SQL."""
import json
import subprocess
from inspeccionar_maestros_cli import OUT


def main():
    data = json.loads((OUT / 'fuentes_metadata.json').read_text(encoding='utf-8'))
    queries = []
    for item in data['tables']:
        name = item['table']
        queries.append(f"SELECT '{name}' entidad, COUNT(*) filas FROM {name}")
    for item in data['paths']:
        name = item['path']
        queries.append(f"SELECT '{name}' entidad, COUNT(*) filas FROM parquet.`{name}`")
    request = {'warehouse_id': '28f84c7f2b5b7255', 'statement': '\nUNION ALL\n'.join(queries), 'wait_timeout': '10s', 'on_wait_timeout': 'CONTINUE', 'disposition': 'INLINE', 'format': 'JSON_ARRAY'}
    payload = OUT / 'conteos_solicitud.json'
    payload.write_text(json.dumps(request), encoding='utf-8')
    result = subprocess.run(['databricks', 'api', 'post', '/api/2.0/sql/statements', '--json', '@' + str(payload), '--profile', 'dlh_cresa', '--output', 'json'], capture_output=True, text=True, encoding='utf-8', timeout=90)
    if result.returncode:
        raise RuntimeError(result.stderr)
    response = json.loads(result.stdout)
    (OUT / 'conteos_respuesta.json').write_text(json.dumps(response, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(response, ensure_ascii=False))


if __name__ == '__main__':
    main()
