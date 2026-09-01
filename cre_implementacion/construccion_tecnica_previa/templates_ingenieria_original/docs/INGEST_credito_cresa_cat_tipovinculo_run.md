# INGEST - credito_cresa_cat_tipovinculo

Descripción: Ingesta del catálogo `cat_tipovinculo` desde la base `CREDITO_CRESA`.

SQL ejecutado:

```sql
SELECT id,nombre,es_activo FROM CREDITO_CRESA.dbo.cat_tipovinculo WITH (NOLOCK)
```

Pasos de ejecución:

1. Revisar y exportar variables de entorno: `DATABRICKS_HOST`, `DATABRICKS_TOKEN`, `DATABRICKS_SQL_WAREHOUSE_ID`.
2. Crear job en Databricks (curl o PowerShell) usando el job JSON: `templates_ingenieria/config/jobs/credito_cresa_cat_tipovinculo_job.json`.
3. (Opcional) Enviar un run de prueba desde PowerShell: `create_all_jobs.ps1 -SubmitRun` o usando `runs/submit`.
4. Verificar logs en `templates_ingenieria/logs/` y revisar el resultado de las validaciones.

Validaciones automáticas aplicadas tras la carga:
- Conteo total (esperado > 0)
- Duplicados sobre `id` (esperado = 0)
- Nulls en `id` (esperado = 0)

Alertas:
- Si alguna validación falla, el script que ejecuta el run enviará un correo a los destinatarios configurados en `SMTP`.

Notas:
- El job creado usa `run_mode: test` por defecto; cambiar a `production` después de verificar ejecuciones.
