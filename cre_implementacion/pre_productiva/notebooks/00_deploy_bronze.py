# Databricks notebook source
# MAGIC %md
# MAGIC # Despliegue pre-productivo — Nivel Bronze
# MAGIC
# MAGIC Este notebook crea la estructura Medallion, los volúmenes, el control plane
# MAGIC y, opcionalmente, las tablas fuente de prueba. El alcance funcional termina
# MAGIC en Bronze: Silver y Gold se crean vacíos y no reciben datos.
# MAGIC
# MAGIC **No ejecuta ni habilita jobs automáticamente.**

# COMMAND ----------

from __future__ import annotations

import re
from pathlib import Path

from pyspark.sql import Row


dbutils.widgets.text("catalog", "cresa_dev", "01 Catálogo")
dbutils.widgets.text(
    "git_folder_path",
    "/Workspace/REEMPLAZAR_RUTA_GIT_FOLDER",
    "02 Ruta absoluta Git folder",
)
dbutils.widgets.dropdown(
    "create_source_tables", "true", ["true", "false"], "03 Crear tablas fuente"
)
dbutils.widgets.dropdown(
    "seed_format", "parquet", ["parquet", "csv"], "04 Formato de semillas"
)
dbutils.widgets.text("table_filter", "", "05 Filtro regex de tablas")
dbutils.widgets.dropdown(
    "replace_existing_source",
    "false",
    ["true", "false"],
    "06 Reemplazar tablas fuente",
)

CATALOG = dbutils.widgets.get("catalog").strip()
GIT_FOLDER_PATH = dbutils.widgets.get("git_folder_path").strip().rstrip("/")
CREATE_SOURCE_TABLES = dbutils.widgets.get("create_source_tables").lower() == "true"
SEED_FORMAT = dbutils.widgets.get("seed_format")
TABLE_FILTER = dbutils.widgets.get("table_filter").strip()
REPLACE_EXISTING_SOURCE = (
    dbutils.widgets.get("replace_existing_source").lower() == "true"
)

if CATALOG != "cresa_dev":
    raise ValueError(
        "Este paquete está parametrizado y aprobado únicamente para catalog=cresa_dev"
    )
if not GIT_FOLDER_PATH.startswith("/Workspace/"):
    raise ValueError("git_folder_path debe ser una ruta absoluta bajo /Workspace/")
if "REEMPLAZAR_RUTA_GIT_FOLDER" in GIT_FOLDER_PATH:
    raise ValueError("Reemplace el placeholder de git_folder_path antes de ejecutar")
if TABLE_FILTER:
    re.compile(TABLE_FILTER)
if REPLACE_EXISTING_SOURCE and not TABLE_FILTER:
    raise ValueError(
        "replace_existing_source=true exige un table_filter explícito para evitar "
        "reemplazar las 34 tablas"
    )

print("Parámetros validados. Alcance: DEV/pre-productivo, nivel Bronze.")

# COMMAND ----------
# MAGIC %md
# MAGIC ## 1. Crear arquitectura Medallion y volúmenes

# COMMAND ----------

environment_statements = [
    """CREATE CATALOG IF NOT EXISTS cresa_dev
       COMMENT 'Catálogo para pruebas pre-productivas CRESA'""",
    """CREATE SCHEMA IF NOT EXISTS cresa_dev.landing
       COMMENT 'Recepción de semillas para pruebas'""",
    """CREATE SCHEMA IF NOT EXISTS cresa_dev.credito_cresa_source
       COMMENT 'Base fuente recreada dentro de Databricks'""",
    """CREATE SCHEMA IF NOT EXISTS cresa_dev.bronze
       COMMENT 'Nivel Bronze de pruebas CRESA'""",
    """CREATE SCHEMA IF NOT EXISTS cresa_dev.silver
       COMMENT 'Reservado; fuera del alcance de estas pruebas'""",
    """CREATE SCHEMA IF NOT EXISTS cresa_dev.gold
       COMMENT 'Reservado; fuera del alcance de estas pruebas'""",
    """CREATE SCHEMA IF NOT EXISTS cresa_dev.audit01
       COMMENT 'Control plane de las pruebas de ingesta'""",
    """CREATE VOLUME IF NOT EXISTS cresa_dev.landing.source_seed
       COMMENT 'Semillas opcionales para recrear las tablas fuente'""",
    """CREATE VOLUME IF NOT EXISTS cresa_dev.bronze.data
       COMMENT 'Archivos Parquet del nivel Bronze'""",
]

environment_results = []
for statement in environment_statements:
    object_name = " ".join(statement.split()[:6])
    try:
        spark.sql(statement)
        environment_results.append(Row(object=object_name, status="OK", detail=None))
    except Exception as exc:
        environment_results.append(
            Row(object=object_name, status="ERROR", detail=str(exc))
        )
        raise

display(spark.createDataFrame(environment_results))

# COMMAND ----------
# MAGIC %md
# MAGIC ## 2. Crear control plane Delta

# COMMAND ----------

control_statements = [
    """CREATE TABLE IF NOT EXISTS cresa_dev.audit01.ingestion_runs (
      run_id STRING NOT NULL,
      source_name STRING NOT NULL,
      status STRING NOT NULL,
      started_at TIMESTAMP NOT NULL,
      finished_at TIMESTAMP,
      table_total INT,
      table_succeeded INT,
      table_failed INT,
      total_rows BIGINT,
      dry_run BOOLEAN NOT NULL,
      table_filter STRING,
      source_config STRING,
      output_base_path STRING,
      error_message STRING,
      created_by STRING,
      updated_at TIMESTAMP NOT NULL,
      CONSTRAINT ingestion_runs_pk PRIMARY KEY (run_id) NOT ENFORCED,
      CONSTRAINT ingestion_runs_status_ck
        CHECK (status IN ('RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED'))
    ) USING DELTA
    COMMENT 'Una fila por ejecución del pipeline de una fuente'
    TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true')""",
    """CREATE TABLE IF NOT EXISTS cresa_dev.audit01.ingestion_table_runs (
      run_id STRING NOT NULL,
      source_name STRING NOT NULL,
      config_path STRING,
      source_table STRING,
      target_table STRING,
      status STRING NOT NULL,
      row_count BIGINT,
      column_count INT,
      started_at TIMESTAMP,
      finished_at TIMESTAMP NOT NULL,
      detail STRING,
      output_path STRING,
      CONSTRAINT ingestion_table_runs_status_ck
        CHECK (status IN ('LOADED', 'CHARACTERIZED', 'ERROR', 'CONFIG_ERROR'))
    ) USING DELTA
    PARTITIONED BY (source_name)
    COMMENT 'Resultado por tabla dentro de una ejecución'
    TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true')""",
    """CREATE TABLE IF NOT EXISTS cresa_dev.audit01.ingestion_columns (
      run_id STRING NOT NULL,
      source_name STRING NOT NULL,
      source_schema STRING NOT NULL,
      source_table STRING NOT NULL,
      target_table STRING NOT NULL,
      ordinal INT NOT NULL,
      column_name STRING NOT NULL,
      spark_data_type STRING NOT NULL,
      nullable BOOLEAN NOT NULL,
      present_in_yaml BOOLEAN NOT NULL,
      characterized_at TIMESTAMP NOT NULL
    ) USING DELTA
    PARTITIONED BY (source_name)
    COMMENT 'Diccionario técnico observado en las tablas fuente'
    TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true')""",
    """CREATE TABLE IF NOT EXISTS cresa_dev.audit01.ingestion_watermarks (
      source_name STRING NOT NULL,
      source_table STRING NOT NULL,
      watermark_column STRING,
      watermark_value STRING,
      last_successful_run_id STRING,
      last_successful_at TIMESTAMP,
      updated_at TIMESTAMP NOT NULL,
      CONSTRAINT ingestion_watermarks_pk
        PRIMARY KEY (source_name, source_table) NOT ENFORCED
    ) USING DELTA
    COMMENT 'Reservado para cargas incrementales futuras'""",
    """CREATE OR REPLACE VIEW cresa_dev.audit01.v_latest_ingestion_run AS
    SELECT * EXCEPT (run_order)
    FROM (
      SELECT *, ROW_NUMBER() OVER (
        PARTITION BY source_name ORDER BY started_at DESC
      ) AS run_order
      FROM cresa_dev.audit01.ingestion_runs
    )
    WHERE run_order = 1""",
    """CREATE OR REPLACE VIEW cresa_dev.audit01.v_ingestion_errors AS
    SELECT run_id, source_name, source_table, target_table,
           status, started_at, finished_at, detail
    FROM cresa_dev.audit01.ingestion_table_runs
    WHERE status IN ('ERROR', 'CONFIG_ERROR')""",
]

for statement in control_statements:
    spark.sql(statement)

print(f"Control plane creado/validado: {len(control_statements)} objetos.")

# COMMAND ----------
# MAGIC %md
# MAGIC ## 3. Recrear tablas fuente desde los YAML
# MAGIC
# MAGIC Con `replace_existing_source=false`, las tablas existentes se conservan.

# COMMAND ----------

source_creation_result = "SKIPPED"
if CREATE_SOURCE_TABLES:
    source_notebook = (
        f"{GIT_FOLDER_PATH}/pre_productiva/notebooks/01_create_source_database"
    )
    source_creation_result = dbutils.notebook.run(
        source_notebook,
        3600,
        {
            "source_config": (
                f"{GIT_FOLDER_PATH}/pre_productiva/config/sources/credito_cresa.yml"
            ),
            "seed_format": SEED_FORMAT,
            "replace_existing": str(REPLACE_EXISTING_SOURCE).lower(),
            "table_filter": TABLE_FILTER,
        },
    )

print(f"Resultado de recreación de fuente: {source_creation_result}")

# COMMAND ----------
# MAGIC %md
# MAGIC ## 4. Validaciones posteriores

# COMMAND ----------

source_tables = spark.sql("SHOW TABLES IN cresa_dev.credito_cresa_source")
bronze_tables = spark.sql("SHOW TABLES IN cresa_dev.bronze")
audit_tables = spark.sql("SHOW TABLES IN cresa_dev.audit01")

print(f"Tablas fuente recreadas: {source_tables.count()}")
print(f"Tablas Bronze actuales: {bronze_tables.count()}")
print(f"Objetos del control plane: {audit_tables.count()}")

display(source_tables.orderBy("tableName"))

silver_count = spark.sql("SHOW TABLES IN cresa_dev.silver").count()
gold_count = spark.sql("SHOW TABLES IN cresa_dev.gold").count()
if silver_count != 0 or gold_count != 0:
    raise RuntimeError(
        "Silver y Gold deben permanecer vacíos en el alcance de pruebas Bronze"
    )

print(
    "Despliegue base Bronze completado. Próximo paso: crear el job pausado y "
    "ejecutar dry_run=true con table_filter=^sis_peticiones$."
)
