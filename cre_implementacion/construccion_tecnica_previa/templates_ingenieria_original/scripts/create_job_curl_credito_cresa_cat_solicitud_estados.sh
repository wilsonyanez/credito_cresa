#!/usr/bin/env bash
# Script para crear el job ingest_credito_cresa_cat_solicitud_estados en Databricks
# Rellenar DATABRICKS_HOST y DATABRICKS_TOKEN en variables de entorno antes de ejecutar

set -euo pipefail

if [[ -z "${DATABRICKS_HOST:-}" || -z "${DATABRICKS_TOKEN:-}" ]]; then
  echo "Exporta DATABRICKS_HOST y DATABRICKS_TOKEN antes de ejecutar" >&2
  exit 2
fi

JOB_JSON="templates_ingenieria/config/jobs/credito_cresa_cat_solicitud_estados_job.json"

curl -s -X POST "$DATABRICKS_HOST/api/2.0/jobs/create" \
  -H "Authorization: Bearer $DATABRICKS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary @$JOB_JSON | jq .

echo "Comando ejecutado. Revisa la salida para job_id o errores."
