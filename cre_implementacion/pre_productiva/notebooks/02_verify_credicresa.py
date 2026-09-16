# Databricks notebook source
# MAGIC %md
# MAGIC # CRESA / credicresa: verify
# COMMAND ----------
import json
import sys
from pathlib import Path

dbutils.widgets.text("source_config", "../config/sources/credicresa.yml")
ROOT = Path(dbutils.widgets.get("source_config")).resolve().parents[2]
sys.path.insert(0, str(ROOT / "lib"))
from credicresa_runtime import settings, verify
values = settings(dbutils)
result = verify(spark, ROOT, values)
print(json.dumps(result, ensure_ascii=False))
dbutils.notebook.exit(json.dumps(result, ensure_ascii=False))
