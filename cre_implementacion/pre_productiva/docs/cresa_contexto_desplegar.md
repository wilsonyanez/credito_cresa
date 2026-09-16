> **Revisión de consistencia — 2026-09-16.** Antecedente documental o evidencia fechada. Para nombres, capacidad, estado de acceso y operación actuales prevalecen el [estado vigente](ESTADO_VIGENTE.md), la [arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y el [informe extendido](20_CRESA_MDM_ANALISIS_EXTENDIDO.md). Los comandos, límites y resultados anteriores del contenido siguiente se conservan como antecedentes; no acreditan un despliegue MDM ni una ejecución actual.

# Contexto CRESA — despliegue del proyecto credicresa

Actualizado: 2026-09-07. Consolida decisiones, incidencias corregidas y evidencia de la sesión. Esta actualización documental no constituye una nueva ejecución remota.

## Cliente, proyecto y alcance

| Concepto | Valor vigente |
|---|---|
| Cliente / catálogo Unity Catalog | cresa |
| Proyecto / base de datos / esquema | credicresa |
| Nombre completo | cresa.credicresa |
| Ejemplo fuente | cresa.credicresa.sis_peticiones |
| Ejemplo Bronze | cresa.bronze.credicresa_sis_peticiones |
| Control plane del proyecto | cresa.audit01.credicresa_* |
| Carpeta remota | /Workspace/Users/wilsonyanez@hotmail.com/cresa/credicresa |
| Paquete remoto | carpeta anterior + /pre_productiva |
| Job único | job_credicresa_ingesta_periodo |

La separación cliente/proyecto permite otros proyectos en cresa; los prefijos y volúmenes identifican a credicresa. No se renombran ni eliminan objetos ajenos. Los datos se conservan en Parquet y se exponen mediante vistas Unity Catalog. El control plane permanece en Delta. Silver y Gold están reservados y no reciben datos. La fuente se recrea dentro de Databricks, sin SQL Server, JDBC, CDC ni incrementalidad.

## Archivos activos y copia única

Paquete: C:/desa/git/cresa/cre_implementacion/pre_productiva.

| Artefacto | Ruta relativa |
|---|---|
| Entrada solicitada por cliente | scripts/cresa_desplegar.ps1 |
| Implementación Shell del proyecto | scripts/credicresa_desplegar.ps1 |
| Orquestador local | scripts/credicresa_cli.py |
| Carga por período | scripts/credicresa_procesar_periodo.ps1 |
| Fuente | config/sources/credicresa.yml |
| 34 contratos de entidades | config/ingestion/credicresa_*.yml |
| Diccionario SQL original | sql/02_credicresa_catalogos.sql |
| Generación de tipos | scripts/credicresa_actualizar_tipos.py |
| Contratos/runtime | lib/cresa_contracts.py; lib/credicresa_runtime.py |
| Definición del job | config/jobs/job_credicresa_ingesta_periodo.json |

C:/desa/git/cresa/scripts/credicresa_desplegar.ps1 es un lanzador externo hacia la misma implementación. cresa_* delega en credicresa_*; no se duplica la lógica. No se copian archivos ejecutados a C:/desa/git/cresa/test. C:/desa/git/cresa/tests recibe exclusivamente cresa_desplegar.log; los logs históricos no se reescriben.

## Entradas SQL y tipos

La carpeta sql contiene cuatro scripts de definiciones, sin registros de negocio para cargar. 02_credicresa_catalogos.sql contiene DDL de varias fuentes con sintaxis SQL Server/MySQL: se utiliza como diccionario, no se ejecuta en bloque. Se toman las definiciones correspondientes a las 34 entidades activas y sus 451 atributos.

columns.source_types conserva el tipo SQL y columns.types define el tipo Spark. VARCHAR/CHAR/TEXT → STRING; BIT → BOOLEAN; FLOAT(53) → DOUBLE; DECIMAL conserva precisión/escala; DATETIME → TIMESTAMP_NTZ. Permanecen 267 atributos de texto por definición SQL; los otros 184 tienen tipos numéricos, booleanos o temporales. Las longitudes VARCHAR se documentan y no se imponen como restricciones Spark.

## Errores encontrados y correcciones

| Hallazgo | Corrección |
|---|---|
| Todas las columnas STRING sin semillas | Tipos explícitos del DDL, incluso en estructuras vacías |
| document, cellular, motive | documento, celular, motivo según SQL |
| fecha_creacion en cat_modelo_calificacion | creado según el diccionario |
| Columnas ajenas en cat_solicitud_estados | Sus siete atributos del DDL |
| Columnas omitidas | direccion y canal_externo_id en cat_almacen; id en cre_solicitante |
| Llaves naturales con atributos inexistentes | Marcadas pendientes en cat_solicitud_estados y cre_solicitante; sin inventar llaves ni activar MERGE |
| Referencias operativas de otros clientes | Nombres y documentación actualizados a CRESA |
| Catálogo anterior credito_cresa | Cliente/catálogo cresa y proyecto/esquema credicresa |
| Serverless rechazó errorifexists | mode("error") sobre rutas de lote únicas, sin sobrescritura |
| read_files añadía columna de rescate | schema explícito del YAML y schemaEvolutionMode='none' |
| Exportación RAW de la marca rechazada | Lectura con AUTO; importación de archivos con RAW |
| Resultado del job incluía intentos anteriores | Evaluar el último intento por tarea |
| Reproceso de períodos | input_batch inmutable y creación de subdirectorios antes de subir |

No se infieren tipos por nombre. Se validan columnas y conversiones antes de publicar el período. Las escrituras de varias entidades no son una transacción atómica: un fallo puede dejar algunas vistas actualizadas; revisar el run y reprocesar un snapshot completo.

## Secuencia de despliegue

1. Validar diccionario, 34 YAML, sintaxis Python y job JSON.
2. Verificar OAuth/warehouse y crear el catálogo cresa si no existe.
3. Comprobar marcas de propiedad antes de reutilizar job y carpeta.
4. Importar exclusivamente lib, config, sql y notebooks.
5. Ejecutar 00_create_test_environment.sql, 00_create_credicresa_database.sql y 01_create_control_plane.sql.
6. Crear/actualizar el job con client=cresa, project=credicresa, concurrencia uno y schedule PAUSED.
7. Ejecutar bootstrap=true: credicresa_fuente → credicresa_bronze → credicresa_verificar.
8. Esperar SUCCESS de las tres tareas, verificar 68 vistas/902 atributos y guardar .deployment/credicresa.json.

El control plane contiene credicresa_ingestion_runs, credicresa_ingestion_table_runs, credicresa_ingestion_columns y credicresa_ingestion_watermarks; sus vistas son credicresa_v_latest_ingestion_run y credicresa_v_ingestion_errors. Los volúmenes son cresa.credicresa.data, cresa.landing.credicresa_input y cresa.bronze.credicresa_data.

## Comandos y parámetros

Desde C:/desa/git/cresa/cre_implementacion/pre_productiva/scripts:

```powershell
# Solo validación local.
.\cresa_desplegar.ps1

# Despliegue remoto.
.\cresa_desplegar.ps1 -Deploy -AuthName "cresa-dev" -WorkspaceUrl "https://dbc-d87ef1e3-6c95.cloud.databricks.com" -WorkspacePath "/Workspace/Users/wilsonyanez@hotmail.com/cresa/credicresa" -SqlWarehouseId "61b8feaf5fbd763d"

# Regenerar tipos y validar tras modificar el diccionario.
..\.venv\Scripts\python.exe .\credicresa_actualizar_tipos.py
.\validate_package.ps1
```

| Parámetro | Uso / valor predeterminado |
|---|---|
| Deploy | Habilita creación/importación y ejecución remota; omitido, valida localmente |
| Authenticate | Solicita OAuth con CLI; puede abrir el navegador |
| AuthName | cresa-dev |
| WorkspaceUrl | https://dbc-d87ef1e3-6c95.cloud.databricks.com |
| WorkspacePath | /Workspace/Users/wilsonyanez@hotmail.com/cresa/credicresa |
| SqlWarehouseId | 61b8feaf5fbd763d |
| PythonPath | .venv/Scripts/python.exe del paquete, con requirements.txt instalado |
| TimeoutSeconds | 7200; un timeout local no cancela el run remoto |

Los valores anteriores se usaron en el despliegue documentado. No se guardan credenciales en scripts, YAML, manifiestos o logs. Sin Deploy ni Authenticate no hay acciones remotas. Después de un timeout, consultar el run antes de reintentar.

## Carga por período

Layout: <InputRoot>/<Period>/<source_table>/*.csv o *.parquet. Period acepta YYYY-MM o YYYY-MM-DD. CSV requiere encabezados y el delimitador suministrado.

```powershell
.\credicresa_procesar_periodo.ps1 -Period "2026-09" -InputRoot "C:/desa/git/cresa/planos" -SeedFormat csv -Delimiter ";" -AuthName "cresa-dev" -SqlWarehouseId "61b8feaf5fbd763d"
```

TableFilter admite una regex, por ejemplo ^sis_peticiones$; sin filtro se requieren las 34 entidades. La subida usa landing/credicresa_input/<period>/<input_batch>/<entidad>. Las vistas publican el último snapshot completo; los anteriores permanecen en Parquet. No se concatenan automáticamente períodos.

El usuario confirmó posteriormente la carpeta pre_productiva/sql como ubicación de insumos. Esos archivos cubren estructuras y tipos, no registros. La carga con datos reales queda pendiente de recibir archivos y período.

## Evidencia obtenida

- Fecha: 2026-09-07.
- Job: 1008661299620101, job_credicresa_ingesta_periodo, PAUSED.
- Run: 1094185962105919, SUCCESS en fuente, Bronze y verificación.
- Resultado: 34 vistas fuente + 34 vistas Bronze; 902 comprobaciones de atributos.
- Auditoría: 8f11d9b93d3c46efa802cab8b16ffd8d, SUCCEEDED, 34 entidades, 451 atributos registrados, cero errores.
- Datos: cero filas de negocio; ejecución bootstrap.
- Pruebas locales del trabajo implementado: 20 satisfactorias.
- Spark: BIGINT sin pérdida de precisión y rechazo de texto inválido/desbordamiento decimal.
- Log: C:/desa/git/cresa/tests/cresa_desplegar.log.
- Manifiesto operativo: .deployment/credicresa.json; conservarlo para la reversa.

El run 856346002227926 se canceló al corregir cliente/proyecto. Los objetos preparatorios de credito_cresa y su carpeta anterior se conservaron; no se ejecutó su reversa. El job activo utiliza el destino nuevo.

La evidencia prueba creación, tipos y funcionamiento técnico; no certifica datos reales ni productos Silver/Gold. Ver [resultado detallado](RESULTADO_DESPLIEGUE_CRESA.md) y [contexto de reversa](cresa_contexto_reversar.md).

## Lineamientos

Referencia disponible: [CRESA_LINEAMIENTOS_ETL_LOGICA_NEGOCIO_v1.1.docx](CRESA_LINEAMIENTOS_ETL_LOGICA_NEGOCIO_v1.1.docx), borrador del 2026-09-02. No se encontró el Markdown en la ruta externa indicada. La sección 18 prevalece sobre disposiciones incompatibles del documento. Se mantiene Medallion; no se declara implementado el framework productivo Silver/Gold ni sus contratos JSON Schema. El catálogo productivo dlh_cresa no es el destino de este paquete.

## Revisión de creación y eliminación por proyecto

Cliente cresa y proyecto credicresa se mantienen separados en nombres y destinos.
Los 34 YAML conservan sus 451 atributos derivados del diccionario SQL; las descripciones
activas identifican CRESA (proyecto credicresa). El script de períodos existente automatiza
snapshots CSV/Parquet; los archivos SQL son DDL, no datos de períodos.

La ayuda de credicresa_desplegar.ps1 incluye la creación y remite la eliminación a
credicresa_reversar.ps1 -DropProjectSchema. Esta opción elimina también el esquema
cresa.credicresa y su volumen data; no elimina el catálogo del cliente ni otros proyectos.
Véase [alcance, parámetros y comandos de reversa](cresa_contexto_reversar.md).

## Estado comprobado el 2026-09-07, 20:41 UTC

Revisión remota de solo lectura: el job 1008661299620101 ya no figura en el inventario
completo de jobs; tampoco están las 34 vistas Bronze. Permanecen las 34 vistas fuente,
cresa.credicresa, su volumen data y la carpeta del proyecto con marca de propiedad.
Este estado posterior no debe confundirse con el despliegue exitoso histórico.

La vista previa con DropProjectSchema terminó correctamente:
rastro 38c72b53b22a44c8a6495bc1d01286ab, registrado en
C:/desa/git/cresa/tests/cresa_desplegar.log. Incluye las 34 vistas restantes,
el volumen data, el esquema fuente y la carpeta del proyecto. La consulta inicial del
job del manifiesto falló; se corrigió la reversa para admitir ausencias comprobadas
mediante inventarios completos, sin ignorar errores de consulta.

Validación local: 34 YAML, 451 atributos, 29 pruebas satisfactorias.
No se ejecutó Execute ni un nuevo Deploy en esta revisión. La comprobación posterior
a la eliminación está implementada y probada localmente; la eliminación real no fue
ejecutada. El comando Deploy recrea los artefactos faltantes y ejecuta su verificación.
