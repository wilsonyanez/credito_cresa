# README — Scripts de Creación de Jobs (Ingesta de Catálogos CRESA)

## 📋 Propósito General

Este directorio contiene scripts de automatización para **crear y administrar jobs de ingesta parametrizada** en Databricks. Los jobs procesan catálogos maestros desde SQL Server (`CREDITO_CRESA`) hacia la capa Bronze del lakehouse (`dlh_cresa.bronze`) usando la plataforma de orquestación de Databricks.

---

## 🎯 ¿Por Qué Se Crean Jobs y Archivos JSON?

### Necesidad
La ingesta de datos de múltiples fuentes (12+ catálogos) requiere:
- **Automatización**: Ejecución programada sin intervención manual
- **Confiabilidad**: Reintentos, alertas y trazabilidad
- **Escala**: Procesar múltiples catálogos en paralelo
- **Gobierno**: Registrar linaje, validaciones y controles de calidad

### Solución
1. **Archivos YAML** (`config/ingestion/`) — Configuración parametrizada de cada ingesta
2. **Archivos JSON** (`config/jobs/`) — Definición de jobs para Databricks Workflows
3. **Scripts de Automatización** (este directorio) — Crear jobs masivamente vía API

### Flujo de Datos

```
┌─────────────────────────────────────────────────────────────┐
│ SQL Server (CREDITO_CRESA)                                  │
│ ├─ cat_nacionalidad                                         │
│ ├─ cat_estadocivil                                          │
│ ├─ cat_tipoverificacion (← NUEVO)                           │
│ └─ ... (12 catálogos)                                       │
└────────────────────┬────────────────────────────────────────┘
                     │ Query SQL
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Databricks Notebook (template_pipeline_metadata_driven)     │
│ ├─ Lee YAML (parametrización)                              │
│ ├─ Valida datos (5+ reglas)                                │
│ ├─ Alerta si falla (SMTP)                                  │
│ └─ Escribe a Bronze                                        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Databricks Lakehouse (dlh_cresa.bronze)                    │
│ ├─ credito_cresa_cat_nacionalidad                          │
│ ├─ credito_cresa_cat_estadocivil                           │
│ ├─ credito_cresa_cat_tipoverificacion                      │
│ └─ ... + audit01 (control_plane)                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Archivos en Este Directorio

| Archivo | Tipo | Propósito | Plataforma |
|---|---|---|---|
| `create_databricks_jobs.ps1` | PowerShell | Crear jobs masivamente en Databricks | Windows/PowerShell 7+ |
| `create_all_jobs_comprehensive.sh` | Bash | Crear todos los jobs (incluido cat_tipoverificacion) | Linux/macOS/WSL |
| `create_job_credito_cresa_cat_tipoverificacion.sh` | Bash | Crear un job individual (cat_tipoverificacion) | Linux/macOS/WSL |
| `README.md` | Markdown | Este archivo | — |

---

## 🚀 Guía Rápida de Uso

### Opción 1: PowerShell (Windows)

```powershell
# 1. Obtener token Databricks
$token = "dapi-xxxxxxxxxxxx"  # Ver: Databricks User Settings → Generate Token

# 2. Ejecutar script
.\create_databricks_jobs.ps1 -Token $token -Env "prod"

# 3. Resultado
# → Logs en: .\logs\jobs_creation_YYYYMMDD_HHMMSS.log
# → Resumen en: .\logs\jobs_summary_YYYYMMDD_HHMMSS.txt
```

**Opciones adicionales**:
```powershell
# Especificar host y directorio
.\create_databricks_jobs.ps1 `
  -Token "dapi-..." `
  -DatabricksHost "https://adbdlh01.cloud.databricks.com" `
  -JobsConfigDir ".\templates_ingenieria\config\jobs" `
  -Env "prod"
```

### Opción 2: Bash (Linux/macOS/WSL)

```bash
# 1. Establecer token como variable de entorno
export DATABRICKS_TOKEN="dapi-xxxxxxxxxxxx"

# 2. Ejecutar script maestro (TODOS los jobs)
bash ./create_all_jobs_comprehensive.sh

# 3. O crear un job individual
bash ./create_job_credito_cresa_cat_tipoverificacion.sh

# 4. Resultado
# → Logs en: ./logs/jobs_creation_YYYYMMDD_HHMMSS.log
# → SQL de referencia incluida en logs
```

---

## 📋 Estándar de Nomenclatura

Todos los jobs siguen esta convención:

```
ingest_credito_cresa_<nombre_tabla>

Ejemplos:
- ingest_credito_cresa_cat_nacionalidad
- ingest_credito_cresa_cat_tipoverificacion
- ingest_credito_cresa_cat_sexo
```

**Campos JSON relacionados**:
```json
{
  "name": "ingest_credito_cresa_cat_tipoverificacion",
  "notebook_task": {
    "base_parameters": {
      "config_yml": "analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_tipoverificacion.yml"
    }
  }
}
```

---

## 🔧 Requisitos Previos

### Para PowerShell (Windows)
```powershell
# 1. PowerShell 7+ (o 5.1 con .NET 4.7.2)
$PSVersionTable.PSVersion

# 2. Permitir ejecución de scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Token Databricks (con permiso jobs:create)
# Obtener en: Databricks → User Settings → Generate Token
```

### Para Bash (Linux/macOS/WSL)
```bash
# 1. curl instalado
which curl

# 2. jq instalado (para parsear JSON)
which jq

# 3. Token Databricks
export DATABRICKS_TOKEN="dapi-..."

# 4. Permisos de ejecución
chmod +x create_all_jobs_comprehensive.sh
chmod +x create_job_credito_cresa_cat_tipoverificacion.sh
```

---

## 📊 Archivos Generados vs. Configuración

### Archivos de Configuración (NO ejecutables)

```
templates_ingenieria/
├── config/
│   ├── ingestion/
│   │   ├── credito_cresa_cat_nacionalidad.yml
│   │   ├── credito_cresa_cat_tipoverificacion.yml (← NUEVO)
│   │   └── ... (otros YAML)
│   └── jobs/
│       ├── credito_cresa_cat_nacionalidad_job.json
│       ├── credito_cresa_cat_tipoverificacion_job.json (← NUEVO)
│       └── ... (otros JSON)
```

### Scripts Ejecutables (este directorio)

```
templates_ingenieria/scripts/
├── create_databricks_jobs.ps1 (← actualizado)
├── create_all_jobs_comprehensive.sh (← actualizado)
├── create_job_credito_cresa_cat_tipoverificacion.sh (← NUEVO)
├── README.md (este archivo)
└── logs/ (generado al ejecutar)
    ├── jobs_creation_YYYYMMDD_HHMMSS.log
    └── jobs_summary_YYYYMMDD_HHMMSS.txt
```

---

## 💡 ¿Qué Hace Cada Script?

### `create_databricks_jobs.ps1` (PowerShell)

**Funcionalidad**:
1. Valida pre-requisitos (PowerShell 7+, curl, token válido)
2. Lee todos los archivos JSON en `config/jobs/`
3. Por cada job:
   - Envía POST a `Databricks API 2.1/jobs/create`
   - Valida HTTP 200 (éxito)
   - Registra job ID en logs
4. Genera SQL de validación para cat_tipoverificacion
5. Produce reporte resumen

**Parámetros**:
```powershell
-Token           (requerido) Token Databricks
-DatabricksHost  (opcional)  URL Databricks (default: https://adbdlh01.cloud.databricks.com)
-JobsConfigDir   (opcional)  Path a config/jobs (default: .\templates_ingenieria\config\jobs)
-Env             (opcional)  Ambiente: prod/dev/test (default: prod)
```

---

### `create_all_jobs_comprehensive.sh` (Bash)

**Funcionalidad**:
1. Valida pre-requisitos (bash, curl, jq, DATABRICKS_TOKEN)
2. Itera sobre array de 13 jobs (incluyendo cat_tipoverificacion)
3. Para cada job: crea vía API REST
4. Incluye SQL de referencia completa
5. Maneja errores y retry lógica

**Uso**:
```bash
export DATABRICKS_HOST="https://adbdlh01.cloud.databricks.com"
export DATABRICKS_TOKEN="dapi-..."
bash create_all_jobs_comprehensive.sh
```

---

### `create_job_credito_cresa_cat_tipoverificacion.sh` (Bash)

**Funcionalidad**:
1. Crea SOLO el job de `cat_tipoverificacion`
2. Valida prerrequisitos
3. Lee JSON de configuración
4. Crea job en Databricks
5. Habilita y verifica job creado

**Uso**:
```bash
export DATABRICKS_TOKEN="dapi-..."
bash create_job_credito_cresa_cat_tipoverificacion.sh
```

---

## ⚙️ Configuración de Ejecución

### Schedule (Programación)

Todos los jobs se ejecutan diariamente:

| Job | Hora (Zona: America/Bogota) | Prioridad |
|---|---|---|
| cat_nacionalidad | 02:00 AM | Baja |
| cat_estadocivil | 02:15 AM | Baja |
| cat_sexo | 02:30 AM | Baja |
| ... | ... | ... |
| **cat_tipoverificacion** | **03:00 AM** | **Alta** |
| ... | ... | ... |

### Alertas (Notificaciones)

```json
{
  "email_notifications": {
    "on_success": ["data-platform-team@empresa.local"],
    "on_failure": ["data-owner@empresa.local", "data-platform-team@empresa.local"]
  }
}
```

**Alertas SMTP adicionales** (configuradas en YAML):
- Cambio de conteo > 50% → MEDIUM severity
- Tiempo ejecución > 5 minutos → MEDIUM severity
- Validaciones fallidas → **CRITICAL** (bloquea ingesta)

---

## 📈 Validación Post-Ejecución

Después de crear los jobs, ejecutar en **Databricks SQL Editor**:

```sql
-- Contar jobs creados
SELECT COUNT(*) FROM system.compute.jobs WHERE name LIKE 'ingest_credito_cresa_%';

-- Revisar últimas ejecuciones
SELECT 
  job_id, 
  job_name,
  start_time,
  state,
  result_state
FROM system.compute.job_runs
WHERE job_name LIKE 'ingest_credito_cresa_cat_tipoverificacion'
ORDER BY start_time DESC
LIMIT 10;

-- Validar datos ingesta (ejemplo: cat_tipoverificacion)
SELECT COUNT(*) FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;
```

---

## 🐛 Troubleshooting

| Problema | Causa | Solución |
|---|---|---|
| "Authentication failed" | Token inválido o expirado | Generar nuevo token en Databricks User Settings |
| "Job already exists" | Job duplicado | Cambiar nombre o eliminar job anterior |
| "jq: command not found" | jq no instalado | `apt install jq` (Linux) o `brew install jq` (macOS) |
| "403 Forbidden" | Token sin permisos `jobs:create` | Revisar permisos en Admin Console |
| Script timeout | API lenta | Aumentar timeout en scripts (parámetro `--connect-timeout`) |

---

## 📚 Referencias Relacionadas

- **YAML Parametrizado**: `templates_ingenieria/config/ingestion/credito_cresa_cat_tipoverificacion.yml`
- **Job JSON**: `templates_ingenieria/config/jobs/credito_cresa_cat_tipoverificacion_job.json`
- **Instrucciones de Ejecución**: `templates_ingenieria/docs/INGEST_credito_cresa_cat_tipoverificacion_run.md`
- **Checklist de Cumplimiento**: `CHECKLIST_cat_tipoverificacion_cumplimiento.md`
- **Recomendaciones Técnicas**: `RECOMENDACIONES_cat_tipoverificacion.md`
- **Notebook Base**: `templates_ingenieria/notebooks/template_pipeline_metadata_driven.ipynb`

---

## 📝 Versionado

| Versión | Fecha | Cambios |
|---|---|---|
| 1.0 | 2026-07-15 | Creación inicial (12 catálogos) |
| 2.0 | 2026-08-27 | Añadir cat_tipoverificacion + validaciones SMTP |
| — | — | — |

---

## ✅ Checklist Final

Antes de pasar scripts a producción:

- [ ] Token Databricks generado y probado
- [ ] Archivos YAML en `config/ingestion/` validados
- [ ] Archivos JSON en `config/jobs/` validados
- [ ] Scripts tienen permisos de ejecución (`chmod +x`)
- [ ] Ejecutar script de prueba en ambiente TEST
- [ ] Validar tablas Bronze creadas
- [ ] Revisar logs sin errores CRITICAL
- [ ] Confirmar alertas SMTP funcionales
- [ ] Documentación actualizada
- [ ] Equipo notificado de cambios

---

## 📧 Contacto y Soporte

**Propietario**: Equipo de Datos - Maestro  
**Fase**: Fase 3 — Gobierno de Datos (DataOn)  
**Período**: Agosto-Septiembre 2026  
**Crítica**: Sí (requerido antes del 1 oct 2026 — switch Salesforce)

Para soporte, contactar:
- Data Owner: [Por asignar]
- DBA Team: dba-team@empresa.local
- Platform Team: data-platform-team@empresa.local

---

**Generado por**: Asistente IA  
**Última actualización**: 2026-08-27  
**Formato**: Markdown (compatible GitHub/GitLab/Databricks)

