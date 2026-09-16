"""Resuelve metadatos UC y lista archivos de rutas activas; no lee filas."""
import json
import re
from inspeccionar_maestros_cli import OUT, get


def main():
    refs, paths = {}, {}
    for file in (OUT / 'dlh_cresa').rglob('*.txt'):
        source = file.read_text(encoding='utf-8')
        source = re.sub(r'/\*.*?\*/', '', source, flags=re.S)
        source = re.sub(r'--[^\n]*', '', source)
        for table in re.findall(r'\bdlh_cresa\.(?:bronze|src)\.\w+', source, re.I):
            refs.setdefault(table.lower(), {'table': table, 'notebooks': []})['notebooks'].append(file.name)
        for path in re.findall(r'/Volumes/[^`\s\x22\x27;]+', source):
            paths.setdefault(path, []).append(file.name)
    data = {'tables': [], 'paths': [], 'scope': 'Persona y Producto exportados; no incluye aun cierre de cartera ni vistas anidadas'}
    for ref in refs.values():
        try:
            metadata = get('dlh_cresa', '/api/2.1/unity-catalog/tables/' + ref['table'])
            ref['metadata'] = metadata
        except Exception as exc:
            ref['error'] = str(exc)
        data['tables'].append(ref)
        print(ref['table'], 'ERROR' if 'error' in ref else 'OK', flush=True)
        (OUT / 'fuentes_metadata.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    for path, notebooks in paths.items():
        ref = {'path': path, 'notebooks': notebooks, 'files': []}
        # API directories para carpetas; si la referencia es archivo, listar su padre.
        pending = [path.rsplit('/', 1)[0] if path.endswith('.parquet') else path.rstrip('/')]
        try:
            while pending:
                directory = pending.pop()
                token = None
                while True:
                    params = {'page_token': token} if token else None
                    result = get('dlh_cresa', '/api/2.0/fs/directories' + directory, params)
                    for entry in result.get('contents', []):
                        if path.endswith('.parquet') and directory == path.rsplit('/', 1)[0] and entry['path'] != path:
                            continue
                        if entry.get('is_directory'):
                            pending.append(entry['path'])
                        else:
                            ref['files'].append(entry)
                    token = result.get('next_page_token')
                    if not token:
                        break
            ref['bytes'] = sum(f.get('file_size', 0) for f in ref['files'])
            ref['count_files'] = len(ref['files'])
            ref['rows'] = None
        except Exception as exc:
            ref['error'] = str(exc)
        data['paths'].append(ref)
        (OUT / 'fuentes_metadata.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
        print(path, 'ERROR' if 'error' in ref else 'OK', flush=True)


if __name__ == '__main__':
    main()
