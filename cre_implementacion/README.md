# CRESA — ingesta y MDM de clientes y productos

Revisión documental: 2026-09-16. Paquete activo: `pre_productiva/`.

## Documentación vigente

- [Estado, alcance e índice documental](pre_productiva/docs/ESTADO_VIGENTE.md).
- [Arquitectura, volúmenes y nombres por ambiente](pre_productiva/docs/17_CRESA_DATABRICK_DEFINICION_INICIAL.md).
- [Entidades, brechas e insumos de los maestros](pre_productiva/docs/20_CRESA_MDM_ANALISIS_EXTENDIDO.md).
- [Operación del paquete y validación local](pre_productiva/README.md).

Desarrollo del cliente usa `dev_dlh_cresa` y el almacenamiento `devstgdlh02`, con **1,2 TB disponibles declarados, sin restricción de espacio en esta etapa**. Producción usa `dlh_cresa`. El catálogo `cresa` corresponde al piloto de pruebas; no se confunden sus resultados con el MDM.

| Dominio | Silver — nombre conservado entre ambientes | Gold — nombre conservado entre ambientes |
|---|---|---|
| Cliente | `dw_cresa_cliente_conformado` | `dw_cresa_maestro_cliente` |
| Producto | `dw_cresa_producto_conformado` | `dw_cresa_maestro_producto` |

Los nombres completos usan `<catalogo>.silver.<objeto>` y `<catalogo>.gold.<objeto>`. El proyecto mantiene `mdm_clientes_productos` en volúmenes, código y operación.

## Estructura y alcance

| Carpeta | Uso |
|---|---|
| `pre_productiva/` | Paquete técnico activo, documentos vigentes y evidencia fechada |
| `documentacion_insumo/` | Mapa de maestros y análisis funcional; métricas históricas identificadas |
| `construccion_tecnica_previa/` | Archivo de solo lectura; no desplegar ni ejecutar sus comandos |

La fuente activa se configura en `pre_productiva/config/sources/credicresa.yml`; existen **34 YAML y 451 atributos** derivados del diccionario SQL. El lanzador `pre_productiva/scripts/cresa_credicresa_desplegar.ps1` valida localmente por defecto y conserva un piloto de 14 entidades, 42 vistas y una tabla de auditoría. El job único se denomina `JOB_CRE_00_CARGA_DATOS_CREDI_CRESA`; la plantilla por período está en `pre_productiva/config/jobs/job_credicresa_ingesta_periodo.json`.

Datos del paquete en Parquet y control plane en Delta. No existe conexión activa a SQL Server; no se habilitan JDBC, incrementalidad ni certificación de maestros mediante esta revisión documental. Las fuentes productivas Delta se conservan y cualquier exportación se realiza mediante lectura de tablas, no copia de archivos internos.

La publicación en Git reúne los cambios locales; no ejecuta un despliegue en Databricks. Los resultados de pruebas y sus limitaciones están en el estado vigente.
