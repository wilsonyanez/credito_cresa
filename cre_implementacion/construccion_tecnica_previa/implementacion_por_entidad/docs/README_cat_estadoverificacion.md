# README — Scripts de Creación de Jobs `cat_estadoverificacion`

## 📋 Propósito

Este directorio contiene scripts de automatización para **crear jobs de ingesta parametrizada** en Databricks para la tabla `cat_estadoverificacion` (Estados de Verificación).

### ¿Por Qué Se Crean Jobs y JSON?

1. **Automatización**: Ejecución programada sin intervención manual
2. **Confiabilidad**: Reintentos, alertas SMTP y trazabilidad
3. **Escalabilidad**: Procesar múltiples catálogos en paralelo
4. **Gobierno**: Registrar linaje, validaciones y calidad de datos

---

## 📦 Archivos Incluidos

| Archivo | Tipo | Propósito | Plataforma |
|---|---|---|---|
| `create_databricks_jobs.ps1` | PowerShell | Crear jobs masivamente | Windows/PowerShell 7+ |
| `create_all_jobs_comprehensive.sh` | Bash | Crear todos los jobs (14 catálogos) | Linux/macOS/WSL |
| `create_job_credito_cresa_cat_estadoverificacion.sh` | Bash | Crear job individual | Linux/macOS/WSL |
| `README.md` | Markdown | Este archivo | — |

---

## 🚀 Guía Rápida

### Opción 1: PowerShell (Windows)

```powershell
# 1. Obtener token Databricks
$token = "dapi-xxxxxxxxxxxx"

# 2. Ejecutar script (crear todos los jobs)
.\create_databricks_jobs_v2.ps1 -Token $token -Mode "test"

# 3. Si está OK, cambiar a modo create
.\create_databricks_jobs_v2.ps1 -Token $token -Mode "create"
```

### Opción 2: Bash (Linux/macOS/WSL)

```bash
# 1. Configurar token
export DATABRICKS_TOKEN="dapi-xxxxxxxxxxxx"

# 2. Crear job individual
bash ./create_job_credito_cresa_cat_estadoverificacion.sh

# O crear TODOS los 14 jobs
bash ./create_all_jobs_comprehensive_v2.sh
```

---

## ⚙️ Parámetros de Scripts

### PowerShell

```powershell
.\create_databricks_jobs_v2.ps1 `
  -Token "dapi-..." `
  -Host "https://adbdlh01.cloud.databricks.com" `
  -Mode "create"  # create|test|dry-run `
  -JobsConfigDir ".\templates_ingenieria\config\jobs" `
  -SkipValidation  # opcional: saltarse validaciones
```

### Bash

```bash
export DATABRICKS_HOST="https://adbdlh01.cloud.databricks.com"
export DATABRICKS_TOKEN="dapi-..."
bash create_all_jobs_comprehensive_v2.sh
```

---

## 📊 Configuración de Jobs

**Tabla `cat_estadoverificacion`**:
- Schedule: `0 0 2 * * ?` (02:00 AM diarios, zona America/Bogota)
- Max retries: 2
- Timeout: 30 minutos
- Notificaciones email: on_success, on_failure

**Campos ingesta**:
- id (Primary Key)
- nombre
- activo (binario 0/1)
- tipo_verificacion
- resolutivo (binario 0/1 o NULL)
- naturaleza

**Validaciones**:
- 5 reglas de validación (PK, activo, nombre no nulo, tipo_verificacion no nulo, resolutivo)
- 3 alertas SMTP (cambio conteo > 30%, tiempo > 5 min, validaciones fallidas)

---

## 📁 Estructura de Archivos

```
templates_ingenieria/
├── config/
│   ├── ingestion/
│   │   ├── credito_cresa_cat_nacionalidad.yml
│   │   ├── ... (otros YAML)
│   │   └── credito_cresa_cat_estadoverificacion.yml ← NUEVO
│   │
│   └── jobs/
│       ├── credito_cresa_cat_nacionalidad_job.json
│       ├── ... (otros JSON)
│       └── credito_cresa_cat_estadoverificacion_job.json ← NUEVO
│
├── docs/
│   ├── INGEST_credito_cresa_cat_nacionalidad_run.md
│   ├── ... (otros docs)
│   └── INGEST_credito_cresa_cat_estadoverificacion_run.md ← NUEVO
│
└── scripts/
    ├── create_databricks_jobs_v2.ps1 (actualizado)
    ├── create_all_jobs_comprehensive_v2.sh (actualizado)
    ├── create_job_credito_cresa_cat_estadoverificacion.sh ← NUEVO
    └── README.md (este archivo)
```

---

## ✅ Pre-requisitos

### Para PowerShell (Windows)
- PowerShell 7+ (o 5.1 con .NET 4.7.2)
- Permitir scripts: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`
- Token Databricks (con permiso `jobs:create`)

### Para Bash (Linux/macOS/WSL)
- `bash` 4+
- `curl`
- `jq` (para parsear JSON)
- Token Databricks

---

## 🔍 Validación Post-Creación

Después de crear los jobs, ejecutar en Databricks SQL Editor:

```sql
-- Contar jobs creados
SELECT COUNT(*) FROM system.compute.jobs 
WHERE name LIKE 'ingest_credito_cresa_%';

-- Revisar últimas ejecuciones de cat_estadoverificacion
SELECT 
  job_id, 
  job_name,
  start_time,
  state,
  result_state
FROM system.compute.job_runs
WHERE job_name LIKE '%cat_estadoverificacion%'
ORDER BY start_time DESC
LIMIT 10;

-- Validar datos ingesta
SELECT COUNT(*) FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion;
```

---

## 🐛 Troubleshooting

| Problema | Solución |
|---|---|
| "Authentication failed" | Verificar token en Databricks User Settings |
| "Table already exists" | Usar modo merge o borrar tabla |
| "jq: command not found" | Instalar: `apt install jq` (Linux) o `brew install jq` (macOS) |
| "403 Forbidden" | Verificar permisos de token (jobs:create) |
| Script timeout | Aumentar timeout en scripts |

---

## 📞 Contactos

- **Data Platform Team**: data-platform-team@empresa.local
- **DBA Team**: dba-team@empresa.local
- **Oficina Seguridad**: gustavo.garcia@empresa.local

---

**Generado por**: Equipo de Datos - Maestro  
**Fecha**: 2026-08-27  
**Versión**: 2.1  
**Crítica**: Sí (requerido antes del 1 oct 2026)

