# Databricks notebook source
# MAGIC %md
# MAGIC # Recrear la base fuente dentro de Databricks
# MAGIC
# MAGIC Crea las tablas de `cresa_dev.credito_cresa_source` desde los YAML. Si existe
# MAGIC un archivo semilla Parquet/CSV, Spark infiere sus tipos; sin semilla crea una
# MAGIC tabla Parquet vacía con columnas `STRING` y deja explícita esa limitación.

# COMMAND ----------

from __future__ import annotations

import re
from pathlib import Path

import yaml
from pyspark.sql import Row


dbutils.widgets.text(
    "source_config",
    "pre_productiva/config/sources/credito_cresa.yml",
    "Configuración de fuente",
)
dbutils.widgets.dropdown("seed_format", "parquet", ["parquet", "csv"], "Formato semilla")
dbutils.widgets.dropdown("replace_existing", "false", ["true", "false"], "Recrear existentes")
dbutils.widgets.text("table_filter", "", "Filtro regex opcional")

SOURCE_CONFIG = Path(dbutils.widgets.get("source_config"))
SEED_FORMAT = dbutils.widgets.get("seed_format")
REPLACE_EXISTING = dbutils.widgets.get("replace_existing").lower() == "true"
TABLE_FILTER = dbutils.widgets.get("table_filter").strip()
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def identifier(value: str, label: str) -> str:
    if not IDENTIFIER.fullmatch(value):
        raise ValueError(f"{label} inválido: {value!r}")
    return value


if not SOURCE_CONFIG.is_file():
    raise FileNotFoundError(f"No existe {SOURCE_CONFIG}")
SOURCE_CONFIG = SOURCE_CONFIG.resolve()
REPO_ROOT = SOURCE_CONFIG.parents[3]
with SOURCE_CONFIG.open(encoding="utf-8-sig") as stream:
    source_cfg = yaml.safe_load(stream)

if source_cfg.get("source_type") != "databricks":
    raise ValueError("La fuente debe tener source_type=databricks")

input_cfg = source_cfg["input"]
discovery = source_cfg["discovery"]
source_catalog = identifier(input_cfg["catalog"], "input.catalog")
source_schema = identifier(input_cfg["schema"], "input.schema")

spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{source_catalog}`.`{source_schema}`")


def top_scalar(lines: list[str], key: str) -> str | None:
    pattern = re.compile(rf"^{re.escape(key)}:\s*([^#]+?)\s*$")
    for line in lines:
        if match := pattern.match(line):
            return match.group(1).strip().strip('"\'')
    return None


def include_columns(lines: list[str]) -> tuple[str, ...]:
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


def path_exists(path: str) -> bool:
    try:
        return bool(dbutils.fs.ls(path))
    except Exception:
        return False


config_paths = sorted(REPO_ROOT.glob(discovery["ingestion_config_glob"]))
table_regex = re.compile(TABLE_FILTER) if TABLE_FILTER else None
results: list[Row] = []

for config_path in config_paths:
    try:
        lines = config_path.read_text(encoding="utf-8-sig").expandtabs(2).splitlines()
        if (top_scalar(lines, "source_name") or "") != source_cfg["source_name"]:
            continue
        if (top_scalar(lines, "enabled") or "true").lower() != "true":
            continue
        table = top_scalar(lines, "source_table")
        columns = include_columns(lines)
        if not table or not columns:
            raise ValueError("faltan source_table o columns.include")
        identifier(table, "source_table")
        if table_regex and not table_regex.search(table):
            continue

        table_fqn = f"{source_catalog}.{source_schema}.{table}"
        if spark.catalog.tableExists(table_fqn) and not REPLACE_EXISTING:
            results.append(Row(table=table, status="SKIPPED_EXISTS", columns=len(columns), detail=None))
            continue

        seed_path = (
            f"/Volumes/{input_cfg['seed_catalog']}/{input_cfg['seed_schema']}/"
            f"{input_cfg['seed_volume']}/{table}"
        )
        if path_exists(seed_path):
            reader = spark.read.format(SEED_FORMAT)
            if SEED_FORMAT == "csv":
                reader = reader.option("header", "true").option("inferSchema", "true")
            frame = reader.load(seed_path)
            actual = {name.lower() for name in frame.columns}
            missing = [name for name in columns if name.lower() not in actual]
            if missing:
                raise ValueError(f"la semilla no contiene columnas YAML: {missing}")
            (
                frame.write.format("parquet")
                .mode("overwrite")
                .option("overwriteSchema", "true")
                .saveAsTable(table_fqn)
            )
            results.append(
                Row(
                    table=table,
                    status="CREATED_FROM_SEED",
                    columns=len(frame.columns),
                    detail=f"Tipos inferidos desde {SEED_FORMAT}",
                )
            )
        else:
            definitions = ",\n  ".join(f"`{name}` STRING" for name in columns)
            if REPLACE_EXISTING:
                spark.sql(f"DROP TABLE IF EXISTS `{source_catalog}`.`{source_schema}`.`{table}`")
            spark.sql(
                f"CREATE TABLE IF NOT EXISTS `{source_catalog}`.`{source_schema}`.`{table}` "
                f"(\n  {definitions}\n) USING PARQUET"
            )
            results.append(
                Row(
                    table=table,
                    status="CREATED_EMPTY_STRING_SCHEMA",
                    columns=len(columns),
                    detail="Sin semilla ni diccionario de tipos",
                )
            )
    except Exception as exc:
        results.append(Row(table=config_path.name, status="ERROR", columns=None, detail=str(exc)))

if not results:
    raise RuntimeError("No se encontraron configuraciones para crear")

result_df = spark.createDataFrame(results)
display(result_df.orderBy("status", "table"))

errors = [row for row in results if row.status == "ERROR"]
if errors:
    raise RuntimeError(f"Fallaron {len(errors)} tablas durante la recreación")
