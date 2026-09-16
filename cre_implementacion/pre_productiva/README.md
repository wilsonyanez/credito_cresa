# CRESA — paquete activo CrediCresa y diseño MDM

Revisión: 2026-09-16. El [estado vigente](docs/ESTADO_VIGENTE.md) organiza documentos, evidencia y limitaciones.

## Dos alcances diferenciados

| Alcance | Estado |
|---|---|
| CrediCresa | 34 contratos/451 atributos; piloto de bootstrap vacío limitado a 14 entidades, 42 vistas Parquet y una tabla Delta de auditoría |
| MDM de Cliente y Producto | Arquitectura y cobertura definidas en documentos 17/20; maestros y volúmenes propuestos, sin despliegue acreditado |

El cliente usa `dev_dlh_cresa` en Desarrollo y `dlh_cresa` en Producción. `devstgdlh02` dispone de 1,2 TB declarados y el espacio no restringe esta etapa. El piloto conserva `cresa` y sus límites actuales: eliminar la restricción de espacio del diseño no modifica automáticamente el código del lanzador.

[Arquitectura MDM y nombres completos](docs/17_CRESA_DATABRICK_DEFINICION_INICIAL.md): Silver `dw_cresa_cliente_conformado` / `dw_cresa_producto_conformado`; Gold `dw_cresa_maestro_cliente` / `dw_cresa_maestro_producto`. Entre ambientes cambia únicamente el catálogo. [Entidades e insumos por atributo](docs/20_CRESA_MDM_ANALISIS_EXTENDIDO.md).

## Artefactos activos

| Artefacto | Ruta relativa al paquete |
|---|---|
| Fuente | `config/sources/credicresa.yml` |
| Contratos | `config/ingestion/credicresa_*.yml` |
| Diccionario de tipos de origen | `sql/02_credicresa_catalogos.sql` |
| Configuración de destino del piloto | `config/credicresa_despliegue.yml` |
| Despliegue / reversa | `scripts/cresa_credicresa_desplegar.ps1`, `scripts/cresa_credicresa_reversar.ps1` |
| Implementación del piloto | `lib/cresa_credicresa_pilot.py`, `lib/cresa_credicresa_common.psm1` |
| Notebook del piloto | `notebooks/credicresa_pip_credito_oro.py` |
| Plantilla del pipeline por período | `config/jobs/job_credicresa_ingesta_periodo.json` |
| Runtime por período | `lib/credicresa_runtime.py`, `lib/credicresa_medallion.py`, `lib/credicresa_quality.py` |

El lanzador genera su plan desde el código y los 34 contratos, seleccionando hasta 14 entidades; no interpreta `config/cresa_credito_piloto.yml` como configuración vigente del destino. Ese YAML conserva una propuesta anterior. El diccionario SQL preserva nombres de origen como metadatos: no ejecutarlo en bloque como DDL de despliegue.

Los esquemas del piloto son `audit01`, `landing`, `bronze`, `silver`, `gold`; no se crea un esquema por proyecto. Las vistas son `cresa.<capa>.credicresa_<entidad>_<capa>`. El bootstrap del piloto crea vistas en Bronze/Silver/Gold; `landing` recibe la estructura de recepción. La auditoría del piloto es `cresa.audit01.credicresa_ejecuciones_bronce`.

El job es `JOB_CRE_00_CARGA_DATOS_CREDI_CRESA`. La plantilla por período tiene cinco tareas, pero el lanzador del piloto no instala un segundo job ni ejecuta una carga de planos. No hay lanzador vigente `credicresa_procesar_periodo.ps1` en este paquete. Los snapshots Silver/Gold de prueba no son maestros certificados.

## Validación local

Ejecutar desde `pre_productiva/` con el entorno Python disponible y `requirements.txt` instalado:

```powershell
.\scripts\cresa_credicresa_desplegar.ps1
.\.venv\Scripts\python.exe -m unittest discover -s tests -p "test_*.py"
```

El primer comando genera un plan local sin APIs remotas. La suite completa tiene dos errores de importación conocidos (`credicresa_cli` y `cresa_eliminar_catalogos`, implementaciones antiguas ausentes); no se declara aprobada. La validación directa de contratos y los 43 casos cargados de piloto, Medallion y calidad pasan en la revisión de consolidación. Ver detalle en [validación](docs/VALIDACION_CONSOLIDACION.md).

## Operación del piloto

La ruta configurada de Workspace del piloto es `/Workspace/Users/wilsonyanez@hotmail.com/.git/cresa/credicresa`; los nuevos destinos del MDM mantienen placeholders hasta su definición autorizada. Se importan `config`, `lib`, `sql` y notebooks sin carpeta intermedia `pre_productiva`. El notebook renderizado por ejecución preserva su identidad para reversa.

Parámetros soportados: `-AuthName`, `-WorkspaceUrl`, `-WorkspacePath`, `-SqlWarehouseId`, `-PythonPath`, `-LogPath`, `-OutputRoot`, `-Entities` y `-TimeoutSeconds`. `OutputRoot` dirige el LOG; `LogPath` explícito tiene prioridad. El LOG por defecto del módulo está en `scripts/cresa_credicresa_desplegar.log`. No se usa OutputRoot para mover manifiestos ni copiar el paquete.

`-Deploy` solicita despliegue y bootstrap; `-Resume` recupera exclusivamente un manifiesto PREPARING sin job/run. Son excluyentes. El despliegue rechaza adoptar catálogos existentes. Resume verifica propietario, inventario y archivos remotos antes de completar faltantes; no usarlo para forzar un despliegue MDM contra `dev_dlh_cresa`.

```powershell
# Plan local de reversa; requiere un manifiesto compatible.
.\scripts\cresa_credicresa_reversar.ps1
```

`-WhatIf` inspecciona remotamente y `-Execute` ejecuta la reversa; son excluyentes. La reversa conserva esquemas, volúmenes, Parquet y configuración; elimina únicamente vistas, job y notebook verificados por manifiesto. Manifiestos históricos incompatibles no se editan para sustituir nombres. La opción histórica `DropProjectSchema` no forma parte del lanzador actual.

La publicación de cambios en Git no ejecuta ninguna de estas acciones remotas. Las credenciales se gestionan por OAuth/Secret Scope; no van en documentos, argumentos ni LOG.

## Tipos, carga y calidad

Los tipos se derivan del SQL: `columns.source_types` preserva el origen y `columns.types` su correspondencia Spark. No se inventan tipos por nombre. Las claves no definidas permanecen pendientes. Parquet para datos, Delta para control; snapshot completo sin watermark ni borrados incrementales habilitados.

El runtime por período recibe período y lote inmutable; no interpreta la ausencia de archivos como una entidad vacía. Su publicación no es una transacción conjunta de todas las vistas. Antes de habilitarlo operacionalmente se requiere cerrar el mecanismo de entrega y validar el job en su destino. Las fuentes Delta de Producción requieren exportación consistente a Parquet si se trasladan a Desarrollo.

La [guía por fuente](docs/PIPELINE_POR_FUENTE.md) y el [checklist](docs/CHECKLIST_DESPLIEGUE_DATABRICKS.md) describen estas diferencias. Los documentos de resultados, Excel, DOCX y LOG son evidencia o insumos fechados; sus comandos anteriores no son instrucciones vigentes.
