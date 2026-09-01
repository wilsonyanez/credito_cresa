#!/usr/bin/env bash
set -euo pipefail

# Crea o actualiza (reset) todos los jobs JSON en templates_ingenieria/config/jobs
# Uso:
#   export DATABRICKS_HOST='https://adb-...'
#   export DATABRICKS_TOKEN='dapi...'
#   bash create_all_jobs_curl.sh [--submit]

SCRIPTDIR=$(cd "$(dirname "$0")" && pwd)
JOBS_DIR="$SCRIPTDIR/../config/jobs"
LOG_DIR="$SCRIPTDIR/../logs"
mkdir -p "$LOG_DIR"

if [[ -z "${DATABRICKS_HOST:-}" || -z "${DATABRICKS_TOKEN:-}" ]]; then
  echo "Exporta DATABRICKS_HOST y DATABRICKS_TOKEN antes de ejecutar" >&2
  exit 2
fi

SUBMIT_RUNS=false
if [[ ${1:-} == "--submit" || ${1:-} == "-s" ]]; then
  SUBMIT_RUNS=true
fi

HOST="$DATABRICKS_HOST"
TOKEN="$DATABRICKS_TOKEN"

# SMTP configuration (optional) - if set, send alert emails on failed runs
SMTP_HOST="${SMTP_HOST:-}"
SMTP_PORT="${SMTP_PORT:-25}"
SMTP_USER="${SMTP_USER:-}"
SMTP_PASS="${SMTP_PASSWORD:-}"
ALERT_RECIPIENTS="${ALERT_RECIPIENTS:-}"
ALERT_FROM="${ALERT_FROM:-alerts@localhost}"

timestamp(){ date +%Y%m%d_%H%M%S; }
jobs_list_file="$LOG_DIR/jobs_list_$(timestamp).json"

echo "Obteniendo lista de jobs desde $HOST..."
curl -s -X GET "$HOST/api/2.0/jobs/list" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" > "$jobs_list_file"

for jobfile in "$JOBS_DIR"/*_job.json; do
  [[ -f "$jobfile" ]] || continue
  name=$(jq -r '.name // empty' "$jobfile")
  if [[ -z "$name" ]]; then
    echo "Skipping $jobfile (no 'name' field)";
    continue
  fi
  echo "Processing job JSON: $jobfile (name='$name')"

  # buscar job existente por nombre
  job_id=$(jq -r --arg nm "$name" '.jobs[] | select((.settings.name // .settings.task.name) == $nm) | .job_id' "$jobs_list_file" | head -n1 || true)

  if [[ -n "$job_id" ]]; then
    echo "Job exists (job_id=$job_id) -> calling reset"
    bodyfile="$LOG_DIR/reset_body_$(basename $jobfile)_$(timestamp).json"
    # construir body: { "job_id": <id>, "new_settings": <content of jobfile> }
    printf '{"job_id": %s, "new_settings": %s}' "$job_id" "$(cat "$jobfile")" > "$bodyfile"
    resp=$(curl -s -X POST "$HOST/api/2.0/jobs/reset" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data-binary "@$bodyfile")
    echo "$resp" > "$LOG_DIR/reset_resp_$(basename $jobfile)_$(timestamp).json"
    echo "Reset response saved"
  else
    echo "Job does not exist -> creating"
    resp=$(curl -s -X POST "$HOST/api/2.0/jobs/create" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data-binary "@$jobfile")
    echo "$resp" > "$LOG_DIR/create_resp_$(basename $jobfile)_$(timestamp).json"
    job_id=$(echo "$resp" | jq -r '.job_id // empty' || true)
    echo "Create response saved"
  fi

  if $SUBMIT_RUNS && [[ -n "$job_id" ]]; then
    echo "Submitting run for job_id=$job_id"
    subresp=$(curl -s -X POST "$HOST/api/2.1/jobs/runs/submit" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "{\"job_id\": $job_id}")
    echo "$subresp" > "$LOG_DIR/submit_resp_${job_id}_$(timestamp).json"
    run_id=$(echo "$subresp" | jq -r '.run_id // empty' || true)
    if [[ -z "$run_id" ]]; then
      echo "No run_id returned for job_id=$job_id; see $LOG_DIR/submit_resp_${job_id}_*.json"
      continue
    fi
    echo "Run submitted run_id=$run_id — polling status..."
    start=$(date +%s)
    while true; do
      sleep 5
      status=$(curl -s -X GET "$HOST/api/2.0/jobs/runs/get?run_id=$run_id" -H "Authorization: Bearer $TOKEN")
      echo "$status" > "$LOG_DIR/run_status_${run_id}_$(timestamp).json"
      life=$(echo "$status" | jq -r '.state.life_cycle_state // empty')
      result=$(echo "$status" | jq -r '.state.result_state // empty')
      echo "  run state: $life / result: $result"
      if [[ "$life" == "TERMINATED" || "$life" == "INTERNAL_ERROR" || "$life" == "SKIPPED" ]]; then
        echo "Run finished: $result"
        # Enviar alerta si falla
        if [[ "$result" != "SUCCESS" && -n "${ALERT_RECIPIENTS}" ]]; then
          subj="[ALERTA] Job $name run_id=$run_id result=$result"
          body="Job: $name\nRun: $run_id\nResult: $result\nRevisa logs en $LOG_DIR"
          # Intentar enviar correo con sendmail/nc si disponible (no exponer credenciales)
          if command -v sendmail >/dev/null 2>&1; then
            printf 'To: %s\nFrom: %s\nSubject: %s\n\n%s\n' "$ALERT_RECIPIENTS" "$ALERT_FROM" "$subj" "$body" | sendmail -t
          elif command -v mailx >/dev/null 2>&1; then
            printf '%s' "$body" | mailx -s "$subj" -r "$ALERT_FROM" $ALERT_RECIPIENTS
          else
            echo "No se encontró sendmail/mailx; para usar SMTP configure y use la versión PowerShell" >&2
          fi
        fi
        break
      fi
      if (( $(date +%s) - start > 900 )); then
        echo "Run polling timeout (15m) for run_id=$run_id"; break
      fi
    done
  fi
done

echo "All jobs processed; logs in $LOG_DIR"
