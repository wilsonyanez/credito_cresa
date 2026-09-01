#!/usr/bin/env bash
# Ejecuta multiple statements SQL contra Databricks SQL API usando curl
# Requisitos: exportar DATABRICKS_HOST, DATABRICKS_TOKEN, DATABRICKS_SQL_WAREHOUSE_ID
# Opcional: pasar un archivo con sentencias SQL (una por línea) como primer argumento

set -euo pipefail

LOG_DIR="$(dirname "$0")/../logs"
mkdir -p "$LOG_DIR"

if [[ -z "${DATABRICKS_HOST:-}" || -z "${DATABRICKS_TOKEN:-}" || -z "${DATABRICKS_SQL_WAREHOUSE_ID:-}" ]]; then
  echo "Debe exportar DATABRICKS_HOST, DATABRICKS_TOKEN y DATABRICKS_SQL_WAREHOUSE_ID" >&2
  exit 2
fi

HOST="$DATABRICKS_HOST"
TOKEN="$DATABRICKS_TOKEN"
WAREHOUSE="$DATABRICKS_SQL_WAREHOUSE_ID"

timestamp() { date +%Y%m%d_%H%M%S; }

declare -a SQLS

# SQLs conocidas previas
SQLS+=("SELECT id,nombre FROM CREDITO_CRESA.dbo.cat_nacionalidad WITH (NOLOCK)")
SQLS+=("SELECT id,nombre FROM CREDITO_CRESA.dbo.cat_sexo WITH (NOLOCK)")
SQLS+=("SELECT id,nombre FROM CREDITO_CRESA.dbo.cat_estadocivil WITH (NOLOCK)")
SQLS+=("SELECT id,provincia_id,cod,pais_cod,provincia_cod,nombre,prefijo,cinec,es_activo FROM CREDITO_CRESA.dbo.cat_canton WITH (NOLOCK)")
SQLS+=("SELECT id,canton_id,cod,pais_cod,provincia_cod,canton_cod,nombre,cinec,es_activo FROM CREDITO_CRESA.dbo.cat_parroquia WITH (NOLOCK)")
SQLS+=("SELECT id,pais_id,cod,pais_cod,region_cod,nombre,cinec,es_activo FROM CREDITO_CRESA.dbo.cat_provincia WITH (NOLOCK)")
SQLS+=("SELECT id,nombre FROM CREDITO_CRESA.dbo.cat_nivelinstruccion WITH (NOLOCK)")
SQLS+=("SELECT id,creado,actualizado,creado_por,nombre,es_activo FROM CREDITO_CRESA.dbo.cat_solicitud_estados WITH (NOLOCK)")
SQLS+=("SELECT id,calificacion_buro_id,calificacion_confianza_id,calificacion_final_id,origen_id,zona_riesgo_id,tipo_cliente_id,dependencia_id,grupo_id,edad_min,edad_max,nacionalidad,capacidad_pago,tipo_verificacion,entrada_base,es_activo,fecha_creacion,actualizado,creado_por,actualizado_por,unidadnegocio_id,canal_id FROM CREDITO_CRESA.dbo.cat_modelo_aprobador WITH (NOLOCK)")
SQLS+=("SELECT id,fecha_creacion,actualizado,creado_por,actualizado_por,codigo_externo,nombre,es_activo FROM CREDITO_CRESA.dbo.cat_origen WITH (NOLOCK)")
SQLS+=("SELECT id,fecha_creacion,actualizado,creado_por,actualizado_por,confianza_desde,confianza_hasta,nombre,es_activo FROM CREDITO_CRESA.dbo.cat_modelo_calificacion WITH (NOLOCK)")
SQLS+=("SELECT id,nombre,es_activo FROM CREDITO_CRESA.dbo.cat_tipovinculo WITH (NOLOCK)")

# Si se pasa un archivo con SQLs (una por línea), agrégalos
if [[ ${1:-} != "" && -f "$1" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    SQLS+=("$line")
  done < "$1"
fi

echo "Ejecutando ${#SQLS[@]} sentencias contra $HOST (warehouse $WAREHOUSE)"

i=0
for sql in "${SQLS[@]}"; do
  i=$((i+1))
  echo "--- ($i) Ejecutando: ${sql:0:120}..."
  body=$(jq -nc --arg stmt "$sql" --arg wh "$WAREHOUSE" '{statement: $stmt, warehouse_id: $wh}')
  resp=$(curl -s -X POST "$HOST/api/2.0/sql/statements" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data-raw "$body")
  echo "$resp" > "$LOG_DIR/sql_submit_${i}_$(timestamp).json"
  stmt_id=$(echo "$resp" | jq -r '.statement_id // empty')
  if [[ -z "$stmt_id" ]]; then
    echo "No se recibió statement_id; respuesta guardada en log. Verifica permisos/warehouse." >&2
    continue
  fi

  echo "Statement_id: $stmt_id — polling..."
  start=$(date +%s)
  while true; do
    sleep 2
    status=$(curl -s -X GET "$HOST/api/2.0/sql/statements/$stmt_id" -H "Authorization: Bearer $TOKEN")
    state=$(echo "$status" | jq -r '.status.state // empty')
    echo "  estado: $state"
    if [[ "$state" == "SUCCEEDED" ]]; then
      result=$(curl -s -X GET "$HOST/api/2.0/sql/statements/$stmt_id/result" -H "Authorization: Bearer $TOKEN")
      outfile="$LOG_DIR/sql_result_${i}_$stmt_id_$(timestamp).json"
      echo "$result" > "$outfile"
      echo "  Resultado guardado en $outfile"
      break
    fi
    if [[ "$state" == "FAILED" ]]; then
      echo "  La ejecución falló. Consulta el endpoint /sql/statements/$stmt_id" >&2
      failfile="$LOG_DIR/sql_failed_${i}_$stmt_id_$(timestamp).json"
      echo "$status" > "$failfile"
      echo "  Estado guardado en $failfile"
      break
    fi
    # timeout 5 minutos
    now=$(date +%s)
    if (( now - start > 300 )); then
      echo "  Timeout polling statement_id=$stmt_id" >&2
      timeoutfile="$LOG_DIR/sql_timeout_${i}_$stmt_id_$(timestamp).json"
      echo "$status" > "$timeoutfile"
      echo "  Estado guardado en $timeoutfile"
      break
    fi
  done
done

echo "Proceso finalizado. Logs: $LOG_DIR"
