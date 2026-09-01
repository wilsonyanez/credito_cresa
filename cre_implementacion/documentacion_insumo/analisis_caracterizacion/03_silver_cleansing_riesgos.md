# Silver — Reglas de Conformación y Riesgos Esperados (CRESA)

## 1. Rol de Silver en CRESA hoy (diagnóstico)

Según `../../Implementación/FUENTES_Y_GAP_CAPAS_CLIENTE_PRODUCTO.md` §3.2: el esquema `silver` tiene solo 42 tablas (vs. 127 en Gold) — la proporción está invertida respecto al patrón esperado. La conformación real, hasta donde existe, **ocurre directamente en Gold** (los `dw_cresa_*_dim`/`*_fact` son ya un modelo dimensional relativamente maduro), saltándose el rol que Silver debería jugar. Esto es válido para un modelo Kimball orientado a BI, pero **no es compatible con el golden record gobernado** que la Arquitectura To-Be adoptó (conformación con reglas de survivorship explícitas, antes de llegar a Gold).

**Decisión de Fase 3**: introducir dos entidades Silver nuevas (`dw_cresa_cliente_conformado`, `dw_cresa_producto_conformado`) que sí cumplan el rol de conformación, sin migrar ni renombrar lo que ya existe en Gold.

## 2. Reglas de cleansing — Cliente

| Regla | Tipo | Columnas | Severidad | Acción |
|---|---|---|---|---|
| SV_CLI_001 | not_null | `num_identificacion` | crítica | flag_only |
| SV_CLI_002 | duplicate_natural_key | `num_identificacion` | alta | flag_only — **evidencia real: 1.351 duplicados (0,18%) en `dw_cresa_persona_dim`** |
| SV_CLI_003 | cross_source_reconciliation | `CreditLimit` (Dynamics) vs. cupo CrediCresa | crítica | flag_only hasta que Crédito confirme fuente de verdad (ver `06_hipotesis_validacion.md` #3) |
| SV_CLI_004 | valid_format | teléfono/email | media | flag_only — CU-02 no tiene proceso formal hoy |
| SV_CLI_005 | address_standardization | dirección particular | media | flag_only — 20% con discrepancias conocidas (AS-IS) |
| SV_CLI_006 | empty_source_alert | `base_concrecion_cliente` | alta | alertar si sigue en 0 filas — bloquea `canal_origen` |

## 3. Reglas de cleansing — Producto

| Regla | Tipo | Columnas | Severidad | Acción |
|---|---|---|---|---|
| SV_PRO_001 | duplicate_key_no_vigencia | `cod_producto` | crítica | flag_only — **2,28 filas por SKU en promedio, sin columna `valid_from`/`valid_to` que lo explique** |
| SV_PRO_002 | completeness_threshold | `ancho`/`altura`/`longitud` | alta | flag_only — 92,4% vacío; establecer meta de completitud explícita, no umbral de rechazo |
| SV_PRO_003 | conditional_format | `serie_chasis` (VIN 17 car.) | media | flag_only, condicionado a `es_vehiculo = true` — evita marcar como error el 44,4% que no es VIN por diseño (no es vehículo) |
| SV_PRO_004 | unit_normalization | `*_um` por dimensión | media | normalizar a unidad métrica estándar — transformación, no captura nueva |
| SV_PRO_005 | missing_unifier | `ean` | alta | flag_only — no existe en ninguna capa hoy, documentar como gap estructural |

## 4. Riesgos esperados al implementar

1. **Falsos duplicados en Cliente**: cruzar por `num_identificacion` puede fallar si el formato difiere entre SIAC (cédula/RUC) y Dynamics (`CustomerAccount`) — validar formato antes de asumir joinability 1:1.
2. **Pérdida de historicidad en Producto**: si se deduplica `dw_cresa_producto_dim` sin antes confirmar si las 2,28 filas/SKU son historización real (falta columna de vigencia) o error de carga, se puede perder información válida — **no descartar agresivamente, marcar y escalar**.
3. **`serie_chasis` sobrecargado**: aplicar la regla de validación VIN a productos no-vehículo generaría falsos negativos masivos — la bandera `es_vehiculo` debe existir *antes* de activar SV_PRO_003.
4. **Reconciliación de crédito politizada, no técnica**: SV_CLI_003 no se resuelve con una regla SQL — requiere decisión de negocio de Mauricio Ponce (Data Owner natural de Crédito). El pipeline debe poder correr con la regla en estado "pendiente de definición" sin bloquear el resto de la conformación.
5. **`base_concrecion_cliente` vacía**: si se conforma el maestro de Cliente sin activar esta fuente, `canal_origen` quedará nulo en el 100% de los casos — el riesgo no es técnico, es de captura ausente en origen.

## 5. Metadata de calidad recomendada (patrón Almar, sin renombrar esquemas existentes)

| Campo | Propósito |
|---|---|
| `_quality_status` | `ok` / `warning` / `failed` / `requires_review` |
| `_quality_flags` | Lista de reglas incumplidas |
| `_bronze_refs` | Referencia a las tablas Bronze/Gold origen usadas en el cruce |
| `_business_key` | Llave natural conformada (`num_identificacion` / `cod_producto`) |

Ninguna de estas columnas existe hoy en las tablas Gold de CRESA — es exactamente la ausencia que impide saber "cuál es la tabla buena" sin preguntarle a una persona (hallazgo confirmado: 5 versiones de backup de `dw_cresa_producto_dim` conviviendo sin marca de vigencia).
