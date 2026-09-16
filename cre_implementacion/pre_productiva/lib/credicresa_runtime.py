"""Runtime Databricks para snapshots CRESA tipados en Parquet."""
from pathlib import Path
import json
import re
import uuid
from datetime import date, datetime, timezone
from cresa_contracts import entities, contract, ddl, quote, PERIOD
from credicresa_medallion import targets, layer_contracts

OWNER = "CRESA credicresa pre_productiva"
CATALOG = "cresa"
SOURCE_SCHEMA = "landing"
BRONZE_SCHEMA = "bronze"

def settings(dbutils):
    values = {}
    for name, default in (("period", ""), ("bootstrap", "false"), ("dry_run", "false"),
                          ("seed_format", "csv"), ("delimiter", ","), ("table_filter", ""), ("input_batch", "")):
        dbutils.widgets.text(name, default)
        values[name] = dbutils.widgets.get(name).strip()
    values["bootstrap"] = values["bootstrap"].lower() == "true"
    values["dry_run"] = values["dry_run"].lower() == "true"
    if not values["bootstrap"]:
        if not PERIOD.fullmatch(values["period"]):
            raise ValueError("period obligatorio: YYYY-MM o YYYY-MM-DD")
        date.fromisoformat(values["period"] if len(values["period"]) == 10 else values["period"] + "-01")
        if not re.fullmatch(r"[a-f0-9]{32}", values["input_batch"]):
            raise ValueError("input_batch debe identificar un lote cargado por credicresa_procesar_periodo.ps1")
    elif values["period"]:
        raise ValueError("bootstrap no acepta periodo de datos")
    if values["seed_format"] not in {"csv", "parquet"}:
        raise ValueError("seed_format debe ser csv o parquet")
    if len(values["delimiter"]) != 1:
        raise ValueError("delimiter debe tener un caracter")
    return values

def selected(root, values):
    layer_contracts(root)
    regex = re.compile(values["table_filter"]) if values["table_filter"] else None
    configs = [(p,c) for p,c in entities(root) if c.get("enabled") and (not regex or regex.search(c["source_table"]))]
    if not configs:
        raise ValueError("Filtro sin entidades")
    for _, cfg in configs:
        contract(cfg)
    return configs

def fqn(schema, table):
    return ".".join(quote(value) for value in (CATALOG, schema, table))

def assert_owned(spark, schema, table):
    name = fqn(schema, table)
    if not spark.catalog.tableExists(name):
        return False
    metadata = spark.catalog.getTable(name)
    if metadata.tableType != "VIEW" or metadata.description != OWNER:
        raise ValueError(f"Objeto existente sin marca de propiedad CRESA: {name}")
    return True

def expected_schema(spark, cfg):
    return spark.createDataFrame([], ddl(cfg)).schema

def same_schema(actual, expected):
    return [(f.name.lower(), f.dataType.simpleString()) for f in actual] == [
        (f.name.lower(), f.dataType.simpleString()) for f in expected]

def typed(spark, frame, cfg):
    from pyspark.sql import functions as F
    names = [name for name, _ in contract(cfg)]
    actual = {name.lower(): name for name in frame.columns}
    if len(actual) != len(frame.columns) or set(actual) != set(names):
        raise ValueError(f"{cfg['source_table']}: columnas incompatibles; faltan={sorted(set(names)-set(actual))}, sobran={sorted(set(actual)-set(names))}")
    if same_schema(frame.schema, expected_schema(spark, cfg)):
        return frame.select(*[F.col(quote(actual[name])).alias(name) for name in names])
    expressions = []
    failures = []
    for name, kind in contract(cfg):
        field = F.col(quote(actual[name]))
        converted = F.expr(f"try_cast({quote(actual[name])} AS {kind})")
        failures.append(F.sum(F.when(field.isNotNull() & converted.isNull(), 1).otherwise(0)).alias(name))
        expressions.append(converted.alias(name))
    counts = frame.agg(*failures).first().asDict()
    bad = {name: count for name, count in counts.items() if count}
    if bad:
        raise ValueError(f"{cfg['source_table']}: conversiones invalidas (conteos, sin datos personales): {bad}")
    result = frame.select(*expressions)
    if not same_schema(result.schema, expected_schema(spark, cfg)):
        raise ValueError("El esquema convertido no coincide con el contrato")
    return result

def publish(spark, frame, cfg, schema, table, path):
    assert_owned(spark, schema, table)
    frame.write.format("parquet").mode("error").save(path)
    spark.sql(f"CREATE OR REPLACE VIEW {fqn(schema, table)} COMMENT '{OWNER}' AS SELECT * FROM read_files('{path}', format => 'parquet', schema => '{ddl(cfg)}', schemaEvolutionMode => 'none')")
    if not same_schema(spark.table(fqn(schema, table)).schema, expected_schema(spark, cfg)):
        raise RuntimeError(f"Esquema publicado incorrecto: {schema}.{table}")

def prepare_source(spark, dbutils, root, values):
    configs = selected(root, values)
    # Validar todas las entradas antes de escribir cualquier entidad del periodo.
    frames = []
    for _, cfg in configs:
        table = cfg["source_table"]
        exists = assert_owned(spark, SOURCE_SCHEMA, "credicresa_" + table + "_landing")
        if values["bootstrap"]:
            if exists:
                frame = typed(spark, spark.table(fqn(SOURCE_SCHEMA, "credicresa_" + table + "_landing")), cfg)
            else:
                frame = spark.createDataFrame([], ddl(cfg))
        else:
            path = f"/Volumes/{CATALOG}/landing/credicresa_input/{values['period']}/{values['input_batch']}/{table}"
            dbutils.fs.ls(path)  # Un archivo ausente o un error de permisos debe detener la carga.
            reader = spark.read.format(values["seed_format"])
            if values["seed_format"] == "csv":
                reader = reader.option("header", "true").option("inferSchema", "false").option("mode", "FAILFAST").option("sep", values["delimiter"])
            frame = typed(spark, reader.load(path), cfg)
        frames.append((cfg, frame))
    results = []
    batch = uuid.uuid4().hex
    period = values["period"] or "bootstrap"
    for cfg, frame in frames:
        table = cfg["source_table"]
        rows = frame.count()
        if not values["dry_run"]:
            path = f"/Volumes/{CATALOG}/landing/credicresa_data/{table}/{period}/{batch}"
            publish(spark, frame, cfg, SOURCE_SCHEMA, "credicresa_" + table + "_landing", path)
        results.append({"table": table, "rows": rows})
    return results

def ingest(spark, root, values):
    from pyspark.sql import functions as F
    configs = selected(root, values)
    cp = f"{CATALOG}.audit01.credicresa_ingestion_runs"
    detail_cp = f"{CATALOG}.audit01.credicresa_ingestion_table_runs"
    columns_cp = f"{CATALOG}.audit01.credicresa_ingestion_columns"
    for name in (cp, detail_cp, columns_cp):
        if not spark.catalog.tableExists(name):
            raise RuntimeError(f"Falta control plane: {name}")
    run_id = uuid.uuid4().hex
    now = datetime.now(timezone.utc)
    source_name = "credicresa"
    period = values["period"] or "bootstrap"
    base = f"/Volumes/{CATALOG}/bronze/credicresa_data"
    run_schema = "run_id string, source_name string, status string, started_at timestamp, finished_at timestamp, table_total int, table_succeeded int, table_failed int, total_rows bigint, dry_run boolean, table_filter string, source_config string, output_base_path string, error_message string, created_by string, updated_at timestamp"
    user = spark.sql("SELECT current_user()").first()[0]
    record = [run_id, source_name, "RUNNING", now, None, len(configs), 0, 0, 0, values["dry_run"], values["table_filter"], str(root / "config/sources/credicresa.yml"), base, None, user, now]
    if not values["dry_run"]:
        spark.createDataFrame([tuple(record)], run_schema).write.mode("append").saveAsTable(cp)
    results = []
    detail_rows = []
    field_rows = []
    detail_schema = "run_id string, source_name string, config_path string, source_table string, target_table string, status string, row_count bigint, column_count int, started_at timestamp, finished_at timestamp, detail string, output_path string"
    field_schema = "run_id string, source_name string, source_schema string, source_table string, target_table string, ordinal int, column_name string, spark_data_type string, nullable boolean, present_in_yaml boolean, characterized_at timestamp"
    error = None
    try:
        for _,cfg in configs:
            table = cfg["source_table"]
            target = cfg["target"]["bronze_table"]
            frame = typed(spark, spark.table(fqn(SOURCE_SCHEMA, "credicresa_" + table + "_landing")), cfg)
            rows = frame.count()
            path = f"{base}/{table}/{period}/{run_id}"
            if not values["dry_run"]:
                publish(spark, frame, cfg, BRONZE_SCHEMA, target, path)
                finish = datetime.now(timezone.utc)
                details = [(run_id, source_name, str(_), table, target, "LOADED", rows, len(frame.columns), now, finish, json.dumps({"period":period}), path)]
                schema = "run_id string, source_name string, config_path string, source_table string, target_table string, status string, row_count bigint, column_count int, started_at timestamp, finished_at timestamp, detail string, output_path string"
                detail_rows.extend(details)
                fields = [(run_id, source_name, SOURCE_SCHEMA, "credicresa_" + table + "_landing", target, i, f.name, f.dataType.simpleString(), f.nullable, True, finish) for i,f in enumerate(frame.schema,1)]
                schema = "run_id string, source_name string, source_schema string, source_table string, target_table string, ordinal int, column_name string, spark_data_type string, nullable boolean, present_in_yaml boolean, characterized_at timestamp"
                field_rows.extend(fields)
            results.append({"table":table,"rows":rows})
    except Exception as exc:
        detail_rows.append((run_id, source_name, str(_), table, target, "ERROR", None, None, now, datetime.now(timezone.utc), "Error de ingesta; revisar tarea y contrato", None))
        error = exc
        raise
    finally:
        if not values["dry_run"]:
            if detail_rows:
                spark.createDataFrame(detail_rows, detail_schema).write.mode("append").saveAsTable(detail_cp)
            if field_rows:
                spark.createDataFrame(field_rows, field_schema).write.mode("append").saveAsTable(columns_cp)
            record[2] = "FAILED" if error else "SUCCEEDED"
            record[4] = datetime.now(timezone.utc)
            record[6:9] = [len(results), 1 if error else 0, sum(row["rows"] for row in results)]
            record[13] = "Error de ingesta; consultar tarea y contrato" if error else None
            record[15] = record[4]
            from delta.tables import DeltaTable
            final = spark.createDataFrame([tuple(record)], run_schema)
            DeltaTable.forName(spark, cp).alias("t").merge(final.alias("s"), "t.run_id=s.run_id").whenMatchedUpdateAll().execute()
    return {"run_id":run_id, "period":period, "entities":len(results), "rows":sum(r["rows"] for r in results)}

def verify(spark, root, values):
    layer_contracts(root)
    # Pruebas de conversion con datos sinteticos, sin modificar objetos remotos.
    probe = {"source_table":"synthetic", "columns":{"include":["id"],"types":{"id":"BIGINT"}}}
    value = "9007199254740993"
    converted = typed(spark, spark.createDataFrame([(value,)], "id STRING"), probe)
    if converted.first()[0] != int(value):
        raise RuntimeError("Perdida de precision en conversion BIGINT")
    rejected = False
    try:
        typed(spark, spark.createDataFrame([("invalid",)], "id STRING"), probe)
    except ValueError:
        rejected = True
    if not rejected:
        raise RuntimeError("No se rechazo una conversion invalida")
    probe["columns"]["types"]["id"] = "DECIMAL(5,2)"
    rejected = False
    try:
        typed(spark, spark.createDataFrame([("1000.00",)], "id STRING"), probe)
    except ValueError:
        rejected = True
    if not rejected:
        raise RuntimeError("No se rechazo desbordamiento decimal")
    results = []
    for _,cfg in selected(root, values):
        for schema,table in targets(cfg):
            if not assert_owned(spark,schema,table):
                raise ValueError(f"Falta objeto {schema}.{table}")
            frame = spark.table(fqn(schema,table))
            if not same_schema(frame.schema, expected_schema(spark,cfg)):
                raise ValueError(f"Tipos incompatibles: {schema}.{table}")
            if schema in {"silver", "gold"}:
                previous = "bronze" if schema == "silver" else "silver"
                upstream = spark.table(fqn(previous, "credicresa_" + cfg["source_table"] + "_" + previous))
                if frame.count() != upstream.count():
                    raise ValueError(f"Filas incompatibles: {schema}.{table}")
            results.append({"schema":schema,"table":table,"attributes":len(frame.columns)})
    return {"status":"SUCCEEDED", "objects":len(results), "attribute_checks":sum(r["attributes"] for r in results)}
