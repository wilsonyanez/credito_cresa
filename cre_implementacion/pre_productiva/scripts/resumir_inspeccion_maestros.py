"""Conserva resultados de la consulta ya ejecutada y genera su informe."""
import json
from datetime import datetime, timezone
from inspeccionar_maestros_cli import OUT, get


def main():
    response = get('dlh_cresa', '/api/2.0/sql/statements/01f1b13b-0c1c-1f24-b35f-e89818fdceb7')
    if response['status']['state'] != 'SUCCEEDED' or response['manifest'].get('truncated'):
        raise RuntimeError('Conteo incompleto')
    (OUT / 'conteos_respuesta.json').write_text(json.dumps(response, ensure_ascii=False, indent=2), encoding='utf-8')
    counts = dict(response['result']['data_array'])
    data = json.loads((OUT / 'fuentes_metadata.json').read_text(encoding='utf-8'))
    for item in data['paths']:
        if 'error' in item:
            result = get('dlh_cresa', '/api/2.0/fs/directories' + item['path'].rstrip('/'))
            if result.get('next_page_token') or any(f.get('is_directory') for f in result['contents']):
                raise RuntimeError('Reintento necesita recursion/paginacion')
            item['files'] = result['contents']
            item['bytes'] = sum(f['file_size'] for f in item['files'])
            item['count_files'] = len(item['files'])
            item['previous_error'] = item.pop('error')
        item['rows'] = int(counts[item['path']])
    data['measured_at_utc'] = datetime.now(timezone.utc).isoformat()
    (OUT / 'fuentes_metadata.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    lines = ['# Medición remota de fuentes — Persona y Producto', '', 'Consulta de lectura: `01f1b13b-0c1c-1f24-b35f-e89818fdceb7`, SUCCEEDED. Fecha de recuperación UTC: ' + data['measured_at_utc'], '', '## Parquet activo en volúmenes', '', '| Ruta | Archivos | Bytes | Filas |', '|---|---:|---:|---:|']
    for item in data['paths']:
        lines.append(f"| `{item['path']}` | {item['count_files']} | {item['bytes']} | {item['rows']} |")
    lines += ['', '## Tablas fuente Delta administradas', '', '| Tabla | Filas |', '|---|---:|']
    for item in data['tables']:
        lines.append(f"| `{item['table']}` | {counts[item['table']]} |")
    lines += ['', 'Los bytes corresponden exclusivamente a cuatro archivos Parquet listados. No incluyen las tablas Delta ni el cierre pendiente de Crédito/Cartera. Conteos y listado no están fijados a un snapshot común: repetir sobre un corte estable antes de copiar. Los bytes de una exportación Parquet de Delta no se deducen de estos conteos.', '', 'Desarrollo: identidad verificada, pero el catálogo dev_dlh_cresa devuelve falta de USE CATALOG. Las rutas suministradas de Persona y Producto no existen. No se copiaron datos ni se crearon objetos remotos.', '']
    (OUT / 'MEDICION_FUENTES.md').write_text('\n'.join(lines), encoding='utf-8')
    print('Informe generado:', OUT / 'MEDICION_FUENTES.md')


if __name__ == '__main__':
    main()
