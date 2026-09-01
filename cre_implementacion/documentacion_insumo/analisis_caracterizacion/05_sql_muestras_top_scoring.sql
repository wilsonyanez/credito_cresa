-- SQL de referencia — perfilamiento de solo lectura contra dlh_cresa (workspace adbdlh01)
-- Reconstruye, para reproducibilidad, las consultas que sustentan las cifras del tamizaje
-- del 2026-07-14 (ver ANTES_DESPUES_GOBIERNO_DATOS.md y el PDF de diagnóstico técnico).
-- Ejecutar con cuenta de solo lectura (SELECT/USE_SCHEMA/USE_CATALOG). No modifica datos.

-- =========================================================
-- 1. DOMINIO CLIENTE — los tres universos sin reconciliar
-- =========================================================

-- 1.1 Universo SIAC (persona_dim)
SELECT COUNT(*) AS filas_persona_dim
FROM dlh_cresa.gold.dw_cresa_persona_dim;

-- 1.2 Duplicados por identificación en persona_dim
SELECT
  COUNT(*)                              AS filas_totales,
  COUNT(DISTINCT num_identificacion)    AS identificaciones_unicas,
  COUNT(*) - COUNT(DISTINCT num_identificacion) AS duplicados
FROM dlh_cresa.gold.dw_cresa_persona_dim;

-- 1.3 Universo Dynamics 365 (customersv3)
SELECT
  COUNT(*)                          AS filas_customersv3,
  COUNT(DISTINCT CustomerAccount)   AS clientes_unicos_dynamics
FROM dlh_cresa.bronze.customersv3;

-- 1.4 Completitud de CreditLimit en Dynamics
SELECT
  COUNT(*) AS total,
  SUM(CASE WHEN CreditLimit IS NOT NULL THEN 1 ELSE 0 END) AS con_credit_limit,
  ROUND(100.0 * SUM(CASE WHEN CreditLimit IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_poblado
FROM dlh_cresa.bronze.customersv3;

-- 1.5 Universo con historial de cartera activo (clientes únicos en el fact)
SELECT
  COUNT(*)                       AS filas_cartera,
  COUNT(DISTINCT id_cliente)     AS clientes_unicos_cartera,
  MIN(fecha)                     AS fecha_min,
  MAX(fecha)                     AS fecha_max
FROM dlh_cresa.gold.dw_cresa_cartera_saldos_fact;

-- 1.6 Completitud de identificación / email / teléfono (no es problema de nulos)
SELECT
  ROUND(100.0 * SUM(CASE WHEN num_identificacion IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_identificacion,
  ROUND(100.0 * SUM(CASE WHEN des_email IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1)            AS pct_email,
  ROUND(100.0 * SUM(CASE WHEN des_telefono2 IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1)         AS pct_telefono
FROM dlh_cresa.gold.dw_cresa_persona_dim;

-- 1.7 Tabla de canal/origen — validar si sigue vacía
SELECT COUNT(*) AS filas_base_concrecion_cliente
FROM dlh_cresa.silver.base_concrecion_cliente;

-- =========================================================
-- 2. DOMINIO PRODUCTO — duplicación y completitud de dimensiones físicas
-- =========================================================

-- 2.1 Filas vs. SKU únicos en el maestro de producto
SELECT
  COUNT(*)                        AS filas_producto_dim,
  COUNT(DISTINCT cod_producto)    AS skus_unicos,
  ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT cod_producto), 2) AS filas_por_sku
FROM dlh_cresa.gold.dw_cresa_producto_dim;

-- 2.2 Completitud de dimensiones físicas
SELECT
  COUNT(*) AS total,
  SUM(CASE WHEN ancho IS NULL AND altura IS NULL AND longitud IS NULL THEN 1 ELSE 0 END) AS sin_ninguna_dimension,
  ROUND(100.0 * SUM(CASE WHEN ancho IS NULL AND altura IS NULL AND longitud IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_sin_dimension
FROM dlh_cresa.gold.dw_cresa_producto_dim;

-- 2.3 Unidad de medida declarada (validar hipótesis "mezcla cm/pulgadas")
SELECT ancho_um, COUNT(*) AS filas
FROM dlh_cresa.gold.dw_cresa_producto_dim
GROUP BY ancho_um
ORDER BY filas DESC;

-- 2.4 Formato de serie_chasis (longitud de cadena — VIN real = 17 caracteres)
SELECT
  LENGTH(serie_chasis) AS longitud_chasis,
  COUNT(*)             AS filas,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM dlh_cresa.gold.dw_cresa_producto_dim
WHERE serie_chasis IS NOT NULL
GROUP BY LENGTH(serie_chasis)
ORDER BY filas DESC;

-- 2.5 Cobertura de atributos técnicos (EAV) sobre el universo de SKU
SELECT
  COUNT(DISTINCT productnumber) AS skus_con_atributos,
  (SELECT COUNT(DISTINCT cod_producto) FROM dlh_cresa.gold.dw_cresa_producto_dim) AS skus_totales
FROM dlh_cresa.bronze.d365_productattributevaluesv3;

-- 2.6 Completitud de unitofmeasure en el EAV (validar si ahí se captura la unidad)
SELECT
  COUNT(*) AS total,
  SUM(CASE WHEN unitofmeasure IS NULL OR unitofmeasure = '' THEN 1 ELSE 0 END) AS sin_unidad,
  ROUND(100.0 * SUM(CASE WHEN unitofmeasure IS NULL OR unitofmeasure = '' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_sin_unidad
FROM dlh_cresa.bronze.d365_productattributevaluesv3;

-- =========================================================
-- 3. PLATAFORMA — evidencia de deuda técnica (versiones sin control)
-- =========================================================

-- 3.1 Listar todas las variantes de dw_cresa_producto_dim en el catálogo (backups/test conviviendo)
SHOW TABLES IN dlh_cresa.gold LIKE 'dw_cresa_producto_dim*';

-- 3.2 Contar tablas con sufijo de no-producción en gold (_test/_bk/_backup/_bckup)
SELECT table_name
FROM dlh_cresa.information_schema.tables
WHERE table_schema = 'gold'
  AND (table_name LIKE '%_test' OR table_name LIKE '%_bk' OR table_name LIKE '%_backup' OR table_name LIKE '%_bckup');

-- 3.3 Permisos efectivos sobre el catálogo (correr desde CLI/Databricks, no SQL puro)
-- databricks unity-catalog catalogs get dlh_cresa
-- databricks grants get catalog dlh_cresa
