# CHECKLIST - credito_cresa_cat_tipovinculo

- [x] YAML creado: analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_tipovinculo.yml
- [x] Job JSON creado: templates_ingenieria/config/jobs/credito_cresa_cat_tipovinculo_job.json
- [x] Documento de ejecución: templates_ingenieria/docs/INGEST_credito_cresa_cat_tipovinculo_run.md
- [x] Script curl único creado: templates_ingenieria/scripts/create_job_curl_credito_cresa_cat_tipovinculo.sh
- [x] Script para crear todos los jobs (Bash): templates_ingenieria/scripts/create_all_jobs_curl.sh (actualizado con alertas)
- [x] Script para crear todos los jobs (PowerShell): templates_ingenieria/scripts/create_all_jobs.ps1
- [x] Sentencia SQL añadida al runner: templates_ingenieria/scripts/exec_sql_statements_curl.sh
- [x] README breve creado: templates_ingenieria/scripts/README_create_jobs.md

Validación sugerida:
1. Exportar `DATABRICKS_HOST` y `DATABRICKS_TOKEN`.
2. Ejecutar `bash templates_ingenieria/scripts/create_job_curl_credito_cresa_cat_tipovinculo.sh` y verificar respuesta.
3. Ejecutar `bash templates_ingenieria/scripts/create_all_jobs_curl.sh --submit` (opcional) o en PowerShell:

```powershell
.\templates_ingenieria\scripts\create_all_jobs.ps1 -SubmitRun
```

4. Verificar logs en `templates_ingenieria/logs/` y confirmar que se envía mail cuando una ejecución falla.
