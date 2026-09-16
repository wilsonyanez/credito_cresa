> **Revisión de consistencia — 2026-09-16.** Consultar el [estado vigente](../../pre_productiva/docs/ESTADO_VIGENTE.md) para los nombres Silver/Gold de Producción y Desarrollo, los 1,2 TB disponibles declarados y la evidencia posterior de fuentes. El diagnóstico y las métricas originales conservan su fecha de corte; las propuestas anteriores se aplican solo donde no contradigan los documentos 17/20. Este material no acredita implementación de los maestros.

# Mapa de Maestros — Cliente y Producto (CRESA)

> Condensa `../../Implementación/BOSQUEJO_TABLAS_CURADAS.md` (inspección real de columnas vía `databricks unity-catalog tables get`) en el mismo formato de mapa de maestros usado en Almar Fase 3. No es una implementación — es el punto de partida para validar con los Data Owners una vez designados.

## Nombres vigentes por ambiente — 2026-09-16

| Ambiente | Dominio | Conformación Silver | Maestro Gold |
|---|---|---|---|
| Producción | Cliente | `dlh_cresa.silver.dw_cresa_cliente_conformado` | `dlh_cresa.gold.dw_cresa_maestro_cliente` |
| Producción | Producto | `dlh_cresa.silver.dw_cresa_producto_conformado` | `dlh_cresa.gold.dw_cresa_maestro_producto` |
| Desarrollo | Cliente | `dev_dlh_cresa.silver.dw_cresa_cliente_conformado` | `dev_dlh_cresa.gold.dw_cresa_maestro_cliente` |
| Desarrollo | Producto | `dev_dlh_cresa.silver.dw_cresa_producto_conformado` | `dev_dlh_cresa.gold.dw_cresa_maestro_producto` |

La definición de nombres no implica despliegue. El [informe extendido](../../pre_productiva/docs/20_CRESA_MDM_ANALISIS_EXTENDIDO.md) distingue existencia verificada, atributos pendientes e hipótesis. Las expresiones de ausencia y completitud del mapa original se interpretan al corte de ese diagnóstico, no como un inventario actual exhaustivo. La clasificación vehicular requiere catálogo de negocio; una longitud de 17 caracteres no valida por sí sola un VIN.

## 1. Maestro Cliente

**Nombre propuesto**: `dlh_cresa.gold.dw_cresa_maestro_cliente`
**Capa de conformación previa**: `dlh_cresa.silver.dw_cresa_cliente_conformado`

| Campo del golden record | Fuente(s) real(es) | Estado |
|---|---|---|
| `id_cliente` (llave conformada) | Cruce por `num_identificacion` entre `dw_cresa_persona_dim`, `bronze.customersv3.CustomerAccount`, `silver.base_concrecion_cliente` | 🟡 Las 3 fuentes tienen el campo; falta el cruce/dedup real |
| `num_identificacion` | `dw_cresa_persona_dim.num_identificacion` | 🟢 Existe |
| `nombre_completo`, `email`, `teléfono` | `dw_cresa_persona_dim` | 🟡 Existe, fragmentado en 3-4 columnas de teléfono sin regla de cuál prevalece |
| `dirección_estandarizada` | `dw_cresa_persona_dim.des_direccion_particular_*` | 🟡 Estructura existe; 20% con discrepancias conocidas (AS-IS) |
| `canal_origen`, `canal_preferido` | `silver.base_concrecion_cliente.origen/.canal` | 🔴 Estructura existe, **0 filas** al 2026-07-14 |
| `segmento_demográfico` | `dw_cresa_clasificacion_clientes_dim` | 🟢 Existe |
| `credit_limit_dynamics` | `bronze.customersv3.CreditLimit` (100% poblado) | 🟢 Existe — pendiente decidir si se reconcilia con cupo real de CrediCresa (ver `06_hipotesis_validacion.md` #3) |
| `estado_crédito`, `días_atraso`, `rango_mora` | `dw_cresa_estado_credito_dim`, `dw_cresa_dias_atraso_dim`, `dw_cresa_rango_mora_dim` | 🟢 Existe, requiere agregación desde `dw_cresa_cartera_saldos_fact` |
| `cupo_disponible` (derivado) | Fórmula sobre `dw_cresa_cartera_saldos_fact` — no confundir con `CreditLimit` | 🟡 Insumo existe, falta fórmula validada por Crédito |
| `flag_contactable` (derivado) | Depende de la "escalera de mora" (regla de negocio pendiente) | 🟡 Insumo existe, falta regla de negocio |
| `optin_email/whatsapp/llamadas` | — | 🔴 No existe ninguna fuente |
| `vtex_customer_id`, `venta_smart_cotizaciones` | — | 🔴 No existe ninguna fuente en el lake |
| `_certification_status`, `_data_owner`, `_sensitivity_classification` | — | 🔴 No existe en ninguna tabla Gold hoy |

**Regla de supervivencia (ya definida en Arquitectura To-Be 4.1bis)**: contacto = más reciente por timestamp, prioridad Dynamics > SIAC > Venta Smart; crédito = siempre CrediCresa; dirección = solo si está validada.

## 2. Maestro Producto

**Nombre propuesto**: `dlh_cresa.gold.dw_cresa_maestro_producto`
**Capa de conformación previa**: `dlh_cresa.silver.dw_cresa_producto_conformado`

| Campo del golden record | Fuente(s) real(es) | Estado |
|---|---|---|
| `cod_producto` (SKU único) | `dw_cresa_producto_dim.cod_producto` | 🟢 Existe |
| `des_producto`, `des_marca`, `des_categoria`, `des_grupo`, `des_subgrupo` | `dw_cresa_producto_dim` | 🟢 Existe, jerarquía comercial rica |
| `ancho`/`altura`/`longitud` + unidad normalizada | `dw_cresa_producto_dim.*` + `*_um` por dimensión | 🔴 92,4% sin ninguna dimensión física capturada — es problema de completitud, no de mezcla de unidades (ver `06_hipotesis_validacion.md`) |
| `num_motor`, `serie_chasis` | `dw_cresa_producto_dim` | 🟡 Existe, poblado, pero 55,6% con formato VIN real (17 car.) — el resto es el campo reutilizado en productos que no son vehículos |
| `es_vehiculo` (bandera nueva) | Derivar de longitud/formato de `serie_chasis` | 🔴 No existe — necesaria para no aplicar validación de VIN a productos no-vehículo |
| `especificaciones_técnicas` | `bronze.d365_productattributevaluesv3` (EAV) | 🟡 Existe, requiere pivotar de filas a columnas |
| `ean` | — | 🔴 No se encontró en ninguna capa — confirma gap de código unificador |
| `_certification_status`, `_data_owner` | — | 🔴 No existe |

**Regla de supervivencia**: dimensiones físicas siempre normalizadas a unidad métrica estándar corporativa, sin importar unidad de origen. Fuente única certificada debe alimentar tanto `rlx_products`/`rlx_products_ms` (RELEX) como `sf_producto_test` (Salesforce) — hoy son dos exportaciones desalineadas entre sí.

## 3. Correcciones a supuestos anteriores (con evidencia real de columnas)

| Supuesto previo | Evidencia real | Ajuste |
|---|---|---|
| "No existe indicador de canal/origen del cliente" | `silver.base_concrecion_cliente` tiene la estructura completa, pero 0 filas | La estructura existe, el dato no |
| "Chasis/serial de motos sin campo limpio" | `dw_cresa_producto_dim` ya tiene `num_motor`/`serie_chasis`, 0% nulos | El campo existe pero está sobrecargado sin regla de aplicación |
| "cupo_disponible no existe en ningún lado" | `CreditLimit` de Dynamics existe 100% poblado, pero es distinto del cupo real de CrediCresa | Hay dos nociones de "crédito" sin reconciliar |
| "Mezcla cm/pulgadas" | 0 filas en pulgadas encontradas; 92,4% simplemente vacío | Gap real es de completitud, no de normalización |

## 4. Nota de alcance

Este mapa no define tipos de dato finales, particionamiento ni mecanismo de actualización (full vs. incremental) — corresponde a diseño técnico detallado con el Data Engineer del dominio, una vez el Data Owner (pendiente de designación, ver `CONTEXTO_PROYECTO.md` §5) valide campos y reglas de supervivencia.
