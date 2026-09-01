# Checklist: `credito_cresa_cat_modelo_calificacion`

Verificación de artefactos y configuraciones para `cat_modelo_calificacion`.

- [x] YAML creado: analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_modelo_calificacion.yml
- [x] Job JSON creado: templates_ingenieria/config/jobs/credito_cresa_cat_modelo_calificacion_job.json
- [x] Documento de ejecución creado: templates_ingenieria/docs/INGEST_credito_cresa_cat_modelo_calificacion_run.md
- [x] Script `create_job_curl_credito_cresa_cat_modelo_calificacion.sh` creado: templates_ingenieria/scripts/create_job_curl_credito_cresa_cat_modelo_calificacion.sh
- [x] `exec_sql_statements_curl.sh` actualizado con la sentencia SQL correspondiente
- [x] `create_all_jobs.ps1` actualizado para enviar alertas SMTP en caso de run fallido

Validación rápida (manual):
1. Confirmar variables de entorno (`DATABRICKS_HOST`, `DATABRICKS_TOKEN`, `DATABRICKS_SQL_WAREHOUSE_ID`, `SMTP_HOST`, etc.).
2. Ejecutar el script curl para crear el job:

```
export DATABRICKS_HOST='https://adb-xxxx.azuredatabricks.net'
export DATABRICKS_TOKEN='dapiXXXXXXXXXXXXXXXX'
bash templates_ingenieria/scripts/create_job_curl_credito_cresa_cat_modelo_calificacion.sh
```

3. Revisar logs en `templates_ingenieria/logs/` y la respuesta del `create` (debe incluir `job_id`).

4. Ejecutar PowerShell wrapper con `-SubmitRun` para test run y validar alertas SMTP.
