# Databricks notebook source
"""Pipeline por fuente: bootstrap tipado de Bronce, Plata y Oro temporal.

El despliegue inyecta un contrato inmutable. No hay JDBC, CDC ni datos sinteticos.
Un segundo run falla antes de sobrescribir objetos. Cada capa verifica tipos/filas.
"""
import json
from datetime import datetime, timezone
import uuid

PLAN = None  # injected
MARKER = None  # injected


def execute(spark):
    if PLAN is None or MARKER is None:
        raise RuntimeError('Ejecutar solo el notebook renderizado por el despliegue')
    spark.conf.set('spark.sql.ansi.enabled', 'true')
    run = uuid.uuid4().hex
    audit = PLAN['catalog'] + '.audit01.credicresa_ejecuciones_bronce'

    def trace(entity, layer, status, code):
        spark.createDataFrame([(run, datetime.now(timezone.utc), entity, layer, status, code)],
                              'run STRING, utc TIMESTAMP, entity STRING, layer STRING, status STRING, code STRING'
                              ).write.mode('append').saveAsTable(audit)

    # No alterar un despliegue previo al volver a ejecutar el job manualmente.
    for entity in PLAN['entities']:
        for name in entity['objects'].values():
            if spark.catalog.tableExists(name):
                raise RuntimeError('Objeto existente: ' + name)
    for layer in ('bronze','silver','gold'):
        for entity in PLAN['entities']:
            name = entity['objects'][layer]
            schema = ', '.join(f'`{col}` {kind}' for col, kind in entity['columns'].items())
            path = f"/Volumes/{PLAN['catalog']}/{layer}/credicresa_archivos_{layer}/{MARKER}/{entity['entity']}"
            trace(entity['entity'], layer, 'STARTED', 'BOOTSTRAP')
            try:
                if layer == 'bronze':
                    df = spark.createDataFrame([], schema)
                else:
                    previous = 'bronze' if layer == 'silver' else 'silver'
                    df = spark.table(entity['objects'][previous])
                # Snapshots Parquet; fail-if-exists evita reemplazar datos.
                df.write.mode('error').parquet(path)
                spark.sql(f"CREATE VIEW {name} COMMENT '{MARKER}' AS SELECT * FROM read_files('{path}', format => 'parquet', schema => '{schema}')")
                actual = spark.table(name)
                expected_schema = spark.createDataFrame([], schema).schema
                if [(f.name, f.dataType) for f in actual.schema] != [(f.name, f.dataType) for f in expected_schema]:
                    raise RuntimeError('Esquema remoto no coincide')
                if actual.count() != df.count():
                    raise RuntimeError('Conteos de capa no coinciden')
                trace(entity['entity'], layer, 'VERIFIED', 'TEMPORAL_NO_CERTIFICADO' if layer == 'gold' else 'BOOTSTRAP_EMPTY')
            except Exception as exc:
                trace(entity['entity'], layer, 'FAILED', type(exc).__name__)
                raise
    return {'status':'VERIFIED', 'views':3*len(PLAN['entities']), 'rows':0,
            'gold_status':'TEMPORAL_NO_CERTIFICADO', 'audit_run':run}


if __name__ == '__main__':
    dbutils.notebook.exit(json.dumps(execute(spark)))
