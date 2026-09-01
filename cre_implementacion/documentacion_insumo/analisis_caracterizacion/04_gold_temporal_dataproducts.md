# Gold — Productos de Datos Temporales por Caso de Uso (CRESA)

## 1. Quick win — campos habilitadores de Salesforce (mayor impacto, menor esfuerzo)

**Producto**: `dlh_cresa.gold.dw_cresa_cliente_campos_salesforce` (vista/tabla derivada, estado `temporal`)

Deriva sobre datos que **ya existen** en Gold — no requiere integración nueva:

| Campo | Fórmula / fuente | Bloqueador real |
|---|---|---|
| `cupo_disponible` | Agregación sobre `dw_cresa_cartera_saldos_fact` (monto − saldo), reconciliado contra `CreditLimit` de Dynamics | Falta fórmula validada por Crédito (Mauricio Ponce) — ver `06_hipotesis_validacion.md` #3 |
| `flag_contactable` | Derivado de `dias_atraso`/`rango_mora` según la "escalera de mora" | Falta definir la escalera (decisión de negocio, no desarrollo) |
| `optin_email` / `optin_whatsapp` / `optin_llamadas` | — | No existe ninguna fuente; requiere activar captura, no solo transformación |
| `num_cuota_actual` / `num_cuota_total` | `dw_cresa_cartera_saldos_fact` (columnas directas) | Insumo ya existe — solo requiere el pipeline de agregación |

**Por qué es prioridad 1**: desbloquea directamente CU-03 a CU-06 y es condición para el switch de Salesforce Data Cloud del **1 de octubre de 2026**. Fecha intermedia comprometida: campos disponibles en Gold entre el 25 de agosto y el 12 de septiembre de 2026.

## 2. Maestro Cliente

**Producto**: `dlh_cresa.gold.dw_cresa_maestro_cliente` — estado inicial `temporal`

- Fuente: `dlh_cresa.silver.dw_cresa_cliente_conformado` (ver `03_silver_cleansing_riesgos.md`).
- Contrato: una fila por `num_identificacion`, llave conformada entre SIAC/Dynamics/(futuro Vtex-Venta Smart).
- Reglas de certificación (Arquitectura To-Be, TDF cap. 3.7): completitud ≥ umbral, unicidad verificada, vigencia, linaje trazable, clasificación de sensibilidad aplicada, owner/reglas aprobados.
- Metadata de gobierno a incorporar: `_certification_status`, `_data_owner`, `_last_certified_at`, `_sensitivity_classification` (particularmente relevante porque mezcla campos sensibles como `cupo_disponible`/`dias_atraso` con campos públicos como `nombre_completo`).
- Consumidores esperados: Power BI, Salesforce Data Cloud (Zero Copy), RELEX (indirecto vía segmentación).

## 3. Maestro Producto

**Producto**: `dlh_cresa.gold.dw_cresa_maestro_producto` — estado inicial `temporal`

- Fuente: `dlh_cresa.silver.dw_cresa_producto_conformado`.
- Contrato: una fila por `cod_producto` (SKU), con `es_vehiculo` explícito y dimensiones normalizadas a unidad métrica estándar.
- Debe convertirse en la **fuente única** que alimente tanto `rlx_products`/`rlx_products_ms` (RELEX) como `sf_producto_test` (Salesforce), reemplazando las dos exportaciones desalineadas actuales.
- Fecha dura: catálogo de Producto listo para RELEX el **22 de septiembre de 2026**.

## 4. Estados de certificación (a introducir — hoy no existen en ninguna tabla Gold de CRESA)

| Estado | Significado |
|---|---|
| `temporal` | Producto usado para validación funcional o técnica |
| `validado` | Revisado por Business Data Steward, aún no certificado corporativamente |
| `certificado` | Aprobado por el Data Owner del dominio para consumo corporativo |
| `restringido` | Acceso limitado por sensibilidad (aplica directo a `cupo_disponible`, `dias_atraso`) |
| `deprecated` | Reemplazado o no vigente — aplicaría hoy mismo a las 5 versiones de backup de `dw_cresa_producto_dim` |

## 5. Canales de consumo declarados

| Canal | Uso esperado en CRESA |
|---|---|
| Salesforce Data Cloud | Zero Copy desde Gold — switch 1 oct 2026 |
| RELEX | JDBC directo desde el maestro de Producto — reemplaza 32 interfaces CSV |
| Power BI | Vistas `vista_pbi_*` ya existentes, migrar a leer del maestro certificado |
| Visión 360 / Data360 | Consolida Databricks + CrediCresa (MuleSoft) + Vtex (MuleSoft) → Salesforce Data Cloud |

## 6. Riesgo de no mover esto a Gold formal

Sin estado de certificación explícito, cualquier consumidor (Salesforce, RELEX, un analista de Power BI) tiene que "preguntarle a una persona" cuál tabla es la vigente — exactamente el patrón que hoy produce 5 versiones de backup de `dw_cresa_producto_dim` conviviendo en el catálogo productivo sin marca de cuál es la correcta.
