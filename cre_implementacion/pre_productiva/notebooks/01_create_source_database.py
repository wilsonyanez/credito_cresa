# Databricks notebook source
# MAGIC %md
# MAGIC # CRESA / credicresa: prepare_source
# COMMAND ----------
import json
import sys
from pathlib import Path

dbutils.widgets.text("source_config", "../config/sources/credicresa.yml")
ROOT = Path(dbutils.widgets.get("source_config")).resolve().parents[2]
sys.path.insert(0, str(ROOT / "lib"))
from credicresa_runtime import settings, prepare_source
values = settings(dbutils)
result = prepare_source(spark, dbutils, ROOT, values)
print(json.dumps(result, ensure_ascii=False))
dbutils.notebook.exit(json.dumps(result, ensure_ascii=False))
