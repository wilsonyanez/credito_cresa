#!/bin/bash

# Script: create_all_jobs_comprehensive.sh
# Propósito: Crear TODOS los jobs de ingesta en Databricks (incluido nuevo: cat_tipoverificacion)
# Autor: Equipo de Datos - Maestro
# Fecha: 2026-08-27
# Versión: 2.0 (ACTUALIZADO con cat_tipoverificacion)

set -e

# ============================================
# CONFIGURACIÓN
# ============================================

DATABRICKS_HOST="https://adbdlh01.cloud.databricks.com"
DATABRICKS_TOKEN="${DATABRICKS_TOKEN}"
JOBS_CONFIG_DIR="./templates_ingenieria/config/jobs"
LOG_DIR="./logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/jobs_creation_$TIMESTAMP.log"
SUMMARY_FILE="$LOG_DIR/jobs_summary_$TIMESTAMP.txt"

# Array de jobs a crear (MANTENER ORDEN DE PRECEDENCIA)
declare -a JOBS=(
  "credito_cresa_cat_nacionalidad_job.json"
  "credito_cresa_cat_estadocivil_job.json"
  "credito_cresa_cat_sexo_job.json"
  "credito_cresa_cat_nivelinstruccion_job.json"
  "credito_cresa_cat_provincia_job.json"
  "credito_cresa_cat_canton_job.json"
  "credito_cresa_cat_parroquia_job.json"
  "credito_cresa_cat_origen_job.json"
  "credito_cresa_cat_modelo_aprobador_job.json"
  "credito_cresa_cat_modelo_calificacion_job.json"
  "credito_cresa_cat_solicitud_estados_job.json"
  "credito_cresa_cat_tipovinculo_job.json"
  "credito_cresa_cat_tipoverificacion_job.json"  # ← NUEVO
)

# ============================================
# FUNCIONES
# ============================================

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_summary() {
  echo "$1" >> "$SUMMARY_FILE"
}

error_exit() {
  log "ERROR: $1"
  exit 1
}

init_logs() {
  mkdir -p "$LOG_DIR"
  > "$LOG_FILE"
  > "$SUMMARY_FILE"
  log "Logs inicializados: $LOG_FILE"
}

validate_prerequisites() {
  log "Validando pre-requisitos..."
  
  [[ -z "$DATABRICKS_TOKEN" ]] && error_exit "DATABRICKS_TOKEN no está configurado"
  [[ ! -d "$JOBS_CONFIG_DIR" ]] && error_exit "Directorio de jobs no encontrado: $JOBS_CONFIG_DIR"
  
  command -v curl >/dev/null || error_exit "curl no instalado"
  command -v jq >/dev/null || error_exit "jq no instalado"
  
  log "✓ Pre-requisitos validados"
}

create_job() {
  local job_file="$1"
  local config_path="$JOBS_CONFIG_DIR/$job_file"
  
  if [[ ! -f "$config_path" ]]; then
    log "⚠ Saltando: $job_file (archivo no encontrado)"
    return 1
  fi
  
  log "Procesando: $job_file"
  
  JOB_JSON=$(cat "$config_path")
  JOB_NAME=$(echo "$JOB_JSON" | jq -r '.name')
  
  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    "$DATABRICKS_HOST/api/2.1/jobs/create" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JOB_JSON" \
    --connect-timeout 30 \
    --max-time 90)
  
  HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
  RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [[ $HTTP_CODE -eq 200 ]]; then
    JOB_ID=$(echo "$RESPONSE_BODY" | jq -r '.job_id')
    log "  ✓ Job creado: $JOB_NAME (ID: $JOB_ID)"
    log_summary "✓ $JOB_NAME (ID: $JOB_ID)"
    return 0
  else
    log "  ✗ Fallo (HTTP $HTTP_CODE): $JOB_NAME"
    log_summary "✗ $JOB_NAME (HTTP $HTTP_CODE)"
    return 1
  fi
}

execute_sql_query() {
  log "Ejecutando SQL de referencia: cat_tipoverificacion..."
  
  cat << 'EOF'

-- SQL DE REFERENCIA: cat_tipoverificacion
-- Ejecutar en Databricks SQL Editor después de cada ingesta
-- Propósito: Validar calidad y cobertura de datos

-- 1. Conteo total de registros
SELECT 
  COUNT(*) AS total_registros,
  COUNT(DISTINCT id) AS ids_unicos,
  COUNT(DISTINCT nombre) AS nombres_unicos
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;

-- 2. Verificar duplicados por Primary Key (id)
SELECT id, COUNT(*) AS cnt, STRING_AGG(nombre, ', ') AS nombres
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion
GROUP BY id
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- 3. Distribución de estado (0/1)
SELECT estado, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion
GROUP BY estado
ORDER BY estado;

-- 4. Validar nulos en campos críticos
SELECT 
  COUNT(CASE WHEN id IS NULL THEN 1 END) AS nulls_id,
  COUNT(CASE WHEN nombre IS NULL THEN 1 END) AS nulls_nombre,
  COUNT(CASE WHEN jerarquia IS NULL THEN 1 END) AS nulls_jerarquia
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;

-- 5. Rango de fechas
SELECT 
  MIN(creado) AS fecha_creacion_minima,
  MAX(creado) AS fecha_creacion_maxima,
  MIN(actualizado) AS fecha_actualizacion_minima,
  MAX(actualizado) AS fecha_actualizacion_maxima
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;

-- 6. Muestra de datos
SELECT TOP 50 
  id, nombre, jerarquia, estado, creado, actualizado, creado_por, actualizado_por, naturaleza
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion
ORDER BY id;

-- 7. Últimas ejecuciones (tabla de control)
SELECT TOP 10
  run_id, 
  config_path,
  status,
  records_processed,
  records_failed,
  execution_time_seconds,
  started_at,
  completed_at
FROM dlh_cresa.audit01.log_procesos
WHERE config_path LIKE '%cat_tipoverificacion%'
ORDER BY started_at DESC;

EOF

  log "✓ SQL de referencia incluida en logs"
}

generate_report() {
  log ""
  log "=========================================="
  log "RESUMEN DE CREACIÓN DE JOBS"
  log "=========================================="
  log_summary "=========================================="
  log_summary "REPORTE DE CREACIÓN DE JOBS"
  log_summary "Fecha: $(date)"
  log_summary "Total jobs: ${#JOBS[@]}"
  log_summary "=========================================="
  log_summary ""
  log_summary "RESULTADOS:"
  log_summary "$(cat "$SUMMARY_FILE" | grep -E "^✓|^✗")"
  log_summary ""
  log_summary "=========================================="
  log_summary "Para detalles, revisar: $LOG_FILE"
}

# ============================================
# EJECUCIÓN PRINCIPAL
# ============================================

main() {
  init_logs
  
  log "=========================================="
  log "CREACIÓN DE JOBS - INGESTA CATALÓGOS CRESA"
  log "=========================================="
  log "Host: $DATABRICKS_HOST"
  log "Total jobs a crear: ${#JOBS[@]}"
  log ""
  
  validate_prerequisites
  
  local success=0
  local failed=0
  
  for job_file in "${JOBS[@]}"; do
    if create_job "$job_file"; then
      ((success++))
    else
      ((failed++))
    fi
  done
  
  log ""
  execute_sql_query
  
  log ""
  log "=========================================="
  log "RESUMEN DE EJECUCIÓN"
  log "=========================================="
  log "Jobs exitosos: $success"
  log "Jobs fallidos: $failed"
  log "Logs guardados en: $LOG_FILE"
  log "Reporte guardado en: $SUMMARY_FILE"
  log "=========================================="
  
  # Retornar código de salida según fallos
  [[ $failed -gt 0 ]] && exit 1 || exit 0
}

main "$@"
