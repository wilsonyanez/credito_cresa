-- Control plane de ingestas CRESA.
-- Para producción, cambiar cresa por el catálogo autorizado (por ejemplo,
-- dlh_cresa) después de revisar compatibilidad con las tablas audit01 existentes.

CREATE SCHEMA IF NOT EXISTS cresa.audit01
COMMENT 'Control plane transaccional de pipelines de datos';

CREATE TABLE IF NOT EXISTS cresa.audit01.credicresa_ingestion_runs (
  run_id                 STRING NOT NULL,
  source_name            STRING NOT NULL,
  status                 STRING NOT NULL,
  started_at             TIMESTAMP NOT NULL,
  finished_at            TIMESTAMP,
  table_total            INT,
  table_succeeded        INT,
  table_failed           INT,
  total_rows             BIGINT,
  dry_run                BOOLEAN NOT NULL,
  table_filter           STRING,
  source_config          STRING,
  output_base_path       STRING,
  error_message          STRING,
  created_by             STRING,
  updated_at             TIMESTAMP NOT NULL,
  CONSTRAINT credicresa_ingestion_runs_pk PRIMARY KEY (run_id) NOT ENFORCED
)
USING DELTA
COMMENT 'Una fila por ejecución del pipeline de una fuente'
TBLPROPERTIES (
  'delta.enableChangeDataFeed' = 'true',
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true'
);

CREATE TABLE IF NOT EXISTS cresa.audit01.credicresa_ingestion_table_runs (
  run_id                 STRING NOT NULL,
  source_name            STRING NOT NULL,
  config_path            STRING,
  source_table           STRING,
  target_table           STRING,
  status                 STRING NOT NULL,
  row_count              BIGINT,
  column_count           INT,
  started_at             TIMESTAMP,
  finished_at            TIMESTAMP NOT NULL,
  detail                 STRING,
  output_path            STRING
)
USING DELTA
PARTITIONED BY (source_name)
COMMENT 'Resultado y métricas de cada tabla procesada dentro de una ejecución'
TBLPROPERTIES (
  'delta.enableChangeDataFeed' = 'true',
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true'
);

CREATE TABLE IF NOT EXISTS cresa.audit01.credicresa_ingestion_columns (
  run_id                 STRING NOT NULL,
  source_name            STRING NOT NULL,
  source_schema          STRING NOT NULL,
  source_table           STRING NOT NULL,
  target_table           STRING NOT NULL,
  ordinal                INT NOT NULL,
  column_name            STRING NOT NULL,
  spark_data_type        STRING NOT NULL,
  nullable               BOOLEAN NOT NULL,
  present_in_yaml        BOOLEAN NOT NULL,
  characterized_at       TIMESTAMP NOT NULL
)
USING DELTA
PARTITIONED BY (source_name)
COMMENT 'Diccionario técnico observado en las tablas fuente durante cada ejecución'
TBLPROPERTIES (
  'delta.enableChangeDataFeed' = 'true',
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true'
);

CREATE TABLE IF NOT EXISTS cresa.audit01.credicresa_ingestion_watermarks (
  source_name            STRING NOT NULL,
  source_table           STRING NOT NULL,
  watermark_column       STRING,
  watermark_value        STRING,
  last_successful_run_id STRING,
  last_successful_at     TIMESTAMP,
  updated_at             TIMESTAMP NOT NULL,
  CONSTRAINT credicresa_ingestion_watermarks_pk
    PRIMARY KEY (source_name, source_table) NOT ENFORCED
)
USING DELTA
COMMENT 'Último punto de lectura exitoso, reservado para futuras cargas incrementales';

-- Vista operativa: última ejecución por fuente.
CREATE OR REPLACE VIEW cresa.audit01.credicresa_v_latest_ingestion_run AS
SELECT * EXCEPT (run_order)
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY source_name ORDER BY started_at DESC) AS run_order
  FROM cresa.audit01.credicresa_ingestion_runs
)
WHERE run_order = 1;

-- Vista operativa: errores recientes por tabla.
CREATE OR REPLACE VIEW cresa.audit01.credicresa_v_ingestion_errors AS
SELECT
  run_id, source_name, source_table, target_table,
  status, started_at, finished_at, detail
FROM cresa.audit01.credicresa_ingestion_table_runs
WHERE status IN ('ERROR', 'CONFIG_ERROR');

CREATE TABLE IF NOT EXISTS cresa.audit01.credicresa_medallion_runs (
  run_id STRING, period STRING, input_batch STRING, layer STRING, entity STRING,
  status STRING, row_count BIGINT, certification_status STRING, business_rules STRING,
  started_at TIMESTAMP, finished_at TIMESTAMP
) USING DELTA COMMENT 'CRESA credicresa pre_productiva';

-- Diagnosticos agregados: no contiene valores de personas ni filas rechazadas.
CREATE TABLE IF NOT EXISTS cresa.audit01.credicresa_quality_results (
  run_id STRING, period STRING, input_batch STRING, layer STRING, entity STRING,
  rule_id STRING, rule_type STRING, columns_json STRING, total_rows BIGINT,
  affected_rows BIGINT, status STRING, action STRING, key_authority STRING,
  certification_status STRING, evaluated_at TIMESTAMP
) USING DELTA COMMENT 'CRESA credicresa pre_productiva';
