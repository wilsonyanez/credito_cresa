# Databricks notebook source
# MAGIC %md
# MAGIC # Ingesta recursiva desde una fuente recreada en Databricks
# MAGIC
# MAGIC Descubre los YAML, lee las tablas fuente internas, conserva su esquema y
# MAGIC genera datos y caracterización en Parquet.

# COMMAND ----------

from __future__ import annotations

import json
import re
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import yaml
from delta.tables import DeltaTable
from pyspark.sql import functions as F
from pyspark.sql import Row
from pyspark.sql.types import (
    BooleanType,
    IntegerType,
    LongType,
    StringType,
    StructField,
    StructType,
    TimestampType,
)
from pyspark.storagelevel import StorageLevel


dbutils.widgets.text(
    "source_config",
    "pre_productiva/config/sources/credito_cresa.yml",
    "Configuración de fuente",
)
dbutils.widgets.text("source_name", "credito_cresa", "Fuente")
dbutils.widgets.dropdown("dry_run", "false", ["true", "false"], "Solo caracterizar configuración")
dbutils.widgets.text("table_filter", "", "Filtro regex opcional")

SOURCE_CONFIG = Path(dbutils.widgets.get("source_config"))
REQUESTED_SOURCE = dbutils.widgets.get("source_name").strip()
DRY_RUN = dbutils.widgets.get("dry_run").lower() == "true"
TABLE_FILTER = dbutils.widgets.get("table_filter").strip()
RUN_ID = f"{datetime.now(timezone.utc):%Y%m%dT%H%M%SZ}_{uuid.uuid4().hex[:8]}"

IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def identifier(value: str, label: str) -> str:
    if not IDENTIFIER.fullmatch(value):
        raise ValueError(f"{label} inválido: {value!r}")
    return value


if not SOURCE_CONFIG.is_file():
    raise FileNotFoundError(
        f"No existe {SOURCE_CONFIG}. Ejecute desde la raíz del Git folder o ajuste source_config."
    )
SOURCE_CONFIG = SOURCE_CONFIG.resolve()
REPO_ROOT = SOURCE_CONFIG.parents[3]

with SOURCE_CONFIG.open(encoding="utf-8-sig") as stream:
    source_cfg = yaml.safe_load(stream)

if not source_cfg.get("enabled", False):
    raise ValueError(f"La fuente {SOURCE_CONFIG} está deshabilitada")
if source_cfg.get("source_name") != REQUESTED_SOURCE:
    raise ValueError(
        f"source_name solicitado={REQUESTED_SOURCE!r} no coincide con la configuración"
    )
if source_cfg.get("source_type") != "databricks":
    raise ValueError("Este notebook requiere source_type=databricks")

input_cfg = source_cfg["input"]
discovery = source_cfg["discovery"]
output = source_cfg["output"]
execution = source_cfg["execution"]
control_plane = source_cfg["control_plane"]

for value, label in [
    (REQUESTED_SOURCE, "source_name"),
    (input_cfg["catalog"], "input.catalog"),
    (input_cfg["schema"], "input.schema"),
    (output["catalog"], "output.catalog"),
    (output["schema"], "output.schema"),
    (output["volume"], "output.volume"),
    (output["table_catalog"], "output.table_catalog"),
    (output["table_schema"], "output.table_schema"),
    (control_plane["catalog"], "control_plane.catalog"),
    (control_plane["schema"], "control_plane.schema"),
    (control_plane["runs_table"], "control_plane.runs_table"),
    (control_plane["table_runs_table"], "control_plane.table_runs_table"),
    (control_plane["columns_table"], "control_plane.columns_table"),
]:
    identifier(value, label)

if output.get("format") != "parquet":
    raise ValueError("La salida de este pipeline debe ser format=parquet")
if int(execution.get("max_parallel_tables", 1)) != 1:
    raise ValueError("La primera caracterización debe ejecutarse secuencialmente (max_parallel_tables=1)")


@dataclass(frozen=True)
class TableConfig:
    config_path: str
    source_name: str
    source_schema: str
    source_table: str
    target_table: str
    expected_columns: tuple[str, ...]
    enabled: bool


def top_scalar(lines: list[str], key: str) -> str | None:
    pattern = re.compile(rf"^{re.escape(key)}:\s*([^#]+?)\s*$")
    for line in lines:
        if match := pattern.match(line):
            return match.group(1).strip().strip('"\'')
    return None


def indented_scalar(lines: list[str], key: str) -> str | None:
    pattern = re.compile(rf"^  {re.escape(key)}:\s*(.+?)\s*$")
    for line in lines:
        if match := pattern.match(line):
            return match.group(1).strip().strip('"\'')
    return None


def expected_columns(lines: list[str]) -> tuple[str, ...]:
    in_columns = False
    in_include = False
    values: list[str] = []
    for line in lines:
        if line == "columns:":
            in_columns = True
            in_include = False
            continue
        if in_columns and line.startswith("  include:"):
            in_include = True
            continue
        if in_include:
            if match := re.match(r"^    -\s+(.+?)\s*$", line):
                value = match.group(1).strip().strip('"\'')
                identifier(value, "column")
                values.append(value)
                continue
            if line and not line.startswith("    "):
                break
    return tuple(dict.fromkeys(values))


def parse_table_config(path: Path) -> TableConfig:
    # Lector tolerante: algunos YAML existentes tienen tabs o listas incompletas.
    lines = path.read_text(encoding="utf-8-sig").expandtabs(2).splitlines()
    yaml_source = top_scalar(lines, "source_name")
    source_schema = top_scalar(lines, "source_schema") or "dbo"
    source_table = top_scalar(lines, "source_table")
    target_table = indented_scalar(lines, "bronze_table")
    enabled = (top_scalar(lines, "enabled") or "true").lower() == "true"
    columns = expected_columns(lines)
    if not yaml_source or not source_table or not target_table:
        raise ValueError("faltan source_name, source_table o target.bronze_table")
    for value, label in [
        (yaml_source, "source_name"),
        (source_schema, "source_schema"),
        (source_table, "source_table"),
        (target_table, "bronze_table"),
    ]:
        identifier(value, label)
    return TableConfig(
        str(path), yaml_source, source_schema, source_table, target_table, columns, enabled
    )


glob_value = discovery["ingestion_config_glob"]
config_paths = sorted(REPO_ROOT.glob(glob_value))
if not config_paths:
    raise FileNotFoundError(f"El patrón no encontró YAML: {glob_value}")

table_regex = re.compile(TABLE_FILTER) if TABLE_FILTER else None
parse_errors: list[dict[str, object]] = []
tables: list[TableConfig] = []
for path in config_paths:
    try:
        table = parse_table_config(path)
        if table.source_name != REQUESTED_SOURCE:
            continue
        if not table.enabled and not discovery.get("include_disabled", False):
            continue
        if table_regex and not table_regex.search(table.source_table):
            continue
        tables.append(table)
    except Exception as exc:
        parse_errors.append(
            {
                "run_id": RUN_ID,
                "source_name": REQUESTED_SOURCE,
                "config_path": str(path),
                "source_table": None,
                "target_table": None,
                "status": "CONFIG_ERROR",
                "row_count": None,
                "column_count": None,
                "started_at_utc": None,
                "finished_at_utc": datetime.now(timezone.utc).isoformat(),
                "detail": str(exc),
            }
        )

if not tables:
    raise RuntimeError("No hay tablas habilitadas para los parámetros solicitados")

base_path = (
    f"/Volumes/{output['catalog']}/{output['schema']}/{output['volume']}/"
    f"{output['base_path']}"
)
spark.sql(
    f"CREATE SCHEMA IF NOT EXISTS `{output['table_catalog']}`.`{output['table_schema']}`"
)

CP_RUNS = (
    f"{control_plane['catalog']}.{control_plane['schema']}.{control_plane['runs_table']}"
)
CP_TABLE_RUNS = (
    f"{control_plane['catalog']}.{control_plane['schema']}."
    f"{control_plane['table_runs_table']}"
)
CP_COLUMNS = (
    f"{control_plane['catalog']}.{control_plane['schema']}.{control_plane['columns_table']}"
)
if control_plane.get("enabled", True):
    missing_control_tables = [
        name for name in (CP_RUNS, CP_TABLE_RUNS, CP_COLUMNS)
        if not spark.catalog.tableExists(name)
    ]
    if missing_control_tables:
        raise RuntimeError(
            "Falta crear el control plane con pre_productiva/sql/01_create_control_plane.sql: "
            + ", ".join(missing_control_tables)
        )

compression = output.get("compression", "snappy")
write_mode = output.get("write_mode", "overwrite")
if write_mode not in {"overwrite", "append", "error", "ignore"}:
    raise ValueError(f"output.write_mode no admitido: {write_mode}")

RUN_SCHEMA = StructType(
    [
        StructField("run_id", StringType(), False),
        StructField("source_name", StringType(), False),
        StructField("status", StringType(), False),
        StructField("started_at", TimestampType(), False),
        StructField("finished_at", TimestampType(), True),
        StructField("table_total", IntegerType(), True),
        StructField("table_succeeded", IntegerType(), True),
        StructField("table_failed", IntegerType(), True),
        StructField("total_rows", LongType(), True),
        StructField("dry_run", BooleanType(), False),
        StructField("table_filter", StringType(), True),
        StructField("source_config", StringType(), True),
        StructField("output_base_path", StringType(), True),
        StructField("error_message", StringType(), True),
        StructField("created_by", StringType(), True),
        StructField("updated_at", TimestampType(), False),
    ]
)

SUMMARY_SCHEMA = StructType(
    [
        StructField("run_id", StringType(), False),
        StructField("source_name", StringType(), False),
        StructField("config_path", StringType(), True),
        StructField("source_table", StringType(), True),
        StructField("target_table", StringType(), True),
        StructField("status", StringType(), False),
        StructField("row_count", LongType(), True),
        StructField("column_count", IntegerType(), True),
        StructField("started_at_utc", StringType(), True),
        StructField("finished_at_utc", StringType(), False),
        StructField("detail", StringType(), True),
    ]
)

run_started_at = datetime.now(timezone.utc)
if control_plane.get("enabled", True):
    created_by = spark.sql("SELECT current_user() AS user").first()["user"]
    initial_run = [
        (
            RUN_ID, REQUESTED_SOURCE, "RUNNING", run_started_at, None,
            len(tables), 0, 0, 0, DRY_RUN, TABLE_FILTER or None,
            str(SOURCE_CONFIG), base_path, None, created_by, run_started_at,
        )
    ]
    spark.createDataFrame(initial_run, RUN_SCHEMA).write.format("delta").mode("append").saveAsTable(CP_RUNS)

results = list(parse_errors)
schema_rows: list[Row] = []

for table in tables:
    started_at = datetime.now(timezone.utc)
    frame = None
    try:
        source_fqn = (
            f"{input_cfg['catalog']}.{input_cfg['schema']}.{table.source_table}"
        )
        if not spark.catalog.tableExists(source_fqn):
            raise RuntimeError(
                f"No existe la tabla fuente {source_fqn}; ejecute primero "
                "pre_productiva/notebooks/01_create_source_database.py"
            )
        frame = spark.table(source_fqn)
        actual_by_lower = {name.lower(): name for name in frame.columns}
        expected_lower = {name.lower() for name in table.expected_columns}
        actual_lower = set(actual_by_lower)
        missing = sorted(expected_lower - actual_lower)
        unexpected = sorted(actual_lower - expected_lower)

        for ordinal, field in enumerate(frame.schema.fields, start=1):
            schema_rows.append(
                Row(
                    run_id=RUN_ID,
                    source_name=REQUESTED_SOURCE,
                    source_schema=input_cfg["schema"],
                    source_table=table.source_table,
                    target_table=table.target_table,
                    ordinal=ordinal,
                    column_name=field.name,
                    spark_data_type=field.dataType.simpleString(),
                    nullable=field.nullable,
                    present_in_yaml=field.name.lower() in expected_lower,
                )
            )

        row_count = None
        if not DRY_RUN:
            frame.persist(StorageLevel.DISK_ONLY)
            row_count = frame.count()
            writer = (
                frame.write.format("parquet")
                .mode(write_mode)
                .option("compression", compression)
                .option("overwriteSchema", "true")
            )
            data_path = f"{base_path}/{table.source_table}"
            if output.get("register_tables", True):
                table_fqn = (
                    f"{output['table_catalog']}.{output['table_schema']}.{table.target_table}"
                )
                writer.option("path", data_path).saveAsTable(table_fqn)
            else:
                writer.save(data_path)

        detail = json.dumps(
            {"missing_from_source": missing, "not_declared_in_yaml": unexpected},
            ensure_ascii=False,
        )
        results.append(
            {
                "run_id": RUN_ID,
                "source_name": REQUESTED_SOURCE,
                "config_path": table.config_path,
                "source_table": table.source_table,
                "target_table": table.target_table,
                "status": "CHARACTERIZED" if DRY_RUN else "LOADED",
                "row_count": row_count,
                "column_count": len(frame.columns),
                "started_at_utc": started_at.isoformat(),
                "finished_at_utc": datetime.now(timezone.utc).isoformat(),
                "detail": detail,
            }
        )
    except Exception as exc:
        results.append(
            {
                "run_id": RUN_ID,
                "source_name": REQUESTED_SOURCE,
                "config_path": table.config_path,
                "source_table": table.source_table,
                "target_table": table.target_table,
                "status": "ERROR",
                "row_count": None,
                "column_count": None,
                "started_at_utc": started_at.isoformat(),
                "finished_at_utc": datetime.now(timezone.utc).isoformat(),
                "detail": str(exc),
            }
        )
        if not execution.get("continue_on_error", True):
            break
    finally:
        if frame is not None:
            frame.unpersist(blocking=False)

summary_df = spark.createDataFrame(results, SUMMARY_SCHEMA)
summary_path = f"{base_path}/_metadata/runs/run_id={RUN_ID}"
summary_df.write.mode("overwrite").parquet(summary_path)

if schema_rows:
    schema_df = spark.createDataFrame(schema_rows)
    schema_path = f"{base_path}/_metadata/schemas/run_id={RUN_ID}"
    schema_df.write.mode("overwrite").parquet(schema_path)
    display(schema_df.orderBy("source_table", "ordinal"))

if control_plane.get("enabled", True):
    control_detail_df = (
        summary_df
        .withColumn("started_at", F.to_timestamp("started_at_utc"))
        .withColumn("finished_at", F.to_timestamp("finished_at_utc"))
        .withColumn(
            "output_path",
            F.when(
                F.col("source_table").isNotNull(),
                F.concat(F.lit(base_path + "/"), F.col("source_table")),
            ),
        )
        .select(
            "run_id", "source_name", "config_path", "source_table", "target_table",
            "status", F.col("row_count").cast("long"), F.col("column_count").cast("int"),
            "started_at", "finished_at", "detail", "output_path",
        )
    )
    control_detail_df.write.format("delta").mode("append").saveAsTable(CP_TABLE_RUNS)

    if schema_rows:
        (
            schema_df.withColumn("characterized_at", F.current_timestamp())
            .write.format("delta").mode("append").saveAsTable(CP_COLUMNS)
        )

display(summary_df.orderBy("status", "source_table"))

failed = [row for row in results if row["status"] in {"ERROR", "CONFIG_ERROR"}]
if control_plane.get("enabled", True):
    succeeded = [row for row in results if row["status"] in {"LOADED", "CHARACTERIZED"}]
    final_status = "SUCCEEDED" if not failed else ("PARTIAL" if succeeded else "FAILED")
    total_rows = sum(int(row.get("row_count") or 0) for row in succeeded)
    finished_at = datetime.now(timezone.utc)
    final_run = [
        (
            RUN_ID, REQUESTED_SOURCE, final_status, run_started_at, finished_at,
            len(results), len(succeeded), len(failed), total_rows, DRY_RUN,
            TABLE_FILTER or None, str(SOURCE_CONFIG), base_path,
            f"{len(failed)} tabla(s) con error" if failed else None,
            created_by, finished_at,
        )
    ]
    final_run_df = spark.createDataFrame(final_run, RUN_SCHEMA)
    (
        DeltaTable.forName(spark, CP_RUNS).alias("target")
        .merge(final_run_df.alias("source"), "target.run_id = source.run_id")
        .whenMatchedUpdateAll()
        .whenNotMatchedInsertAll()
        .execute()
    )

if failed and execution.get("fail_job_on_any_error", True):
    raise RuntimeError(
        f"La fuente {REQUESTED_SOURCE} terminó con {len(failed)} errores. "
        f"Resumen: {summary_path}"
    )
