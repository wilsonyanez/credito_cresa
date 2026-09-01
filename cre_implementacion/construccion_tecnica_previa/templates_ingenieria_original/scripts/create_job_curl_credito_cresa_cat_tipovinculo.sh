#!/usr/bin/env bash
set -euo pipefail

# Crea el job en Databricks usando el JSON provisto
if [ -z "${DATABRICKS_HOST:-}" ] || [ -z "${DATABRICKS_TOKEN:-}" ]; then
  echo "Setea DATABRICKS_HOST y DATABRICKS_TOKEN como variables de entorno antes de ejecutar"
  exit 1
fi

JOB_JSON_PATH="templates_ingenieria/config/jobs/credito_cresa_cat_tipovinculo_job.json"

curl -sS -X POST "${DATABRICKS_HOST%/}/api/2.0/jobs/create" \
  -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
  -H 'Content-Type: application/json' \
  --data-binary @"${JOB_JSON_PATH}" | jq .
