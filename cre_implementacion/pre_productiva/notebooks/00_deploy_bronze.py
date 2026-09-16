# Databricks notebook source
# MAGIC %md
# MAGIC # CRESA: estructura Medallion y control plane
# COMMAND ----------
from pathlib import Path
import re
dbutils.widgets.text("source_config", "../config/sources/credicresa.yml")
root = Path(dbutils.widgets.get("source_config")).resolve().parents[2]
for filename in ("00_create_test_environment.sql", "00_create_credicresa_database.sql", "01_create_control_plane.sql"):
    text = re.sub(r"(?m)^\s*--.*$", "", (root / "sql" / filename).read_text(encoding="utf-8-sig"))
    for statement in text.split(";"):
        if statement.strip():
            spark.sql(statement)
print("CRESA: estructura creada. Ejecutar JOB_CRE_00_CARGA_DATOS_CREDI_CRESA para crear y verificar las entidades.")
