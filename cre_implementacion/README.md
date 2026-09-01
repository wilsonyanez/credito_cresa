# CRESA Fase 3 — Gobierno e ingesta de datos

Repositorio organizado para recrear y caracterizar las entidades de CRESA íntegramente dentro de Azure Databricks mediante un pipeline metadata-driven por fuente.

## Estructura vigente

```text
cre_implementacion/
├── documentacion_insumo/          # análisis y evidencia; no desplegable
├── construccion_tecnica_previa/   # archivo histórico; no ejecutar
└── pre_productiva/                # paquete único para pruebas y despliegue
```

## Empezar por aquí

1. Leer `pre_productiva/README.md`.
2. Configurar la fuente en `pre_productiva/config/sources/credito_cresa.yml`.
3. Revisar los 34 YAML en `pre_productiva/config/ingestion/`.
4. Ejecutar los SQL de `pre_productiva/sql/` en orden.
5. Desplegar el notebook y el job consolidado de `pre_productiva/`.

## Principios actuales

- Un pipeline por fuente, no un pipeline por YAML.
- Descubrimiento recursivo de entidades mediante metadatos.
- Base fuente de prueba recreada como tablas Parquet en Databricks.
- Tipos preservados/inferidos desde semillas; `STRING` explícito cuando no existen datos ni diccionario.
- Datos y caracterización en Parquet.
- Control plane transaccional en Delta.
- Primera ejecución secuencial para proteger la fuente.
- Credenciales únicamente en Secret Scope.

Los artefactos históricos se conservan, pero no forman parte del paquete desplegable.
