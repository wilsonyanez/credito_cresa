> **Revisión de consistencia — 2026-09-16.** Consultar el [estado vigente](../../pre_productiva/docs/ESTADO_VIGENTE.md) para los nombres Silver/Gold de Producción y Desarrollo, los 1,2 TB disponibles declarados y la evidencia posterior de fuentes. El diagnóstico y las métricas originales conservan su fecha de corte; las propuestas anteriores se aplican solo donde no contradigan los documentos 17/20. Este material no acredita implementación de los maestros.

# Convenciones de Nombramiento Databricks — Fase 3 (CRESA)

## Propósito

A diferencia de Almar (convenciones definidas desde cero sobre un catálogo nuevo), este documento fija reglas **hacia adelante** para las tablas nuevas de Fase 3, y documenta — sin corregirla retroactivamente — la inconsistencia ya existente en el catálogo productivo `dlh_cresa`. Renombrar las 649 tablas existentes no es un objetivo de Fase 3 (principio de mínima disrupción, Arquitectura To-Be).

## Inconsistencia ya confirmada (documentar, no corregir de inmediato)

| Patrón encontrado | Ejemplo | Fuente | Problema |
|---|---|---|---|
| Prefijo de fuente | `d365_customerv3`, `d365_releasedproductsv2` | Dynamics 365 | Consistente |
| Sin prefijo, mismo origen aparente | `customersv3`, `cecustomers` | Dynamics 365 (¿mismo pipeline que `d365_*`?) | **No está claro si son duplicados, versiones migradas, o dos pipelines paralelos** — resolver antes de decidir cuál es la fuente Bronze del maestro de Cliente |
| Prefijo `dw_cresa_` para Gold dimensional | `dw_cresa_persona_dim`, `dw_cresa_producto_dim` | Interno (ETL corporativo) | Consistente y maduro — se adopta como base para nombres nuevos |
| Sufijos de no-producción en catálogo productivo | `_test`, `_bk`, `_backup`, `_bckup` (>15 solo en `gold`) | Ad-hoc | Diagnóstico histórico de coexistencia en Producción; Desarrollo está identificado ahora como dev_dlh_cresa — 5 versiones de `dw_cresa_producto_dim` sin marca de vigente |

## Regla general para tablas nuevas de Fase 3

- Minúsculas, `snake_case`, sin tildes ni caracteres especiales.
- Mantener el prefijo `dw_cresa_` ya validado y reconocido por el equipo de CRESA — no introducir un prefijo nuevo (`almar_*` no aplica aquí).
- El dominio va en el nombre de la tabla, no en el esquema (el esquema ya está fijado por capa: `bronze`, `silver`, `gold`).
- Nada de sufijos `_test`/`_bk`/`_backup` en objetos que se consideren productivos de Fase 3 — usar `_certification_status = temporal` en su lugar, dentro de la misma tabla.

## Nomenclatura por capa

### Bronze (sin cambios — se documenta el estado, no se renombra)

```text
dlh_cresa.bronze.<nombre_ya_existente>
```

Antes de conformar, confirmar con Miguel Espinosa cuál de estas parejas es la fuente vigente:

```text
dlh_cresa.bronze.customersv3       vs.  dlh_cresa.bronze.d365_customerv3
```

### Silver (nuevo, Fase 3)

```text
dlh_cresa.silver.dw_cresa_<dominio>_conformado
```

Ejemplos:

```text
dlh_cresa.silver.dw_cresa_cliente_conformado
dlh_cresa.silver.dw_cresa_producto_conformado
```

### Gold — maestros (nuevo, Fase 3)

```text
dlh_cresa.gold.dw_cresa_maestro_<dominio>
```

Ejemplos:

```text
dlh_cresa.gold.dw_cresa_maestro_cliente
dlh_cresa.gold.dw_cresa_maestro_producto
```

### Gold — productos derivados (nuevo, Fase 3)

```text
dlh_cresa.gold.dw_cresa_<dominio>_<producto>
```

Ejemplos:

```text
dlh_cresa.gold.dw_cresa_cliente_campos_salesforce
```

### Antecedente de control de gobierno

El documento 17 propone `audit01.mdm_clientes_productos_*`; los nombres `gobierno_*` siguientes corresponden al diseño anterior y no se presentan como implementados.

```text
dlh_cresa.audit01.gobierno_<capa>_<entidad>
```

Ejemplos:

```text
dlh_cresa.audit01.gobierno_silver_reglas
dlh_cresa.audit01.gobierno_silver_resultados
dlh_cresa.audit01.gobierno_gold_certificacion
dlh_cresa.audit01.gobierno_gold_publicacion
```

## Archivos YAML

| Tipo | Patrón |
|---|---|
| Entidad Silver | `config/silver/<dominio>.<entidad>.yml` |
| Producto Gold | `config/gold/<dominio>.<producto>.yml` |
| Ambiente | `config/environments/<ambiente>.yml` — propuesta de configuración; ambientes identificados: `dlh_cresa` y `dev_dlh_cresa`; no afirmar que estos archivos estén implementados |

Ejemplos:

```text
config/silver/cliente.dw_cresa_cliente_conformado.yml
config/silver/producto.dw_cresa_producto_conformado.yml
config/gold/cliente.dw_cresa_maestro_cliente.yml
config/gold/cliente.dw_cresa_cliente_campos_salesforce.yml
config/gold/producto.dw_cresa_maestro_producto.yml
```

## Antecedente de notebooks y jobs

La convención vigente del documento 17 usa un job por fuente y un orquestador de maestros; los ejemplos por entidad siguientes quedan como referencia anterior y no deben multiplicarse en el despliegue.

| Artefacto | Patrón |
|---|---|
| Notebook Silver genérico | `nb_silver_transform_entity_cresa` |
| Notebook Gold genérico | `nb_gold_build_product_cresa` |
| Job Silver por entidad | `job_silver_<dominio>_<entidad>` |
| Job Gold por producto | `job_gold_<dominio>_<producto>` |

Ejemplos:

```text
job_silver_cliente_dw_cresa_cliente_conformado
job_gold_cliente_dw_cresa_maestro_cliente
job_gold_cliente_dw_cresa_cliente_campos_salesforce
```

## Columnas técnicas obligatorias (nuevas tablas de Fase 3)

### Silver

| Columna | Propósito |
|---|---|
| `_domain_official` | `Cliente` o `Producto` |
| `_business_key` | `num_identificacion` / `cod_producto` |
| `_quality_status` | `ok` / `warning` / `failed` / `requires_review` |
| `_quality_flags` | Lista de problemas detectados |
| `_bronze_refs` | Tablas Bronze/Gold origen |

### Gold

| Columna | Propósito |
|---|---|
| `_certification_status` | `temporal` / `validado` / `certificado` / `restringido` / `deprecated` |
| `_data_owner` | Rol/persona responsable |
| `_last_certified_at` | Fecha de última certificación |
| `_sensitivity_classification` | `Público` / `Interno` / `Confidencial` / `Sensible-Regulado` |

## Estados permitidos

| Concepto | Valores |
|---|---|
| Estado de producto Gold | `temporal`, `validado`, `certificado`, `restringido`, `deprecated` |
| Sensibilidad | `Público`, `Interno`, `Confidencial`, `Sensible-Regulado` (clasificación ya definida en Arquitectura To-Be cap. 4.4) |
| Resultado de calidad Silver | `ok`, `warning`, `failed`, `requires_review` |

## Regla para nombres de dominio

Fase 3 no crea dominios técnicos nuevos por conveniencia. "Campos habilitadores de Salesforce" o "conformación de crédito" son productos de datos o atributos incorporados al dominio Cliente — no dominios propios (ver `08_alineacion_dominios_as_is_fase3.md`).

## Ejemplo end-to-end (Cliente)

| Elemento | Nombre |
|---|---|
| Fuentes Bronze/Gold usadas | `dlh_cresa.bronze.customersv3`, `dlh_cresa.gold.dw_cresa_persona_dim` |
| YAML Silver | `config/silver/cliente.dw_cresa_cliente_conformado.yml` |
| Tabla Silver | `dlh_cresa.silver.dw_cresa_cliente_conformado` |
| YAML Gold | `config/gold/cliente.dw_cresa_maestro_cliente.yml` |
| Tabla Gold | `dlh_cresa.gold.dw_cresa_maestro_cliente` |
| Job Silver | `job_silver_cliente_dw_cresa_cliente_conformado` |
| Job Gold | `job_gold_cliente_dw_cresa_maestro_cliente` |

## Coordinación pendiente con Handytech

Si se confirma que Handytech implementa dominios de gobierno completos para Financiero/Crédito/Operaciones (ver `06_hipotesis_validacion.md` #4), estas convenciones deben compartirse con su equipo para evitar un segundo patrón de nombramiento paralelo dentro del mismo catálogo `dlh_cresa`.
