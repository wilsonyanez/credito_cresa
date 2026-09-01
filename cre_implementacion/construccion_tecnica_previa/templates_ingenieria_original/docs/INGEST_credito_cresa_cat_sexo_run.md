# Instrucciones de ejecución: `credito_cresa_cat_sexo`

Pasos para ejecutar y validar la ingesta de `cat_sexo` en `dlh_cresa.bronze`.

1) Objetivo
- Ejecutar la ingesta parametrizada definida en `analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_sexo.yml`.

2) SQL fuente (usada en el YAML)

```
SELECT id,nombre FROM CREDITO_CRESA.dbo.cat_sexo WITH (NOLOCK)
```

3) Ejecutar el notebook metadata-driven (Databricks)
- Abrir `templates_ingenieria/notebooks/template_pipeline_metadata_driven.ipynb` en Databricks.
- Cargar/parametrizar con la ruta al YAML: `analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_sexo.yml`.
- Ejecutar celda de test/run único en modo `test`.

4) Validaciones post-run (SQL de ejemplo)
- Ver conteo total:

```
SELECT COUNT(*) FROM dlh_cresa.bronze.credito_cresa_cat_sexo;
```

- Revisar duplicados por `id`:

```
SELECT id, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_sexo
GROUP BY id
HAVING COUNT(*) > 1;
```

- Ver unicidad del `natural_key (nombre)`:

```
SELECT nombre, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_sexo
GROUP BY nombre
HAVING COUNT(*) > 1;
```

- Muestra de filas:

```
SELECT TOP 50 id,nombre
FROM dlh_cresa.bronze.credito_cresa_cat_sexo
ORDER BY id;
```

5) Notas importantes
- `WITH (NOLOCK)` puede devolver lecturas inconsistentes; usar solo si aceptas lecturas sucias.
- Si se planifica ingesta incremental, añadir `watermark_column` real en el YAML y ajustar `incremental_mode`.
- Actualizar `governance.data_owner` con el owner definitivo.

6) Si la ejecución es correcta
- Crear job programado (ver `templates_ingenieria/config/jobs/credito_cresa_cat_sexo_job.json`) y añadir alertas que monitoricen `control_plane.error_table`.
