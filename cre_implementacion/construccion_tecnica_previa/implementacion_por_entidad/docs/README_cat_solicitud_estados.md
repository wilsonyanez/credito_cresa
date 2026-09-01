# README — Jobs de `cat_solicitud_estados`

## Propósito

Este conjunto automatiza la ingesta de la entidad `CREDITO_CRESA.dbo.cat_solicitud_estados` hacia `dlh_cresa.bronze.credito_cresa_cat_solicitud_estados`. El YAML define la metadata, el JSON define el Workflow, los scripts crean los jobs y el runbook explica la ejecución y sus controles.

## Archivos

- `../config/ingestion/credito_cresa_cat_solicitud_estados.yml`: configuración metadata-driven, SQL, calidad, gobierno y SMTP.
- `../config/ingestion/jobs/credito_cresa_cat_solicitud_estados_job.json`: job solicitado.
- `../config/ingestion/JSON/credito_cresa_cat_solicitud_estados.json`: metadata de entidad y controles.
- `../docs/INGEST_credito_cresa_cat_solicitud_estados_run.md`: instrucciones y SQL post-run.
- `create_job_credito_cresa_cat_solicitud_estados.sh`: creación curl de un job.
- `create_databricks_jobs.ps1`: entrada PowerShell compatible. creación masiva con `create`, `test` y `dry-run`.
- `create_all_jobs_comprehensive.sh`: script maestro; incluye `cat_solicitud_estados` y su SQL de validación.

## Uso rápido

### PowerShell

```powershell
$env:DATABRICKS_TOKEN = "dapi-..."
.\create_databricks_jobs.ps1 -Mode dry-run
.\create_databricks_jobs.ps1 -Mode test
```

### Curl/Bash

```bash
export DATABRICKS_TOKEN="dapi-..."
sh create_job_credito_cresa_cat_solicitud_estados.sh
```

## Controles incluidos

- Conteo de registros por tabla e igualdad de claves únicas.
- Duplicados de `id`.
- Valores binarios de `es_activo`.
- Nulos de `id`, `nombre`.
- Orden y futuro de fechas `creado`/`actualizado`.
- Alertas SMTP por cambio de conteo mayor a 30%, duración mayor a 5 minutos y cualquier fallo de validación.

## Requisitos antes de producción

Configurar el token mediante secreto o variable segura, validar conectividad SQL Server, probar SMTP end-to-end, designar Data Owner y verificar la relación con `cat_solicitud_estados`. La sentencia solicitada usa `nolock`; para un table hint explícito en SQL Server, usar `WITH (NOLOCK)` según la política aprobada.
