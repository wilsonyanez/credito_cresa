# Operación vigente — pipeline por fuente

Revisión: 2026-09-16. [Operación y parámetros](../README.md). [Arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y [cobertura de entidades](20_CRESA_MDM_ANALISIS_EXTENDIDO.md).

## Fuente y contratos

Fuente: `config/sources/credicresa.yml`. Contratos: 34 YAML `config/ingestion/credicresa_*.yml`, 451 atributos contrastados con `sql/02_credicresa_catalogos.sql`. Las rutas son relativas a `pre_productiva/`.

`columns.source_types` conserva el tipo SQL; `columns.types` fija su correspondencia Spark. Las claves pendientes no se usan para MERGE o incrementalidad. `cat_modelo_calificacion` usa `creado`; `cat_solicitud_estados` usa los siete atributos del DDL; `cat_almacen` incluye `direccion` y `canal_externo_id`; `cre_solicitante` incluye `id`. Se preservan nombres y tipos del contrato, sin inferencia semántica por nombre.

## Piloto ejecutable y plantilla por período

| Aspecto | Piloto actual | Plantilla/runtime por período |
|---|---|---|
| Entrada | `scripts/cresa_credicresa_desplegar.ps1` | `config/jobs/job_credicresa_ingesta_periodo.json`; no hay lanzador de entrega de planos vigente |
| Selección | Hasta 14 entre 34 contratos | Contratos seleccionados por metadatos/filtro |
| Proceso | Bootstrap vacío Bronze/Silver/Gold | Fuente → Bronze → Silver → Gold → verificación |
| Resultado esperado | 42 vistas y una auditoría Delta para 14 entidades | Con 34 entidades: 136 vistas/1804 comprobaciones de atributos; expectativa, no evidencia de despliegue actual |
| Identidad de job | `JOB_CRE_00_CARGA_DATOS_CREDI_CRESA` | Mismo nombre en plantilla; no instalar como segundo job del piloto |
| Certificación MDM | No | No; requiere reglas de negocio propias |

El piloto usa `cresa` y los esquemas `audit01`, `landing`, `bronze`, `silver`, `gold`. Vistas `credicresa_<entidad>_<capa>` y auditoría `audit01.credicresa_ejecuciones_bronce`. No crea un esquema `cresa.credicresa`. El diccionario de origen no es DDL para ejecutar en bloque.

## Contrato de carga por período

El runtime conserva lote y período, valida encabezados y conversiones antes de publicar snapshots Parquet y rechaza entradas ausentes. Silver/Gold diagnostican nulos, duplicados y longitudes; no certifican reglas MDM pendientes. El control plane del runtime permanece en tablas Delta `audit01.credicresa_*`.

Los snapshots previos se conservan; las vistas apuntan a la publicación correspondiente. No hay transacción conjunta entre todas las entidades. Se requiere corte estable, manifiesto y conciliación antes de habilitar consumo. No se activa incrementalidad sin watermark y estrategia de borrados.

## MDM y capacidad

El proyecto `mdm_clientes_productos` usa `dev_dlh_cresa` / `dlh_cresa`. Desarrollo dispone de 1,2 TB declarados en `devstgdlh02`, sin restricción de espacio en esta etapa. El código del piloto sigue limitado a 14 entidades: la nueva capacidad no amplía su selección automáticamente.

Silver: `dw_cresa_cliente_conformado` y `dw_cresa_producto_conformado`. Gold: `dw_cresa_maestro_cliente` y `dw_cresa_maestro_producto`. La matriz de nombres completos, volúmenes y directorios está en el documento 17. No se reintroducen conexiones a SQL Server ni se ejecutan maestros con el piloto.

## Evidencia y recuperación

Los planes locales no acreditan despliegue remoto. El manifiesto identifica los objetos del piloto; la reversa requiere coincidencia de nombre/propiedad y conserva datos. Las mediciones de fuentes del 15 de septiembre y los metadatos del 16 se conservan en `tests/contexto_03` y `tests/contexto_04`. Los lineamientos DOCX son un insumo versionado; las decisiones aplicables a esta entrega se consolidan en [estado vigente](ESTADO_VIGENTE.md).
