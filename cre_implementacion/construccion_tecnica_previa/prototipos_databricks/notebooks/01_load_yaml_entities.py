# Databricks notebook source
# MAGIC %md
# MAGIC # Crear y cargar entidades de prueba desde los YAML
# MAGIC
# MAGIC Lee los YAML del repositorio, crea tablas Delta vacías para las entidades sin
# MAGIC archivo y carga Parquet/CSV desde un volumen de Unity Catalog cuando existen.
# MAGIC No accede a SQL Server y no contiene credenciales.

# COMMAND ----------

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from pyspark.sql import functions as F


dbutils.widgets.text("catalog", "cresa_dev", "01 Catálogo de pruebas")
dbutils.widgets.text("landing_schema", "landing", "02 Esquema landing")
dbutils.widgets.text("bronze_schema", "bronze", "03 Esquema Bronze")
dbutils.widgets.text("volume", "sqlserver", "04 Volumen")
dbutils.widgets.dropdown("file_format", "parquet", ["parquet", "csv"], "05 Formato")
dbutils.widgets.dropdown("write_mode", "overwrite", ["overwrite", "append"], "06 Escritura")
dbutils.widgets.dropdown("create_empty", "true", ["true", "false"], "07 Crear vacías")
dbutils.widgets.text(
    "config_dir",
    "analisis_caracterizacion/templates_ingenieria/config/ingestion",
    "08 Directorio YAML",
)

CATALOG = dbutils.widgets.get("catalog")
LANDING_SCHEMA = dbutils.widgets.get("landing_schema")
BRONZE_SCHEMA = dbutils.widgets.get("bronze_schema")
VOLUME = dbutils.widgets.get("volume")
FILE_FORMAT = dbutils.widgets.get("file_format")
WRITE_MODE = dbutils.widgets.get("write_mode")
CREATE_EMPTY = dbutils.widgets.get("create_empty").lower() == "true"
CONFIG_DIR = Path(dbutils.widgets.get("config_dir"))

IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def checked_identifier(value: str, label: str) -> str:
    if not IDENTIFIER.fullmatch(value):
        raise ValueError(f"{label} no es un identificador válido: {value!r}")
    return value


for value, label in [
    (CATALOG, "catalog"),
    (LANDING_SCHEMA, "landing_schema"),
    (BRONZE_SCHEMA, "bronze_schema"),
    (VOLUME, "volume"),
]:
    checked_identifier(value, label)


@dataclass(frozen=True)
class Entity:
    config_file: str
    source_table: str
    target_table: str
    columns: tuple[str, ...]
    enabled: bool


def scalar(lines: list[str], key: str) -> str | None:
    pattern = re.compile(rf"^{re.escape(key)}:\s*([^#]+?)\s*$")
    for line in lines:
        match = pattern.match(line)
        if match:
            return match.group(1).strip().strip('"\'')
    return None


def include_columns(lines: list[str]) -> tuple[str, ...]:
    """Extrae columns.include sin depender de que el YAML completo sea válido."""
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
            match = re.match(r"^    -\s+(.+?)\s*$", line)
            if match:
                value = match.group(1).strip().strip('"\'')
                checked_identifier(value, "column")
                values.append(value)
                continue
            if line and not line.startswith("    "):
                break
    return tuple(dict.fromkeys(values))


def read_entity(path: Path) -> Entity:
    lines = path.read_text(encoding="utf-8-sig").expandtabs(2).splitlines()
    source = scalar(lines, "source_table")
    target = next(
        (
            match.group(1)
            for line in lines
            if (match := re.match(r"^  bronze_table:\s*([A-Za-z_][A-Za-z0-9_]*)", line))
        ),
        None,
    )
    enabled_value = scalar(lines, "enabled") or "true"
    columns = include_columns(lines)
    if not source or not target or not columns:
        raise ValueError("faltan source_table, target.bronze_table o columns.include")
    checked_identifier(source, "source_table")
    checked_identifier(target, "bronze_table")
    return Entity(path.name, source, target, columns, enabled_value.lower() == "true")


if not CONFIG_DIR.is_dir():
    raise FileNotFoundError(
        f"No existe {CONFIG_DIR}. Ejecute el notebook desde el Git folder raíz o ajuste config_dir."
    )

spark.sql(f"CREATE CATALOG IF NOT EXISTS `{CATALOG}`")
spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{CATALOG}`.`{LANDING_SCHEMA}`")
spark.sql(f"CREATE SCHEMA IF NOT EXISTS `{CATALOG}`.`{BRONZE_SCHEMA}`")
spark.sql(f"CREATE VOLUME IF NOT EXISTS `{CATALOG}`.`{LANDING_SCHEMA}`.`{VOLUME}`")


def path_exists(path: str) -> bool:
    try:
        dbutils.fs.ls(path)
        return True
    except Exception:  # dbutils no expone una excepción estable entre runtimes
        return False


results: list[dict[str, object]] = []
for config_path in sorted(CONFIG_DIR.glob("*.yml")):
    try:
        entity = read_entity(config_path)
        if not entity.enabled:
            results.append({"config": config_path.name, "status": "SKIPPED_DISABLED"})
            continue

        input_path = (
            f"/Volumes/{CATALOG}/{LANDING_SCHEMA}/{VOLUME}/{entity.source_table}"
        )
        target = f"`{CATALOG}`.`{BRONZE_SCHEMA}`.`{entity.target_table}`"

        if path_exists(input_path):
            reader = spark.read.format(FILE_FORMAT)
            if FILE_FORMAT == "csv":
                reader = reader.option("header", "true").option("inferSchema", "true")
            frame = reader.load(input_path)
            actual = {name.lower(): name for name in frame.columns}
            missing = [name for name in entity.columns if name.lower() not in actual]
            if missing:
                raise ValueError(f"columnas ausentes en archivo: {missing}")
            frame = frame.select(
                *[F.col(actual[name.lower()]).alias(name) for name in entity.columns]
            )
            frame = (
                frame.withColumn("_ingestion_timestamp", F.current_timestamp())
                .withColumn("_source_file", F.input_file_name())
            )
            (
                frame.write.format("delta")
                .mode(WRITE_MODE)
                .option("overwriteSchema", "true" if WRITE_MODE == "overwrite" else "false")
                .saveAsTable(f"{CATALOG}.{BRONZE_SCHEMA}.{entity.target_table}")
            )
            results.append(
                {
                    "config": entity.config_file,
                    "source": entity.source_table,
                    "target": entity.target_table,
                    "status": "LOADED",
                    "rows": frame.count(),
                }
            )
        elif CREATE_EMPTY:
            definitions = ",\n  ".join(f"`{name}` STRING" for name in entity.columns)
            spark.sql(f"CREATE TABLE IF NOT EXISTS {target} (\n  {definitions}\n) USING DELTA")
            results.append(
                {
                    "config": entity.config_file,
                    "source": entity.source_table,
                    "target": entity.target_table,
                    "status": "CREATED_EMPTY_STRING_SCHEMA",
                    "rows": 0,
                }
            )
        else:
            results.append(
                {
                    "config": entity.config_file,
                    "source": entity.source_table,
                    "target": entity.target_table,
                    "status": "SKIPPED_NO_INPUT",
                }
            )
    except Exception as exc:
        results.append(
            {"config": config_path.name, "status": "ERROR", "detail": str(exc)}
        )

result_df = spark.createDataFrame(results)
display(result_df.orderBy("status", "config"))

errors = [item for item in results if item["status"] == "ERROR"]
if errors:
    raise RuntimeError(f"Fallaron {len(errors)} configuraciones; revise la tabla de resultados")

