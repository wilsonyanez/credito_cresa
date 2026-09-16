-- Cliente cresa: catalogo; proyecto credicresa: prefijo de objetos.
CREATE CATALOG IF NOT EXISTS cresa COMMENT 'Cliente CRESA';
-- CRESA: usar el catalogo de pruebas existente cresa.
CREATE SCHEMA IF NOT EXISTS cresa.audit01;
CREATE SCHEMA IF NOT EXISTS cresa.landing;
CREATE SCHEMA IF NOT EXISTS cresa.bronze;
CREATE SCHEMA IF NOT EXISTS cresa.silver;
CREATE SCHEMA IF NOT EXISTS cresa.gold;
CREATE VOLUME IF NOT EXISTS cresa.landing.credicresa_input;
CREATE VOLUME IF NOT EXISTS cresa.bronze.credicresa_data;

CREATE VOLUME IF NOT EXISTS cresa.silver.credicresa_data;
CREATE VOLUME IF NOT EXISTS cresa.gold.credicresa_data;
