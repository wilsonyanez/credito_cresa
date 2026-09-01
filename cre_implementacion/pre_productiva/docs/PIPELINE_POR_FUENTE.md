# Pipeline por fuente recreada en Databricks

## Diseño

El proceso ya no consulta una base externa. Los YAML definen el inventario; un primer notebook recrea las tablas fuente en Parquet y el pipeline consolidado las recorre desde Databricks.

```text
pre_productiva/config/ingestion/**/*.yml
                  |
                  v
01_create_source_database.py
                  |
                  v
cresa_dev.credito_cresa_source.<source_table>
                  |
                  v
ingest_databricks_source_to_parquet.py
```

## Recreación de la fuente

`01_create_source_database.py` usa `source_table` y `columns.include` de cada YAML:

- Si encuentra una semilla en `/Volumes/cresa_dev/landing/source_seed/<tabla>/`, crea la tabla Parquet conservando o infiriendo su esquema.
- Si no hay semilla, crea una tabla Parquet vacía con columnas `STRING`.
- `replace_existing=false` evita reemplazos accidentales.
- `replace_existing=true` elimina y recrea únicamente la tabla fuente filtrada; requiere aprobación previa.

## Ingesta

El pipeline lee cada tabla mediante `spark.table`, caracteriza su esquema, compara las columnas reales con el YAML y escribe:

```text
/Volumes/cresa_dev/landing/parquet/credito_cresa/<source_table>/*.parquet
/Volumes/cresa_dev/landing/parquet/credito_cresa/_metadata/runs/...
/Volumes/cresa_dev/landing/parquet/credito_cresa/_metadata/schemas/...
```

También registra las tablas en `cresa_dev.bronze` y las ejecuciones en el control plane Delta `cresa_dev.audit01`.

## Prueba inicial

1. Crear ambiente y control plane.
2. Ejecutar la recreación con `table_filter=^sis_peticiones$`.
3. Revisar la tabla `cresa_dev.credito_cresa_source.sis_peticiones`.
4. Ejecutar el job con `dry_run=true` y el mismo filtro.
5. Ejecutar con `dry_run=false` después de aprobar el esquema.

Los jobs individuales históricos están en `construccion_tecnica_previa/` y no deben desplegarse.

