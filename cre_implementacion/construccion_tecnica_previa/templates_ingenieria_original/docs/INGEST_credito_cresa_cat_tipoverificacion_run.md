# Instrucciones de ejecución: `credito_cresa_cat_tipoverificacion`

Pasos para ejecutar, validar y monitorear la ingesta de `cat_tipoverificacion` en `dlh_cresa.bronze` con controles de calidad y alertas SMTP.

## 1) Objetivo

- Ejecutar la ingesta parametrizada definida en `templates_ingenieria/config/ingestion/credito_cresa_cat_tipoverificacion.yml`.
- Validar calidad de datos mediante reglas de negocio (primary key, estado binario, fechas, valores nulos).
- Enviar alertas por SMTP en caso de fallos o anomalías.
- Registrar linaje y metadatos en tablas de control (`audit01.gobierno_silver_reglas`, `audit01.log_procesos`).

## 2) SQL fuente (definida en el YAML)

```sql
SELECT id,nombre,jerarquia,estado,creado,actualizado,creado_por,actualizado_por,naturaleza 
FROM CREDITO_CRESA.dbo.cat_tipoverificacion WITH (NOLOCK)
```

**Nota**: Se filtra por `estado = 1` (solo registros activos) y se ordena por `id ASC`.

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
   config_yml = "analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_tipoverificacion.yml"
   run_mode = "test"
   enable_quality_checks = "true"
   enable_alerts = "false"  # Desactivar alertas en test para evitar ruido
   ```
4. Ejecutar el notebook completo (`Ctrl+Shift+Return`).
5. Validar en **Output** que no hay errores críticos (ver Sección 5).

### Opción B: Ejecución Programada (Job)

1. En Databricks → Workflows → Jobs.
2. Crear job nuevo:
   - **Name**: `ingest_credito_cresa_cat_tipoverificacion`
   - **Notebook path**: `/Repos/your_repo/path/templates_ingenieria/notebooks/template_pipeline_metadata_driven`
   - **Base parameters**:
     ```json
     {
       "config_yml": "analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_tipoverificacion.yml",
       "run_mode": "production",
       "enable_quality_checks": "true",
       "enable_alerts": "true"
     }
     ```
   - **Schedule**: `0 0 3 * * ?` (diariamente a las 3:00 AM, zona horaria America/Bogota).
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
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;
```

**Esperado**: Al menos 1 registro; ids_unicos = total_registros (sin duplicados).

### 5.2) Verificar duplicados por `id` (Primary Key Check)

```sql
SELECT id, COUNT(*) AS cnt, STRING_AGG(nombre, ', ') AS nombres
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion
GROUP BY id
HAVING COUNT(*) > 1
ORDER BY cnt DESC;
```

**Esperado**: Resultado vacío (cero duplicados).

### 5.3) Validar valores de `estado` (deben ser 0 o 1)

```sql
SELECT DISTINCT estado, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion
GROUP BY estado
ORDER BY estado;
```

**Esperado**: Solo valores 0 y/o 1.

### 5.4) Validar registros con valores nulos críticos

```sql
SELECT 
  COUNT(CASE WHEN id IS NULL THEN 1 END) AS nulls_id,
  COUNT(CASE WHEN nombre IS NULL THEN 1 END) AS nulls_nombre,
  COUNT(CASE WHEN jerarquia IS NULL THEN 1 END) AS nulls_jerarquia
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;
```

**Esperado**: Todos los conteos = 0 (sin nulos en campos críticos).

### 5.5) Muestra de filas (primeras 50)

```sql
SELECT TOP 50 
  id, nombre, jerarquia, estado, creado, actualizado, creado_por, actualizado_por, naturaleza
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion
ORDER BY id;
```

### 5.6) Validar fechas (creado/actualizado no deben ser del futuro)

```sql
SELECT 
  COUNT(CASE WHEN creado > CURRENT_TIMESTAMP() THEN 1 END) AS fechas_futuro_creado,
  COUNT(CASE WHEN actualizado > CURRENT_TIMESTAMP() THEN 1 END) AS fechas_futuro_actualizado,
  MIN(creado) AS fecha_creacion_minima,
  MAX(actualizado) AS fecha_actualizacion_maxima
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;
```

**Esperado**: Todos los conteos de fechas futuro = 0.

### 5.7) Revisar últimas ejecuciones (tabla de control)

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
WHERE config_path LIKE '%credito_cresa_cat_tipoverificacion%'
ORDER BY started_at DESC;
```

## 6) Alertas SMTP — Configuración y Manejo

### 6.1) Alertas Activadas Automáticamente

El YAML define las siguientes alertas (con `enable_alerts: "true"`):

| Condición | Severidad | Acción | Destinatarios |
|---|---|---|---|
| Cambio de conteo > 50% | MEDIUM | Email | data-platform-team@empresa.local |
| Tiempo ejecución > 5 min | MEDIUM | Email a DBA | dba-team@empresa.local |
| Validaciones con fallos > 0 | **CRITICAL** | Bloquear + Email | data-owner@empresa.local, data-platform-team@empresa.local |

**Email de alerta típico** (CRITICAL):
```
Asunto: [CRITICAL] Ingesta Fallida - credito_cresa_cat_tipoverificacion

Cuerpo:
Job: ingest_credito_cresa_cat_tipoverificacion
Estado: FAILED
Timestamp: 2026-08-27 03:05:17 UTC
Razón: Validación PRIMARY_KEY_CHECK falló — 5 registros con id duplicado

Detalles:
- IDs duplicados: [123, 456, 789]
- Registros totales procesados: 1,245
- Registros fallidos: 5
- Tabla de errores: dlh_cresa.audit01.log_procesos

Acción requerida:
1. Revisar SQL fuente (CREDITO_CRESA.dbo.cat_tipoverificacion) para duplicados.
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
   - Reejecutar el job manualmente en Databricks → Workflows → Jobs → `ingest_credito_cresa_cat_tipoverificacion` → Run Now.

### 6.3) Desactivar Alertas Temporalmente

Para troubleshooting, modificar parámetro del job:
```json
"enable_alerts": "false"
```
**⚠️ Advertencia**: No dejar desactivado en producción.

## 7) Documentación Relacionada

- **Plantilla YAML parametrizada**: `templates_ingenieria/config/ingestion/credito_cresa_cat_tipoverificacion.yml`
- **Configuración del job**: `templates_ingenieria/config/jobs/credito_cresa_cat_tipoverificacion_job.json`
- **Notebook base**: `templates_ingenieria/notebooks/template_pipeline_metadata_driven.ipynb`
- **Script PowerShell (crear job)**: `templates_ingenieria/scripts/create_databricks_jobs.ps1`
- **Script curl (crear job)**: `templates_ingenieria/scripts/create_job_credito_cresa_cat_tipoverificacion.sh`
- **Script maestro (todos los jobs)**: `templates_ingenieria/scripts/create_all_jobs.sh`

## 8) Notas Importantes

- `WITH (NOLOCK)` puede devolver lecturas inconsistentes; es aceptable para catálogos de bajo movimiento, pero se recomienda monitorear discrepancias.
- Si se requiere ingesta incremental auténtica, activar `incremental_mode: true` en YAML y poblaar `watermark_column: actualizado`.
- Actualizar `governance.data_owner` con el owner oficial en Comité Directivo.
- Las alertas SMTP requieren credenciales configuradas en Databricks → Admin Console → Workspace settings → SMTP settings.

## 9) Troubleshooting

| Síntoma | Causa Probable | Solución |
|---|---|---|
| Job falla con "connection refused" | Conexión SQL Server no disponible | Verificar credenciales en Databricks Secrets; revisar firewall entre Databricks y SQL Server |
| "Table already exists" | Tabla Bronze ya existe sin modo merge | Cambiar `write_mode_delta: merge` en YAML o borrar tabla con `DROP TABLE dlh_cresa.bronze.credito_cresa_cat_tipoverificacion PURGE` |
| SMTP no envía email | Credenciales SMTP incorrectas | Revisar en Databricks Admin Console → workspace settings; verificar que puertos 587/465 no estén bloqueados |
| Validaciones fallan constantemente | Esquema de tabla cambió en origen | Actualizar `columns.include` en YAML para coincidir con esquema actual |

