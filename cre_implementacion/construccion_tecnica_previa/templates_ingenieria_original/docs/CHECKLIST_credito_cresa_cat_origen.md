# Checklist: `credito_cresa_cat_origen`

Verificación de artefactos y configuraciones para `cat_origen`.

- [x] YAML creado: analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_origen.yml
- [x] Job JSON creado: templates_ingenieria/config/jobs/credito_cresa_cat_origen_job.json
- [x] Documento de ejecución creado: templates_ingenieria/docs/INGEST_credito_cresa_cat_origen_run.md
- [x] Script `create_job_curl_credito_cresa_cat_origen.sh` creado: templates_ingenieria/scripts/create_job_curl_credito_cresa_cat_origen.sh
- [x] `exec_sql_statements_curl.sh` actualizado con la sentencia SQL correspondiente
- [x] Wrapper `create_databricks_jobs.ps1` puede ejecutar el script con reset/submit

Validación rápida (manual):
1. Confirmar variables de entorno (`DATABRICKS_HOST`, `DATABRICKS_TOKEN`, `DATABRICKS_SQL_WAREHOUSE_ID`).
2. Ejecutar el script curl para crear el job:

```
export DATABRICKS_HOST='https://adb-xxxx.azuredatabricks.net'
export DATABRICKS_TOKEN='dapiXXXXXXXXXXXXXXXX'
bash templates_ingenieria/scripts/create_job_curl_credito_cresa_cat_origen.sh
```

3. Revisar logs en `templates_ingenieria/logs/` y la respuesta del `create` (debe incluir `job_id`).

4. (Opcional) Ejecutar wrapper con `-SubmitRun` para test run y validar alertas/SQLs.
