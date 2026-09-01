# Instrucciones de ejecución: `credito_cresa_cat_parroquia`

Pasos para ejecutar y validar la ingesta de `cat_parroquia` en `dlh_cresa.bronze`.

1) Objetivo
- Ejecutar la ingesta parametrizada definida en `analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_parroquia.yml`.

2) SQL fuente (usada en el YAML)

```
SELECT id,canton_id,cod,pais_cod,provincia_cod,canton_cod,nombre,cinec,es_activo FROM CREDITO_CRESA.dbo.cat_parroquia WITH (NOLOCK)
```

3) Ejecutar el notebook metadata-driven (Databricks)
- Abrir `templates_ingenieria/notebooks/template_pipeline_metadata_driven.ipynb` en Databricks.
- Cargar/parametrizar con la ruta al YAML: `analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_parroquia.yml`.
- Ejecutar celda de test/run único en modo `test`.

4) Validaciones post-run (SQL de ejemplo; ya automatizadas por el script de creación de jobs)
- Ver conteo total:

```
SELECT COUNT(*) FROM dlh_cresa.bronze.credito_cresa_cat_parroquia;
```

- Revisar duplicados por `nombre`:

```
SELECT nombre, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_parroquia
GROUP BY nombre
HAVING COUNT(*) > 1;
```

- Filas con `id` NULL:

```
SELECT COUNT(*) AS null_pk FROM dlh_cresa.bronze.credito_cresa_cat_parroquia WHERE id IS NULL;
```

- Muestra de filas:

```
SELECT TOP 50 id,canton_id,cod,pais_cod,provincia_cod,canton_cod,nombre,cinec,es_activo
FROM dlh_cresa.bronze.credito_cresa_cat_parroquia
ORDER BY id;
```

5) Notas importantes
- `WITH (NOLOCK)` puede devolver lecturas inconsistentes; usar solo si aceptas lecturas sucias.
- El YAML está configurado por defecto para `incremental_datetime` usando `fecha_modificacion` como watermark; si la columna no existe, actualiza `watermark_column`.
- Actualizar `governance.data_owner` con el owner definitivo.

6) Si la ejecución es correcta
- El job puede programarse con `templates_ingenieria/config/jobs/credito_cresa_cat_parroquia_job.json`.
- El script `templates_ingenieria/scripts/create_databricks_jobs.ps1` crea/actualiza el job y ejecuta validaciones automáticas; revisa `templates_ingenieria/logs/` para resultados.
