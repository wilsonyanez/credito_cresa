"""Extrae evidencia de los Excel de procesos sin dependencias externas."""
import csv
import hashlib
import json
import posixpath
import re
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
NS = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}


def extract(path):
    with ZipFile(path) as z:
        strings = []
        if 'xl/sharedStrings.xml' in z.namelist():
            strings = [''.join(t.text or '' for t in n.findall('.//s:t', NS)) for n in ET.fromstring(z.read('xl/sharedStrings.xml')).findall('s:si', NS)]
        rels = {r.attrib['Id']: r.attrib['Target'] for r in ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))}
        for sheet in ET.fromstring(z.read('xl/workbook.xml')).findall('s:sheets/s:sheet', NS):
            rid = sheet.attrib['{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id']
            target = rels[rid]
            target = target.lstrip('/') if target.startswith('/') else posixpath.normpath('xl/' + target)
            tree = ET.fromstring(z.read(target))
            for row in tree.findall('s:sheetData/s:row', NS):
                cells, formulas = {}, {}
                for cell in row.findall('s:c', NS):
                    col = ''.join(c for c in cell.attrib['r'] if c.isalpha())
                    value = cell.find('s:v', NS)
                    value = value.text if value is not None else ''
                    if cell.attrib.get('t') == 's':
                        value = strings[int(value)]
                    elif cell.attrib.get('t') == 'inlineStr':
                        value = ''.join(t.text or '' for t in cell.findall('s:is//s:t', NS))
                    cells[col] = value or ''
                    formula = cell.find('s:f', NS)
                    if formula is not None:
                        formulas[col] = formula.text
                if any(cells.values()):
                    yield {'archivo': path.name, 'hoja': sheet.attrib['name'], 'fila': int(row.attrib['r']), 'celdas': cells, 'formulas': formulas}


def main():
    rows = []
    for name in ('12_Procesos_Credito_Cartera.xlsx', '13_Procesos_Producto_Cliente.xlsx'):
        rows.extend(extract(ROOT / 'docs' / name))
    out = ROOT / 'tests' / 'contexto_03'
    out.mkdir(parents=True, exist_ok=True)
    (out / 'excel_evidencia.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')
    manifest = []
    for name in sorted({r['archivo'] for r in rows}):
        path = ROOT / 'docs' / name
        with ZipFile(path) as z:
            merges = {n: [m.attrib['ref'] for m in ET.fromstring(z.read(n)).findall('s:mergeCells/s:mergeCell', NS)] for n in z.namelist() if re.fullmatch(r'xl/worksheets/sheet\d+\.xml', n)}
        manifest.append({'archivo': name, 'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'celdas_combinadas': merges})
    (out / 'excel_manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    with (out / 'procesos_fuentes.csv').open('w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['archivo', 'hoja', 'fila', 'L_Ruta_Proceso', 'M_Nombre_Proceso_JOB', 'R_Tabla', 'T_Dominio_Coleccion'])
        for row in rows:
            if row['hoja'] not in ('Procesos | JOBs', 'Diciconario Azurian') or row['fila'] == 1:
                continue
            writer.writerow([row['archivo'], row['hoja'], row['fila']] + [row['celdas'].get(c, '') for c in ('L', 'M', 'R', 'T')])
    domain_rows = [r for r in rows if r['hoja'] == 'Diciconario Azurian' and r['celdas'].get('T') in ('Cliente', 'Producto')]
    lines = ['# Evidencia de entidades por dominio', '', 'Generado desde `13_Procesos_Producto_Cliente.xlsx`, hoja `Diciconario Azurian`. Referencias documentales; existencia, formato, columnas y dependencia física pendientes de inspección remota.', '', '| Fila Excel | Dominio | Entidad en R | Proceso en M |', '|---|---|---|---|']
    for r in domain_rows:
        c = r['celdas']
        lines.append(f"| {r['fila']} | {c['T']} | `{c.get('R', '')}` | `{c.get('M', '')}` |")
    lines += ['', 'Las rutas completas L/M y el resto de hojas se conservan en `excel_evidencia.json`. No se rellenan celdas vacías ni se infiere dominio a partir de hojas sin T. Los rangos combinados y hashes se conservan en `excel_manifest.json`.', '']
    (out / 'entidades_por_dominio.md').write_text('\n'.join(lines), encoding='utf-8')
    print(json.dumps({'filas_no_vacias': len(rows), 'salida': str(out)}, ensure_ascii=False))


if __name__ == '__main__':
    main()
