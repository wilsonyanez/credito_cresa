-- Ejecutar con una identidad autorizada para crear catálogo/esquemas/volúmenes.
-- Cambiar cresa_dev si el administrador asignó otro catálogo de desarrollo.

CREATE CATALOG IF NOT EXISTS cresa_dev
COMMENT 'Catálogo aislado para pruebas de ingesta CRESA';

CREATE SCHEMA IF NOT EXISTS cresa_dev.landing
COMMENT 'Archivos semilla y salidas Parquet de prueba';

CREATE SCHEMA IF NOT EXISTS cresa_dev.credito_cresa_source
COMMENT 'Base de datos fuente recreada internamente para pruebas';

CREATE SCHEMA IF NOT EXISTS cresa_dev.bronze
COMMENT 'Tablas Parquet de prueba construidas desde los YAML de ingesta';

CREATE SCHEMA IF NOT EXISTS cresa_dev.silver
COMMENT 'Reservado para futuras pruebas Silver';

CREATE SCHEMA IF NOT EXISTS cresa_dev.gold
COMMENT 'Reservado para futuras pruebas Gold';

CREATE VOLUME IF NOT EXISTS cresa_dev.landing.source_seed
COMMENT 'Datos semilla opcionales para inferir tipos al recrear las tablas fuente';

CREATE VOLUME IF NOT EXISTS cresa_dev.bronze.data
COMMENT 'Salida Parquet de las ingestas Bronze metadata-driven';

-- Comprobación no destructiva.
SHOW SCHEMAS IN cresa_dev;
SHOW VOLUMES IN cresa_dev.landing;
SHOW VOLUMES IN cresa_dev.bronze;
