#!/bin/bash

# Script: create_all_jobs_comprehensive_v2.sh
# Propósito: Crear TODOS los jobs de ingesta en Databricks (incluido nuevo: cat_estadoverificacion)
# Autor: Equipo de Datos - Maestro
# Fecha: 2026-08-27
# Versión: 2.1 (ACTUALIZADO con cat_estadoverificacion)

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
  "credito_cresa_cat_sexo_job.json"
  "credito_cresa_cat_estadocivil_job.json"
  "credito_cresa_cat_estadoverificacion_job.json"
  "credito_cresa_cat_nivelinstruccion_job.json"
  "credito_cresa_cat_provincia_job.json"
  "credito_cresa_cat_canton_job.json"
  "credito_cresa_cat_parroquia_job.json"
  "credito_cresa_cat_profesion_job.json"
  "credito_cresa_cat_solicitud_estados_job.json"
  "credito_cresa_cat_almacen_job.json"
  "credito_cresa_cat_modelo_aprobador_job.json"
  "credito_cresa_cat_origen_job.json"
  "credito_cresa_cat_modelo_calificacion_job.json"
  "credito_cresa_cat_tipovinculo_job.json"
  "credito_cresa_cat_tipoverificacion_job.json"
  "credito_cresa_cat_sector_job.json"
  "credito_cresa_cat_sector_riesgo_geocerca_job.json"
  "credito_cresa_cobro_tipo_credito_tb.json"
  "credito_cresa_com_cub_cobros_cuotas_cresa_tb.json"
  "credito_cresa_cre_solicitante.json"
  "credito_cresa_cre_solicitante_mina.json"
  "credito_cresa_cre_solicitud.json"
  "credito_cresa_cre_solicitud_bitacora.json"
  "credito_cresa_cre_solicituddomicilio.json"
  "credito_cresa_cre_solicitudlaboral.json"
  "credito_cresa_cub_cobro_cuotas.json"
  "credito_cresa_lcr_cuentas.json"
  "credito_cresa_lcr_reserva_cuotas.json"
  "credito_cresa_lcr_graduacion.json"
  "credito_cresa_sec_usuario.json"
  "credito_cresa_sis_peticiones.json"
  "credito_cresa_ver_respuesta_proveedor.json"

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

execute_sql_queries() {
  log "Ejecutando SQL de referencia para: cat_estadoverificacion..."
  
  cat << 'EOF'

-- ========================================
-- SQL DE REFERENCIA: cat_estadoverificacion
-- ========================================

-- 1. Conteo total
SELECT 
  COUNT(*) AS total_registros,
  COUNT(DISTINCT id) AS ids_unicos,
  COUNT(DISTINCT nombre) AS nombres_unicos
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion;

-- 2. Duplicados (PRIMARY KEY)
SELECT id, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion
GROUP BY id
HAVING COUNT(*) > 1;

-- 3. Distribución de activo
SELECT DISTINCT es_activo, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion
GROUP BY es_activo;

-- 4. Distribución de tipo_verificacion
SELECT tipo_verificacion, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion
GROUP BY tipo_verificacion
ORDER BY cnt DESC;

-- 5. Nulos en críticos
SELECT 
  COUNTIF(id IS NULL) AS nulls_id,
  COUNTIF(nombre IS NULL) AS nulls_nombre,
  COUNTIF(tipo_verificacion IS NULL) AS nulls_tipo_verificacion
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion;

-- 6. Distribución resolutivo
SELECT DISTINCT resolutivo, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion
GROUP BY resolutivo;

-- 7. Últimas ejecuciones
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
WHERE config_path LIKE '%cat_estadoverificacion%'
ORDER BY started_at DESC;

-- 8. Conteo de registros por tabla: cat_sector
SELECT COUNT(*) AS total_registros,
       COUNT(DISTINCT id) AS ids_unicos
FROM dlh_cresa.bronze.credito_cresa_cat_sector;

-- 9. Validación de sectores activos
SELECT es_activo, COUNT(*) AS cantidad
FROM dlh_cresa.bronze.credito_cresa_cat_sector
GROUP BY es_activo;

-- 10. Validación de fechas
SELECT COUNTIF(creado IS NULL) AS nulos_creado,
       COUNTIF(actualizado < creado) AS fechas_inconsistentes,
       COUNTIF(actualizado > CURRENT_TIMESTAMP()) AS fechas_futuras
FROM dlh_cresa.bronze.credito_cresa_cat_sector;

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
  execute_sql_queries
  
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
