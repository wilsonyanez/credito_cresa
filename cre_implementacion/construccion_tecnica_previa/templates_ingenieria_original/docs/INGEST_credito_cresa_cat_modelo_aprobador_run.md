# Instrucciones de ejecución: `credito_cresa_cat_modelo_aprobador`

Pasos para ejecutar y validar la ingesta de `cat_modelo_aprobador` en `dlh_cresa.bronze`.

1) Objetivo
- Ejecutar la ingesta parametrizada definida en `analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_modelo_aprobador.yml`.

2) SQL fuente (usada en el YAML)

```
SELECT id,calificacion_buro_id,calificacion_confianza_id,calificacion_final_id,origen_id,zona_riesgo_id,tipo_cliente_id,dependencia_id,grupo_id,edad_min,edad_max,nacionalidad,capacidad_pago,tipo_verificacion,entrada_base,es_activo,fecha_creacion,actualizado,creado_por,actualizado_por,unidadnegocio_id,canal_id FROM CREDITO_CRESA.dbo.cat_modelo_aprobador WITH (NOLOCK)
```

3) Ejecutar el notebook metadata-driven (Databricks)
- Abrir `templates_ingenieria/notebooks/template_pipeline_metadata_driven.ipynb` en Databricks.
- Cargar/parametrizar con la ruta al YAML: `analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_modelo_aprobador.yml`.
- Ejecutar celda de test/run único en modo `test`.

4) Validaciones post-run (SQL de ejemplo; ya automatizadas por el script de creación de jobs)
- Ver conteo total:

```
SELECT COUNT(*) FROM dlh_cresa.bronze.credito_cresa_cat_modelo_aprobador;
```

- Revisar duplicados por `id` (clave primaria):

```
SELECT id, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_modelo_aprobador
GROUP BY id
HAVING COUNT(*) > 1;
```

- Filas con `id` NULL:

```
SELECT COUNT(*) AS null_pk FROM dlh_cresa.bronze.credito_cresa_cat_modelo_aprobador WHERE id IS NULL;
```

- Muestra de filas relevantes (ejemplo):

```
SELECT TOP 50 id,calificacion_final_id,origen_id,nacionalidad,es_activo,fecha_creacion
FROM dlh_cresa.bronze.credito_cresa_cat_modelo_aprobador
ORDER BY id;
```

5) Notas importantes
- `WITH (NOLOCK)` puede devolver lecturas inconsistentes; usar solo si aceptas lecturas sucias.
- Revisar `governance.sensitivity` y `data_owner` antes de publicar.

6) Si la ejecución es correcta
- El job puede programarse con `templates_ingenieria/config/jobs/credito_cresa_cat_modelo_aprobador_job.json`.
- El script `templates_ingenieria/scripts/create_databricks_jobs.ps1` crea/actualiza el job y ejecuta validaciones automáticas; revisa `templates_ingenieria/logs/` para resultados.
