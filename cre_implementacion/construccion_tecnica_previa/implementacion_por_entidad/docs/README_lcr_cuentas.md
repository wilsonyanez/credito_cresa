# README — Jobs de `lcr_cuentas`

## Propósito

Este conjunto automatiza la ingesta de la entidad `CREDITO_CRESA.dbo.lcr_cuentas` hacia `dlh_cresa.bronze.credito_cresa_lcr_cuentas`. El YAML define la metadata, el JSON define el Workflow, los scripts crean los jobs y el runbook explica la ejecución y sus controles.

## Archivos

- `../config/ingestion/credito_cresa_lcr_cuentas.yml`: configuración metadata-driven, SQL, calidad, gobierno y SMTP.
- `../config/ingestion/job/credito_cresa_lcr_cuentas_job.json`: job solicitado.
- `../config/ingestion/JSON/credito_cresa_lcr_cuentas.json`: metadata de entidad y controles.
- `../docs/INGEST_credito_cresa_lcr_cuentas_run.md`: instrucciones y SQL post-run.
- `create_job_credito_cresa_lcr_cuentas.sh`: creación curl de un job.
- `create_databricks_jobs.ps1`: Entrada PowerShell compatible. Creación masiva con `create`, `test` y `dry-run`.
- `create_all_jobs_comprehensive.sh`: script maestro; incluye `lcr_cuentas` y su SQL de validación.

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
sh create_job_credito_cresa_lcr_cuentas.sh
```

## Controles incluidos

- Conteo de registros por tabla e igualdad de claves únicas.
- Duplicados de `id`.
- Valores binarios de `es_actual`.
- Nulos de `id`, `nombre_empresa` y `es_actual`.
- Orden y futuro de fechas `creado`/`actualizado`.
- Alertas SMTP por cambio de conteo mayor a 30%, duración mayor a 5 minutos y cualquier fallo de validación.

## Requisitos antes de producción

Configurar el token mediante secreto o variable segura, validar conectividad SQL Server, probar SMTP end-to-end, designar Data Owner y verificar la relación con `lcr_cuentas`. La sentencia solicitada usa `nolock`; para un table hint explícito en SQL Server, usar `WITH (NOLOCK)` según la política aprobada.
