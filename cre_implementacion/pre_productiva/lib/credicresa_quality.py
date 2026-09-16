"""Reglas diagnosticas adaptadas de ALMAR; solo conteos, nunca datos personales."""
import re
from cresa_contracts import ROOT, contract, quote, read_yaml

FAMILIES = ['empty_source_alert', 'not_null_key', 'duplicate_declared_key',
            'blank_string', 'surrounding_spaces', 'declared_text_length']


def policy(root=ROOT):
    cfg = read_yaml(root / 'config/quality/credicresa.yml')
    expected = dict(config_version=1, action='flag_only', key_authority='candidate',
                    duplicate_null_handling='exclude_incomplete_keys',
                    rules=FAMILIES, certification='temporal', publication=False)
    if cfg != expected:
        raise ValueError('Politica de calidad no soportada; revisar contrato antes de cambiar acciones')
    return cfg


def rule_plan(cfg):
    columns = dict(contract(cfg))
    result = [dict(rule_id='EMPTY_SOURCE', type='empty_source_alert', columns=[], predicate=None)]
    for kind in ('primary_key', 'natural_key'):
        key = cfg.get(kind, {})
        names = key.get('columns', [])
        if key.get('pending_definition') or not names:
            result.append(dict(rule_id=kind.upper()+'_PENDING', type='pending_business_rule', columns=[], predicate=None))
            continue
        if not isinstance(names, list) or len(set(names)) != len(names) or any(n not in columns for n in names):
            raise ValueError(f"{cfg['source_table']}: llave {kind} invalida")
        result.append(dict(rule_id=kind.upper()+'_NULL', type='not_null_key', columns=names,
                           predicate=' OR '.join(quote(n)+' IS NULL' for n in names)))
        result.append(dict(rule_id=kind.upper()+'_DUPLICATE', type='duplicate_declared_key', columns=names, predicate=None))
    for name, dtype in columns.items():
        if dtype != 'STRING':
            continue
        q = quote(name)
        for suffix, kind, condition in (
            ('BLANK', 'blank_string', f"{q} IS NOT NULL AND TRIM({q}) = ''"),
            ('SPACES', 'surrounding_spaces', f'{q} IS NOT NULL AND LENGTH({q}) <> LENGTH(TRIM({q}))')):
            result.append(dict(rule_id=name+'_'+suffix, type=kind, columns=[name], predicate=condition))
        original = cfg['columns'].get('source_types', {}).get(name, '')
        size = re.fullmatch(r'(?:N?VARCHAR|N?CHAR)\((\d+)\)', original, re.I)
        if size:
            result.append(dict(rule_id=name+'_LENGTH', type='declared_text_length', columns=[name],
                               predicate=f'LENGTH({q}) > {int(size[1])}'))
    return result


def queries(cfg, table):
    # table es un identificador generado por el runtime, nunca SQL de un YAML.
    if not re.fullmatch(r'`[A-Za-z_]\w*`(?:\.`[A-Za-z_]\w*`){0,2}', table):
        raise ValueError('Identificador de tabla invalido')
    rules = rule_plan(cfg)
    aggregates = ['COUNT(*) AS total_rows']
    for index, rule in enumerate(rules):
        if rule['predicate']:
            aggregates.append(f"COALESCE(SUM(CASE WHEN {rule['predicate']} THEN 1 ELSE 0 END), 0) AS m{index}")
    duplicates = {}
    for index, rule in enumerate(rules):
        if rule['type'] == 'duplicate_declared_key':
            names = ', '.join(quote(n) for n in rule['columns'])
            complete = ' AND '.join(quote(n)+' IS NOT NULL' for n in rule['columns'])
            duplicates[index] = (f'SELECT COALESCE(SUM(n), 0) AS affected_rows FROM '
                                 f'(SELECT COUNT(*) AS n FROM {table} WHERE {complete} '
                                 f'GROUP BY {names} HAVING COUNT(*) > 1) duplicates')
    return rules, f"SELECT {', '.join(aggregates)} FROM {table}", duplicates


def diagnose(cfg, table, query, bootstrap=False):
    """query devuelve la primera fila como dict; no modifica el origen."""
    rules, aggregate_sql, duplicate_sql = queries(cfg, table)
    counts = query(aggregate_sql)
    total = int(counts['total_rows'])
    output = []
    for index, rule in enumerate(rules):
        if rule['type'] == 'pending_business_rule':
            affected, status = None, 'PENDING'
        elif rule['type'] == 'empty_source_alert':
            # Es un evento de tabla, no un numero de registros invalidos.
            affected = 0
            status = 'EXPECTED_EMPTY' if not total and bootstrap else ('WARNING' if not total else 'PASS')
        else:
            affected = int(query(duplicate_sql[index])['affected_rows']) if index in duplicate_sql else int(counts[f'm{index}'])
            status = 'NOT_EVALUATED' if not total else ('WARNING' if affected else 'PASS')
        output.append(dict(rule_id=rule['rule_id'], type=rule['type'], columns=rule['columns'],
                           affected_rows=affected, total_rows=total, status=status, action='flag_only'))
    # Un PASS de reglas tecnicas no certifica un producto.
    output.append(dict(rule_id='BUSINESS_CERTIFICATION', type='pending_business_rule', columns=[],
                       affected_rows=None, total_rows=total, status='PENDING', action='flag_only'))
    return output
