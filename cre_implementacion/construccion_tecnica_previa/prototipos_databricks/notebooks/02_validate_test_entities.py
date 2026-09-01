# Databricks notebook source
# MAGIC %md
# MAGIC # Validación de entidades Bronze de prueba

# COMMAND ----------

from pyspark.sql import Row

dbutils.widgets.text("catalog", "cresa_dev", "Catálogo")
dbutils.widgets.text("schema", "bronze", "Esquema")

catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")

tables = spark.sql(f"SHOW TABLES IN `{catalog}`.`{schema}`").collect()
if not tables:
    raise RuntimeError(f"No existen tablas en {catalog}.{schema}")

results = []
for table in tables:
    full_name = f"`{catalog}`.`{schema}`.`{table.tableName}`"
    count = spark.sql(f"SELECT COUNT(*) AS total FROM {full_name}").first()["total"]
    results.append(Row(table=table.tableName, rows=count, status="OK"))

display(spark.createDataFrame(results).orderBy("table"))
