#!/bin/bash

# Script: create_job_credito_cresa_cat_tipoverificacion.sh
# Propósito: Crear job único en Databricks usando API REST para ingesta de cat_tipoverificacion
# Autor: Equipo de Datos - Maestro
# Fecha: 2026-08-27
# Versión: 1.0

set -e  # Salir ante primer error

# ============================================
# CONFIGURACIÓN
# ============================================

DATABRICKS_HOST="https://adbdlh01.cloud.databricks.com"  # Reemplazar con URL real
DATABRICKS_TOKEN="${DATABRICKS_TOKEN}"                   # Usar variable de entorno
JOB_CONFIG_PATH="./credito_cresa_cat_tipoverificacion_job.json"
LOG_FILE="job_creation_$(date +%Y%m%d_%H%M%S).log"
TIMEOUT=30

# ============================================
# FUNCIONES
# ============================================

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
  log "ERROR: $1"
  exit 1
}

validate_prerequisites() {
  log "Validando pre-requisitos..."
  
  [[ -z "$DATABRICKS_TOKEN" ]] && error_exit "DATABRICKS_TOKEN no está configurado. Usar: export DATABRICKS_TOKEN=<token>"
  [[ ! -f "$JOB_CONFIG_PATH" ]] && error_exit "Archivo de configuración no encontrado: $JOB_CONFIG_PATH"
  
  command -v curl >/dev/null || error_exit "curl no está instalado"
  command -v jq >/dev/null || error_exit "jq no está instalado (para parsear JSON)"
  
  log "✓ Pre-requisitos validados"
}

create_job() {
  log "Leyendo configuración del job..."
  JOB_JSON=$(cat "$JOB_CONFIG_PATH")
  
  log "Enviando solicitud de creación de job a Databricks..."
  
  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    "$DATABRICKS_HOST/api/2.1/jobs/create" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JOB_JSON" \
    --connect-timeout "$TIMEOUT" \
    --max-time "$((TIMEOUT * 3))")
  
  HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
  RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [[ $HTTP_CODE -ne 200 ]]; then
    log "ERROR: Fallo en creación de job (HTTP $HTTP_CODE)"
    log "Respuesta: $RESPONSE_BODY"
    error_exit "Job no pudo ser creado"
  fi
  
  JOB_ID=$(echo "$RESPONSE_BODY" | jq -r '.job_id')
  log "✓ Job creado exitosamente"
  log "  Job ID: $JOB_ID"
  log "  Nombre: $(echo "$JOB_JSON" | jq -r '.name')"
}

enable_job() {
  log "Habilitando job..."
  
  curl -s -X POST \
    "$DATABRICKS_HOST/api/2.1/jobs/update" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"job_id\": $JOB_ID}" \
    > /dev/null
  
  log "✓ Job habilitado"
}

verify_job() {
  log "Verificando creación del job..."
  
  VERIFY_RESPONSE=$(curl -s \
    -X GET \
    "$DATABRICKS_HOST/api/2.1/jobs/get?job_id=$JOB_ID" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN")
  
  JOB_NAME=$(echo "$VERIFY_RESPONSE" | jq -r '.settings.name')
  JOB_SCHEDULE=$(echo "$VERIFY_RESPONSE" | jq -r '.settings.schedule.quartz_cron_expression')
  
  log "✓ Verificación exitosa"
  log "  Job ID: $JOB_ID"
  log "  Nombre: $JOB_NAME"
  log "  Schedule: $JOB_SCHEDULE"
}

send_alert_email() {
  log "Notificando al equipo..."
  
  SUBJECT="✓ Job creado: credito_cresa_cat_tipoverificacion"
  MESSAGE="El job para ingesta de cat_tipoverificacion ha sido creado exitosamente.

Job ID: $JOB_ID
Nombre: ingest_credito_cresa_cat_tipoverificacion
Schedule: Diariamente a las 3:00 AM (America/Bogota)
Configuración: $JOB_CONFIG_PATH

Próximos pasos:
1. Verificar en Databricks: Workflows → Jobs → $JOB_ID
2. Ejecutar test manual: Jobs → Run Now → run_mode=test
3. Monitorear alertas en email: data-platform-team@empresa.local

Documentación: templates_ingenieria/docs/INGEST_credito_cresa_cat_tipoverificacion_run.md"
  
  # Simulación: en producción, usar herramienta de notificación
  log "$MESSAGE"
}

# ============================================
# EJECUCIÓN PRINCIPAL
# ============================================

main() {
  log "=========================================="
  log "Iniciando creación de job"
  log "=========================================="
  
  validate_prerequisites
  create_job
  enable_job
  verify_job
  send_alert_email
  
  log ""
  log "=========================================="
  log "✓ PROCESO COMPLETADO EXITOSAMENTE"
  log "=========================================="
  log "Logs guardados en: $LOG_FILE"
}

main "$@"
