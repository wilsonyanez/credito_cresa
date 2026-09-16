# Databricks notebook source
import json
import sys
from pathlib import Path

dbutils.widgets.text("source_config", "../config/sources/credicresa.yml")
ROOT = Path(dbutils.widgets.get("source_config")).resolve().parents[2]
sys.path.insert(0, str(ROOT / "lib"))
from credicresa_runtime import settings
from credicresa_medallion import transform
values = settings(dbutils)
# Primera pasada de lectura obligatoria antes de persistir esta capa.
transform(spark, ROOT, dict(values, dry_run=True), "gold")
result = transform(spark, ROOT, values, "gold")
dbutils.notebook.exit(json.dumps(result))
