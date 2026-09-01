# Checklist: `credito_cresa_cat_solicitud_estados`

Verificación de artefactos y configuraciones para `cat_solicitud_estados`.

- [x] YAML creado: analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_solicitud_estados.yml
- [x] Job JSON creado: templates_ingenieria/config/jobs/credito_cresa_cat_solicitud_estados_job.json
- [x] Documento de ejecución creado: templates_ingenieria/docs/INGEST_credito_cresa_cat_solicitud_estados_run.md
- [x] Script `create_job_curl_credito_cresa_cat_solicitud_estados.sh` creado: templates_ingenieria/scripts/create_job_curl_credito_cresa_cat_solicitud_estados.sh
- [x] `exec_sql_statements_curl.sh` actualizado con la sentencia SQL correspondiente
- [x] Wrapper `create_databricks_jobs.ps1` ya puede ejecutar el script que hace reset/submit (revisión previa)

Validación rápida (manual):
1. Confirmar que las variables de entorno están definidas (`DATABRICKS_HOST`, `DATABRICKS_TOKEN`, `DATABRICKS_SQL_WAREHOUSE_ID`).
2. Ejecutar el script curl para crear el job:

```
export DATABRICKS_HOST='https://adb-xxxx.azuredatabricks.net'
export DATABRICKS_TOKEN='dapiXXXXXXXXXXXXXXXX'
bash templates_ingenieria/scripts/create_job_curl_credito_cresa_cat_solicitud_estados.sh
```

3. Revisar logs en `templates_ingenieria/logs/` y la respuesta del `create` (debe incluir `job_id`).

4. (Opcional) Ejecutar wrapper con `-SubmitRun` para test run y validar alertas/SQLs.
