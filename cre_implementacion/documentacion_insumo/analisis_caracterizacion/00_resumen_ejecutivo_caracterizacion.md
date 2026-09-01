# Caracterización Fase 3 — Resumen Ejecutivo (CRESA)

> Generado a partir del diagnóstico técnico verificado contra producción (`adbdlh01`, catálogo `dlh_cresa`, corte 2026-07-14) y consolidado en `../../Implementación/CONTEXTO_PROYECTO.md`, `FUENTES_Y_GAP_CAPAS_CLIENTE_PRODUCTO.md`, `BOSQUEJO_TABLAS_CURADAS.md` y `MAPEO_CASOS_USO_FUENTES.md`. A diferencia de un barrido de metadatos en frío (caso Almar), aquí el punto de partida ya es un catálogo productivo con 649 tablas — el barrido fue de **estado de gobierno**, no de existencia de datos.

## Resultado del barrido

- Tablas totales en `dlh_cresa`: **649**, en 9 esquemas (staging 223, bronze 173, gold 127, src 60, silver 42, externo_cresa 8, fivetran_log 10, audit01 4, ai_cresa 2).
- Dominios en alcance de Fase 3 (Azurian): **Cliente** y **Producto**. Financiero/Crédito/Operaciones quedan bajo BusinessIT/Handytech (alcance exacto — 2 vs. 5 dominios de gobierno — es una decisión pendiente de escalar, ver `06_hipotesis_validacion.md` #4).
- El volumen de datos **no es la brecha**: hay modelo dimensional maduro en Gold. La brecha es de **gobierno y reconciliación** — no existe fuente certificada única para Cliente ni para Producto.

## Los 4 números que resumen el gap

| Hallazgo | Cifra | Fuente |
|---|---|---|
| Universos de cliente sin reconciliar | 768.727 (SIAC) / 651.367 (Dynamics) / 262.563 (cartera activa) | `dw_cresa_persona_dim`, `customersv3`, `dw_cresa_cartera_saldos_fact` |
| Duplicados por identificación en persona_dim | 1.351 (0,18%) | `dw_cresa_persona_dim` |
| Productos sin ninguna dimensión física capturada | 92,4% | `dw_cresa_producto_dim` |
| Filas por SKU en el maestro de Producto | 2,28× (189.465 filas / 83.127 SKU únicos) | `dw_cresa_producto_dim` |

## Bronze/Gold relevante por dominio

| Dominio | Fuentes ya mapeadas | Fuentes pendientes de integrar |
|---|---|---|
| Cliente | Dynamics 365, SIAC, CrediCresa/Resuelve, Canal/Origen (tabla vacía) | Vtex transaccional, Venta Smart, Genesys, opt-in por canal |
| Producto | Dynamics 365 (dim + EAV), RELEX (export activo), Salesforce (export en prueba) | EAN unificador, chasis/serial limpio, normalización de dimensiones físicas |

## Por qué importa ahora

El switch de tablas fuente de Salesforce Data Cloud está agendado para el **1 de octubre de 2026**. Los campos que necesita (`cupo_disponible`, `flag_contactable`, `optin_email/whatsapp/llamadas`, `num_cuota_actual/total`) no existen hoy como campo en ningún lado, pero **el insumo para derivarlos ya está en Gold** (`dw_cresa_cartera_saldos_fact`, 191,7M filas). Es el quick win de mayor impacto por menor esfuerzo de todo el roadmap — ver `04_gold_temporal_dataproducts.md` §1.

## Archivos generados en esta carpeta

- `01_mapa_maestros.md`: propuesta de golden records Cliente y Producto.
- `02_bronze_relevante.md`: selección de fuentes Bronze relevantes y su estado de integración.
- `03_silver_cleansing_riesgos.md`: reglas de conformación, survivorship y riesgos de calidad esperados.
- `04_gold_temporal_dataproducts.md`: productos de datos Gold propuestos (maestros + quick win de crédito).
- `05_sql_muestras_top_scoring.sql`: SQL de referencia usado para el tamizaje del 14 de julio (perfilamiento de solo lectura).
- `06_hipotesis_validacion.md`: hipótesis y decisiones a escalar, no resolubles desde el equipo técnico.
- `07_diagramas_arquitectura_dominios.md`: diagramas de arquitectura y flujo Bronze/Silver/Gold para Cliente/Producto.
- `08_alineacion_dominios_as_is_fase3.md`: alineación de Fase 3 con los dominios del AS-IS/To-Be y el reparto Azurian/Handytech.
- `09_plan_ingesta_almacenamiento_lakehouse.md`: convención de organización dentro del catálogo `dlh_cresa` ya existente.
- `10_metodologia_lakehouse_gobierno_fase3.md`: metodología metadata-driven adaptada a la plataforma ya desplegada.
- `11_convenciones_nombramiento_databricks.md`: convenciones de nombramiento hacia adelante, sin renombrar lo ya productivo.
- `matriz_tablas_dominios_scoring.csv`, `bronze_relevante.csv`, `candidatas_secundarias.csv`: inventario tabular de soporte.

## Diferencia metodológica importante frente a Almar (Fase 3, referencia)

Almar partió de una carga inicial de 993 tablas nunca antes llevadas al lake — el barrido fue de **descubrimiento y priorización de ingesta**. CRESA ya tiene Bronze/Silver/Gold pobladas — el barrido aquí es de **conformación y certificación**: identificar qué tablas ya existentes deben conformarse en un golden record y qué reglas de supervivencia aplicar, sin tocar la ingesta de las 649 tablas que ya funcionan.
