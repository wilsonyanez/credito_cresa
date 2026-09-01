"""Prueba mínima de Databricks Connect; no modifica datos remotos."""

from databricks.connect import DatabricksSession


def main() -> None:
    spark = DatabricksSession.builder.validateSession(True).getOrCreate()
    row = spark.sql(
        "SELECT current_catalog() AS catalog, "
        "current_schema() AS schema, current_user() AS user"
    ).first()
    print(row.asDict())


if __name__ == "__main__":
    main()

