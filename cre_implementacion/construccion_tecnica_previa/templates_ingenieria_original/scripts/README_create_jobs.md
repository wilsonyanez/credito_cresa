# README - Scripts de creación de Jobs Databricks

Resumen: Scripts para crear/reset y (opcional) ejecutar Jobs en Databricks. Incluye versión Bash (curl) y PowerShell con envío de alertas SMTP.

Requisitos:
- `DATABRICKS_HOST` (ej: https://adb-1234567890.11.azuredatabricks.net)
- `DATABRICKS_TOKEN` (usar `dapi...`)
- Para ejecución de SQL: `DATABRICKS_SQL_WAREHOUSE_ID`.
- Opcional (alertas): `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_ENABLE_SSL`, `ALERT_RECIPIENTS`, `ALERT_FROM`.

Bash - crear job único:

```bash
export DATABRICKS_HOST='https://adb-...'
export DATABRICKS_TOKEN='dapi...'
bash templates_ingenieria/scripts/create_job_curl_credito_cresa_cat_tipovinculo.sh
```

Bash - crear/reset todos los jobs y (opcional) submit de runs:

```bash
export DATABRICKS_HOST='https://adb-...'
export DATABRICKS_TOKEN='dapi...'
export ALERT_RECIPIENTS='data-team@empresa.local'
bash templates_ingenieria/scripts/create_all_jobs_curl.sh --submit
```

PowerShell - crear/reset todos los jobs y submit (recomendado si necesita SMTP):

```powershell
# Ejemplo de variables de entorno en PowerShell
$env:DATABRICKS_HOST='https://adb-...'
$env:DATABRICKS_TOKEN='dapi...'
$env:SMTP_HOST='smtp.empresa.local'
$env:SMTP_PORT='587'
$env:SMTP_USER='alerts@empresa.local'
$env:SMTP_PASSWORD='<secret>'
$env:ALERT_RECIPIENTS='data-team@empresa.local'
.\templates_ingenieria\scripts\create_all_jobs.ps1 -SubmitRun
```

Logs: todos los logs se escriben en `templates_ingenieria/logs/`.

Seguridad: No pongas tokens en el repositorio. Usa variables de entorno o herramientas secret manager.
# Scripts para creación/actualización de jobs Databricks

Resumen:
- `create_all_jobs_curl.sh` (Bash): crea o hace `reset` de todos los archivos `*_job.json` en `templates_ingenieria/config/jobs`. Opción `--submit` para enviar runs y hacer polling.
- `create_all_jobs.ps1` (PowerShell): equivalente en PowerShell. Acepta `-SubmitRun` para enviar runs.
- `exec_sql_statements_curl.sh` (Bash): ejecuta una serie de sentencias SQL usando la Databricks SQL API y guarda resultados en `templates_ingenieria/logs/`.
- `create_job_curl_*.sh`: scripts individuales para crear un job específico.

Variables de entorno requeridas:
- `DATABRICKS_HOST` (ej. https://adb-xxxx.azuredatabricks.net)
- `DATABRICKS_TOKEN` (token personal con permisos de jobs/sql)
- Para validaciones SQL: `DATABRICKS_SQL_WAREHOUSE_ID`

Alertas por SMTP (opcional):
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_ENABLE_SSL` (true/false), `ALERT_RECIPIENTS` (coma-separados), `ALERT_FROM`.

Ejemplos de uso (Bash):
```
export DATABRICKS_HOST='https://adb-xxxx.azuredatabricks.net'
export DATABRICKS_TOKEN='dapi...'
bash templates_ingenieria/scripts/create_all_jobs_curl.sh --submit
```

Ejemplo PowerShell:
```powershell
$env:DATABRICKS_HOST='https://adb-xxxx.azuredatabricks.net'
$env:DATABRICKS_TOKEN='dapi...'
.\templates_ingenieria\scripts\create_all_jobs.ps1 -SubmitRun
```

Logs:
- Todos los scripts guardan JSON/respuestas y estado en `templates_ingenieria/logs/` con marcas de tiempo.

Seguridad:
- No pongas tokens en repositorio ni en chats. Usa variables de entorno o secreto en CI.
