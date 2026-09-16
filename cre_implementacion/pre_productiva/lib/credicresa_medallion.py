"""CRESA: snapshots temporales Medallion, sin certificacion de negocio."""
import uuid
from datetime import datetime, timezone
from cresa_contracts import read_yaml, ROOT, entities
from credicresa_quality import policy, rule_plan, diagnose
import json


def layer_contracts(root=ROOT):
    for layer in ('silver', 'gold'):
        cfg = read_yaml(root / 'config' / layer / 'credicresa.yml')
        expected = dict(config_version=1, layer=layer, status='temporal',
                        load_strategy='full_snapshot', format='parquet',
                        business_rules='pending_business_rule', publish_to_consumers=False)
        if cfg != expected:
            raise ValueError(f'Contrato {layer} no soportado; no habilitar reglas silenciosamente')
    policy(root)
    for _, entity in entities(root):
        rule_plan(entity)


def targets(cfg):
    return tuple((layer, 'credicresa_' + cfg['source_table'] + '_' + layer)
                 for layer in ('landing', 'bronze', 'silver', 'gold'))


def transform(spark, root, values, layer):
    from credicresa_runtime import selected, typed, publish, fqn, assert_owned
    layer_contracts(root)
    if layer not in {'silver', 'gold'}:
        raise ValueError('Capa no soportada')
    cp = 'cresa.audit01.credicresa_medallion_runs'
    if not spark.catalog.tableExists(cp):
        raise RuntimeError(f'Falta control plane: {cp}')
    quality_cp = 'cresa.audit01.credicresa_quality_results'
    if not spark.catalog.tableExists(quality_cp):
        raise RuntimeError(f'Falta control plane: {quality_cp}')
    source = 'bronze' if layer == 'silver' else 'silver'
    run_id = uuid.uuid4().hex
    period = values['period'] or 'bootstrap'
    results = []
    for _, cfg in selected(root, values):
        table = 'credicresa_' + cfg['source_table'] + '_' + layer
        source_table = 'credicresa_' + cfg['source_table'] + '_' + source
        started = datetime.now(timezone.utc)
        rows = 0
        status = 'FAILED'
        try:
            if not assert_owned(spark, source, source_table):
                raise ValueError(f'Falta entrada propia {source}.{table}')
            frame = typed(spark, spark.table(fqn(source, source_table)), cfg)
            # No normalizar texto ni deduplicar sin reglas aprobadas de CRESA.
            rows = frame.count()
            diagnostics = diagnose(cfg, fqn(source, source_table),
                                   lambda sql: spark.sql(sql).first().asDict(),
                                   bootstrap=values.get('bootstrap', False))
            if diagnostics[0]['total_rows'] != rows:
                raise RuntimeError('La fuente cambio durante el diagnostico; reprocesar snapshot')
            if not values['dry_run']:
                metrics = [(run_id, period, values['input_batch'], layer, table,
                            r['rule_id'], r['type'], json.dumps(r['columns']),
                            r['total_rows'], r['affected_rows'], r['status'], r['action'],
                            'candidate', 'temporal', datetime.now(timezone.utc)) for r in diagnostics]
                quality_schema = 'run_id STRING, period STRING, input_batch STRING, layer STRING, entity STRING, rule_id STRING, rule_type STRING, columns_json STRING, total_rows BIGINT, affected_rows BIGINT, status STRING, action STRING, key_authority STRING, certification_status STRING, evaluated_at TIMESTAMP'
                spark.createDataFrame(metrics, quality_schema).write.format('delta').mode('append').saveAsTable(quality_cp)
                path = f"/Volumes/cresa/{layer}/credicresa_data/{cfg['source_table']}/{period}/{run_id}"
                publish(spark, frame, cfg, layer, table, path)
            status = 'SUCCEEDED'
            results.append({'table': table, 'rows': rows, 'diagnostics': diagnostics})
        finally:
            if not values['dry_run']:
                record = (run_id, period, values['input_batch'], layer, table, status,
                          rows, 'temporal', 'pending_business_rule', started, datetime.now(timezone.utc))
                schema = 'run_id STRING, period STRING, input_batch STRING, layer STRING, entity STRING, status STRING, row_count BIGINT, certification_status STRING, business_rules STRING, started_at TIMESTAMP, finished_at TIMESTAMP'
                spark.createDataFrame([record], schema).write.format('delta').mode('append').saveAsTable(cp)
    return {'layer': layer, 'entities': len(results), 'rows': sum(r['rows'] for r in results),
            'certification_status': 'temporal', 'published_to_consumers': False,
            'quality_warnings': sum(r['status'] == 'WARNING' for item in results for r in item['diagnostics']),
            'pending_rules': sum(r['status'] == 'PENDING' for item in results for r in item['diagnostics'])}
