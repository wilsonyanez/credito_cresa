# Índice de Entregables — Caracterización Fase 3 (CRESA)

Carpeta generada: `Fase 3/analisis_caracterizacion`. Estructura calcada de `Almar/Fase 3/analisis_caracterizacion`, con contenido propio de CRESA (dominios Cliente y Producto, catálogo `dlh_cresa` ya productivo).

## Lectura recomendada

1. `00_resumen_ejecutivo_caracterizacion.md`
2. `matriz_tablas_dominios_scoring.csv`
3. `bronze_relevante.csv`
4. `candidatas_secundarias.csv`
5. `01_mapa_maestros.md`
6. `07_diagramas_arquitectura_dominios.md`
7. `08_alineacion_dominios_as_is_fase3.md`
8. `09_plan_ingesta_almacenamiento_lakehouse.md`
9. `10_metodologia_lakehouse_gobierno_fase3.md`
10. `11_convenciones_nombramiento_databricks.md`
11. `02_bronze_relevante.md`
12. `03_silver_cleansing_riesgos.md`
13. `04_gold_temporal_dataproducts.md`
14. `05_sql_muestras_top_scoring.sql`
15. `06_hipotesis_validacion.md`

## Kit técnico para ingeniería

Carpeta generada: `Fase 3/templates_ingenieria`

| Archivo | Propósito |
|---|---|
| `config/sources/source_template.yml` | Plantilla de fuente SQL Server/API y secretos — reservada para cuando se incorpore Vtex/Venta Smart/Genesys. |
| `config/ingestion/ingestion_table_template.yml` | Plantilla de ingesta paramétrica Bronze — igual, reservada para fuentes nuevas. |
| `config/silver/silver_entity_template.yml` | Plantilla de cleansing, homologación y calidad diagnóstica Silver — usar para `dw_cresa_cliente_conformado` / `dw_cresa_producto_conformado`. |
| `config/gold/gold_product_template.yml` | Plantilla de contrato, certificación y publicación Gold — usar para los golden records y el quick win de Salesforce. |
| `config/environments/environment_template.yml` | Plantilla de parámetros por ambiente — hoy solo `prod` es real en CRESA (sin DEV/TEST separados). |
| `notebooks/template_pipeline_metadata_driven.ipynb` | Notebook base metadata-driven para Databricks, adaptado al catálogo `dlh_cresa`. |
| `docs/template_documentacion_pipeline.md` | Plantilla Markdown de documentación operativa por pipeline. |

## Gráficos incorporados

Los diagramas de Fase 3 se dejaron en formato Mermaid dentro de `07_diagramas_arquitectura_dominios.md` (renderizables directamente en Markdown/VS Code/GitHub), en vez de PNG estático — no se generaron imágenes rasterizadas en esta iteración. Si se necesitan como PNG para un documento Word/PowerPoint del cliente, exportar los bloques Mermaid con la herramienta de preferencia (mermaid-cli, draw.io, o el editor de artifacts) y guardarlos en `Fase 3/imagenes/`.

## Diferencia clave frente a Almar/Fase 3 (referencia)

Almar partió de una carga inicial (993 tablas nunca antes llevadas al lake) — el barrido fue de descubrimiento y priorización de ingesta. **CRESA ya tiene 649 tablas productivas en Databricks** — el barrido aquí es de conformación y certificación de los dominios Cliente y Producto, no de carga inicial. Por eso:

- No hay CSVs de "tablas muestreadas" ni consultas de descarga masiva (esa capa ya existe y está poblada).
- No se generaron plantillas `source_template`/`ingestion_table_template` pobladas con datos reales — se conservan como plantilla vacía para el backlog de fuentes no integradas (Vtex, Venta Smart, Genesys).
- El foco está en `silver_entity_template` y `gold_product_template`, que sí son el trabajo real de Fase 3.

## Decisión aplicada

El primer barrido de Fase 3 no toca las 649 tablas existentes. Usa `bronze_relevante.csv` como el subconjunto de tablas Bronze/Gold ya productivas que alimentan la conformación de Cliente y Producto, y `candidatas_secundarias.csv` como el backlog de fuentes que requieren integración nueva (no conformación).
