> **Revisión de consistencia — 2026-09-16.** Consultar el [estado vigente](../../pre_productiva/docs/ESTADO_VIGENTE.md) para los nombres Silver/Gold de Producción y Desarrollo, los 1,2 TB disponibles declarados y la evidencia posterior de fuentes. El diagnóstico y las métricas originales conservan su fecha de corte; las propuestas anteriores se aplican solo donde no contradigan los documentos 17/20. Este material no acredita implementación de los maestros.

# Bronze Relevante — Selección y Justificación (CRESA)

> A diferencia de Almar (selección P1 de 114 tablas sobre 993 nunca antes cargadas), aquí Bronze ya existe (173 tablas). La "selección" es de **qué tablas Bronze ya existentes son la fuente de verdad a conformar** para los golden records de Cliente y Producto — no de qué cargar por primera vez.

## 1. Bronze relevante — Dominio Cliente

| Tabla Bronze/Staging | Fuente origen | Rol en el maestro | Prioridad |
|---|---|---|---|
| `bronze.customersv3` | Dynamics 365 F&O (OData) | Base de identidad + `CreditLimit` | P1 |
| `bronze.d365_customerv3` | Dynamics 365 F&O | Posible duplicado/versión de `customersv3` — **confirmar si son el mismo pipeline** | P1 (aclarar antes de conformar) |
| `bronze.cecustomers` | Dynamics 365 F&O | Datos comerciales de cliente | P2 |
| `gold.dw_cresa_persona_dim` | SIAC | Núcleo demográfico (768.727 filas) | P1 |
| `gold.dw_cresa_persona_siac_dim` | SIAC | Complementaria a persona_dim | P1 |
| `staging.temp_cotizaciones_siac` | SIAC | Cotizaciones — insumo de contactabilidad | P2 |
| `staging.solicitud_credicresa` | CrediCresa/Resuelve | Solicitudes de crédito | P1 |
| `gold.dw_cresa_estado_credito_dim` | CrediCresa/Resuelve | Estado de crédito | P1 |
| `gold.dw_cresa_rango_mora_dim` | CrediCresa/Resuelve | Rango de mora | P1 |
| `gold.dw_cresa_dias_atraso_dim` | CrediCresa/Resuelve | Días de atraso | P1 |
| `gold.dw_cresa_cartera_saldos_fact` | CrediCresa/Resuelve | Fact granular (191,7M filas, 262.563 clientes) — insumo directo de `cupo_disponible` | P1 |
| `gold.dw_cresa_dueno_cartera_dim` | CrediCresa/Resuelve | Dueño de cartera | P2 |
| `gold.dw_cresa_etapa_cobranza_dim` | Interno | Dimensión de etapa (sin hechos de gestión) | P2 |
| `silver.base_concrecion_cliente` | Canal/Origen interno | Estructura de canal/origen — **0 filas, activar captura** | P1 (activación, no conformación) |

## 2. Bronze relevante — Dominio Producto

| Tabla Bronze/Gold | Fuente origen | Rol en el maestro | Prioridad |
|---|---|---|---|
| `gold.dw_cresa_producto_dim` (+ 5 versiones de backup) | Dynamics 365 | Base del maestro — 189.465 filas, 83.127 SKU únicos | P1 (requiere resolver backups antes) |
| `bronze.d365_releasedproductsv2` | Dynamics 365 F&O | Producto liberado a venta | P1 |
| `bronze.d365_productattributevaluesv3` | Dynamics 365 F&O | Atributos EAV — especificaciones técnicas | P1 |
| `gold.dw_cresa_clase_producto_dim` | Dynamics 365 | Jerarquía comercial | P1 |
| `externo_cresa.rlx_products` / `rlx_products_ms` | Export a RELEX | Ya alimentando RELEX (modo test) — candidato a convertirse en consumidor del maestro certificado | P1 |
| `externo_cresa.sf_producto_test` | Export a Salesforce | Solo 4 columnas — desalineado con RELEX | P2 |

## 3. Candidatas secundarias / fuera de alcance P1

Ver `candidatas_secundarias.csv`. Incluye fuentes que **no están en el lake todavía** y no se resuelven con conformación de lo existente, sino con integración nueva: Vtex transaccional, Venta Smart, Genesys, opt-in por canal.

## 4. Decisión aplicada

El primer barrido de conformación no toca las 649 tablas — se concentra en las ~20 tablas Bronze/Gold que ya alimentan Cliente y Producto (listadas arriba). El resto del catálogo (staging 223, src 60, fivetran_log 10, audit01 4, ai_cresa 2) queda fuera de esta fase salvo lo que aporte trazabilidad de ingesta (`audit01`).
