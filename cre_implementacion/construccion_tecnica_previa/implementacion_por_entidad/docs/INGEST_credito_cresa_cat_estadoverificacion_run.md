# Instrucciones de ejecución: `credito_cresa_cat_estadoverificacion`

Pasos para ejecutar, validar y monitorear la ingesta de `cat_estadoverificacion` en `dlh_cresa.bronze` con controles de calidad y alertas SMTP.

## 1) Objetivo

- Ejecutar la ingesta parametrizada definida en `analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_estadoverificacion.yml`.
- Validar calidad de datos mediante reglas de negocio (primary key, activo binario, nulos, resolutivo).
- Enviar alertas por SMTP en caso de fallos o anomalías.
- Registrar linaje y metadatos en tablas de control (`audit01.gobierno_silver_reglas`, `audit01.log_procesos`).

## 2) SQL fuente (definida en el YAML)

```sql
SELECT id,nombre,activo,tipo_verificacion,resolutivo,naturaleza 
FROM CREDITO_CRESA.dbo.cat_estadoverificacion WITH (NOLOCK)
```

**Nota**: Se filtra por `activo = 1` (solo registros activos) y se ordena por `id ASC`.

## 3) Pre-requisitos

- Acceso Databricks al cluster de `dlh_cresa`.
- Conexión SQL Server activa a `CREDITO_CRESA` (credenciales en Databricks Secrets: `scope=cresa_secrets`, `key=sql_connection_string`).
- Acceso de escritura a esquema `dlh_cresa.bronze` y `dlh_cresa.audit01`.
- Configuración SMTP funcional (host: `smtp.empresa.local`, puerto 587, TLS habilitado).
- Notebook `templates_ingenieria/notebooks/template_pipeline_metadata_driven.ipynb` disponible en el repositorio de Databricks.

## 4) Ejecutar el notebook metadata-driven en Databricks

### Opción A: Ejecución Manual (Test)

1. Abrir Databricks → Workspace → Notebooks.
2. Navegar a `templates_ingenieria/notebooks/template_pipeline_metadata_driven.ipynb`.
3. En la celda de parámetros, ingresar:
   ```
   config_yml = "analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_estadoverificacion.yml"
   run_mode = "test"
   enable_quality_checks = "true"
   enable_alerts = "false"  # Desactivar alertas en test para evitar ruido
   ```
4. Ejecutar el notebook completo (`Ctrl+Shift+Return`).
5. Validar en **Output** que no hay errores críticos (ver Sección 5).

### Opción B: Ejecución Programada (Job)

1. En Databricks → Workflows → Jobs.
2. Crear job nuevo:
   - **Name**: `ingest_credito_cresa_cat_estadoverificacion`
   - **Notebook path**: `/Repos/your_repo/path/templates_ingenieria/notebooks/template_pipeline_metadata_driven`
   - **Base parameters**:
     ```json
     {
       "config_yml": "analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_estadoverificacion.yml",
       "run_mode": "production",
       "enable_quality_checks": "true",
       "enable_alerts": "true"
     }
     ```
   - **Schedule**: `0 0 2 * * ?` (diariamente a las 2:00 AM, zona horaria America/Bogota).
   - **Max retries**: 2.
   - **Timeout**: 30 minutos (1800 segundos).
   - **Email notifications**: 
     - On success: `data-platform-team@empresa.local`
     - On failure: `data-owner@empresa.local`, `data-platform-team@empresa.local`

3. Guardar y activar job.

## 5) Validaciones Post-Run (SQL de Ejemplo)

Ejecutar después de cada ingesta (manual o programada):

### 5.1) Conteo total de registros

```sql
SELECT 
  COUNT(*) AS total_registros,
  COUNT(DISTINCT id) AS ids_unicos,
  COUNT(DISTINCT nombre) AS nombres_unicos
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion;
```

**Esperado**: Al menos 1 registro; ids_unicos = total_registros (sin duplicados).

### 5.2) Verificar duplicados por `id` (Primary Key Check)

```sql
SELECT id, COUNT(*) AS cnt, STRING_AGG(nombre, ', ') AS nombres
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion
GROUP BY id
HAVING COUNT(*) > 1
ORDER BY cnt DESC;
```

**Esperado**: Resultado vacío (cero duplicados).

### 5.3) Validar valores de `es_activo` (deben ser 0 o 1)

```sql
SELECT DISTINCT es_activo, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion
GROUP BY es_activo
ORDER BY es_activo;
```

**Esperado**: Solo valores 0 y/o 1.

### 5.4) Validar valores de `resolutivo` (0, 1 o NULL)

```sql
SELECT DISTINCT resolutivo, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion
GROUP BY resolutivo
ORDER BY resolutivo;
```

**Esperado**: Solo valores 0, 1 o NULL.

### 5.5) Validar registros con valores nulos críticos

```sql
SELECT 
  COUNT(CASE WHEN id IS NULL THEN 1 END) AS nulls_id,
  COUNT(CASE WHEN nombre IS NULL THEN 1 END) AS nulls_nombre,
  COUNT(CASE WHEN tipo_verificacion IS NULL THEN 1 END) AS nulls_tipo_verificacion
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion;
```

**Esperado**: Todos los conteos = 0 (sin nulos en campos críticos).

### 5.6) Muestra de filas (primeras 50)

```sql
SELECT TOP 50 
  id, nombre, es_activo, tipo_verificacion, resolutivo, naturaleza
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion
ORDER BY id;
```

### 5.7) Distribución por tipo_verificacion

```sql
SELECT 
  tipo_verificacion, 
  COUNT(*) AS cnt,
  COUNT(CASE WHEN es_activo = 1 THEN 1 END) AS activos,
  COUNT(CASE WHEN resolutivo = 1 THEN 1 END) AS resolutivos
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion
GROUP BY tipo_verificacion
ORDER BY cnt DESC;
```

### 5.8) Revisar últimas ejecuciones (tabla de control)

```sql
SELECT TOP 20
  run_id, 
  config_path,
  status,
  records_processed,
  records_failed,
  execution_time_seconds,
  started_at,
  completed_at
FROM dlh_cresa.audit01.log_procesos
WHERE config_path LIKE '%credito_cresa_cat_estadoverificacion%'
ORDER BY started_at DESC;
```

## 6) Alertas SMTP — Configuración y Manejo

### 6.1) Alertas Activadas Automáticamente

El YAML define las siguientes alertas (con `enable_alerts: "true"`):

| Condición | Severidad | Acción | Destinatarios |
|---|---|---|---|
| Cambio de conteo > 30% | MEDIUM | Email | data-platform-team@empresa.local |
| Tiempo ejecución > 5 min | MEDIUM | Email a DBA | dba-team@empresa.local |
| Validaciones con fallos > 0 | **CRITICAL** | Bloquear + Email | data-owner@empresa.local, data-platform-team@empresa.local |

**Email de alerta típico** (CRITICAL):
```
Asunto: [CRITICAL] Ingesta Fallida - credito_cresa_cat_estadoverificacion

Cuerpo:
Job: ingest_credito_cresa_cat_estadoverificacion
Estado: FAILED
Timestamp: 2026-08-27 02:05:17 UTC
Razón: Validación PRIMARY_KEY_CHECK falló — 3 registros con id duplicado

Detalles:
- IDs duplicados: [45, 67, 89]
- Registros totales procesados: 892
- Registros fallidos: 3
- Tabla de errores: dlh_cresa.audit01.log_procesos

Acción requerida:
1. Revisar SQL fuente (CREDITO_CRESA.dbo.cat_estadoverificacion) para duplicados.
2. Investigar query con NOLOCK — puede haber inconsistencias transaccionales.
3. Contactar a Equipo de Datos - Maestro para resolución.
```

### 6.2) Manejo Manual de Fallos

Si recibe alerta CRITICAL:

1. **Verificar la tabla de control**:
   ```sql
   SELECT TOP 1 * FROM dlh_cresa.audit01.log_procesos 
   WHERE run_id = '<run_id_del_email>'
   ORDER BY completed_at DESC;
   ```

2. **Revisar detalles de error**:
   ```sql
   SELECT * FROM dlh_cresa.audit01.control_calidad_ingestion
   WHERE run_id = '<run_id_del_email>' AND status = 'FAILED'
   ORDER BY validation_timestamp DESC;
   ```

3. **Re-ejecutar**:
   - Corregir en origen (SQL Server) si es necesario.
   - Reejecutar el job manualmente en Databricks → Workflows → Jobs → `ingest_credito_cresa_cat_estadoverificacion` → Run Now.

### 6.3) Desactivar Alertas Temporalmente

Para troubleshooting, modificar parámetro del job:
```json
"enable_alerts": "false"
```
**⚠️ Advertencia**: No dejar desactivado en producción.

## 7) Documentación Relacionada

- **Plantilla YAML parametrizada**: `templates_ingenieria/config/ingestion/credito_cresa_cat_estadoverificacion.yml`
- **Configuración del job**: `templates_ingenieria/config/jobs/credito_cresa_cat_estadoverificacion_job.json`
- **Notebook base**: `templates_ingenieria/notebooks/template_pipeline_metadata_driven.ipynb`
- **Script PowerShell (crear job)**: `templates_ingenieria/scripts/create_databricks_jobs.ps1`
- **Script curl (crear job)**: `templates_ingenieria/scripts/create_job_credito_cresa_cat_estadoverificacion.sh`
- **Script maestro (todos los jobs)**: `templates_ingenieria/scripts/create_all_jobs.sh`

## 8) Notas Importantes

- `WITH (NOLOCK)` puede devolver lecturas inconsistentes; es aceptable para catálogos de bajo movimiento, pero se recomienda monitorear discrepancias.
- Campo `tipo_verificacion` es restringido (L2); no exponerlo sin control de acceso.
- Campo `naturaleza` es restringido; aplicar clasificación de datos en Purview.
- Actualizar `governance.data_owner` con el owner oficial en Comité Directivo.
- Las alertas SMTP requieren credenciales configuradas en Databricks → Admin Console → Workspace settings → SMTP settings.

## 9) Troubleshooting

| Síntoma | Causa Probable | Solución |
|---|---|---|
| Job falla con "connection refused" | Conexión SQL Server no disponible | Verificar credenciales en Databricks Secrets; revisar firewall entre Databricks y SQL Server |
| "Table already exists" | Tabla Bronze ya existe sin modo merge | Cambiar `write_mode_delta: merge` en YAML o borrar tabla con `DROP TABLE dlh_cresa.bronze.credito_cresa_cat_estadoverificacion PURGE` |
| SMTP no envía email | Credenciales SMTP incorrectas | Revisar en Databricks Admin Console → workspace settings; verificar que puertos 587/465 no estén bloqueados |
| Validaciones fallan constantemente | Esquema de tabla cambió en origen | Actualizar `columns.include` en YAML para coincidir con esquema actual |
| Cambio de conteo > 30% sin causa conocida | Posible cambio de estado en origen | Investigar si hubo actualización masiva o cambio de política en `activo` |

