> **Revisión de consistencia — 2026-09-16.** Antecedente documental o evidencia fechada. Para nombres, capacidad, estado de acceso y operación actuales prevalecen el [estado vigente](ESTADO_VIGENTE.md), la [arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y el [informe extendido](20_CRESA_MDM_ANALISIS_EXTENDIDO.md). Los comandos, límites y resultados anteriores del contenido siguiente se conservan como antecedentes; no acreditan un despliegue MDM ni una ejecución actual.

# CRESA credito: siete fases

## Convención vigente — revisión 2026-09-14

Esta revisión sustituye los destinos y nombres indicados en las secciones históricas
inferiores. Cliente y catálogo: `cresa`; proyecto: `credicresa`.
Los únicos esquemas de aplicación son `audit01`, `landing`, `bronze`, `silver` y `gold`.
No se crea un esquema por proyecto. Las vistas de datos siguen
`credicresa_<entidad>_<capa>`; por ejemplo,
`cresa.bronze.credicresa_cat_almacen_bronze`. La fuente interna se publica en
`cresa.landing.credicresa_<entidad>_landing`. El diccionario SQL conserva los nombres
originales como metadatos; no debe ejecutarse como DDL de despliegue.

La ruta de Workspace es
`/Workspace/Users/wilsonyanez@hotmail.com/.git/cresa/credicresa`.
Se interpreta la referencia al usuario y `.git` usando la separación ya existente
en la configuración local. Bajo el proyecto están `config/ingestion`, `config/jobs`,
`config/sources`, `notebooks`, `lib` y `sql`, sin carpeta intermedia `pre_productiva`.
El notebook renderizado del piloto se ubica en `notebooks/<run>/` para preservar
su identidad en la reversa. Configuración, librerías y SQL se importan directamente.

El despliegue disponible es `scripts/cresa_credicresa_desplegar.ps1` (sin `-Deploy`
solo valida localmente). Su job se llama `JOB_CRE_00_CARGA_DATOS_CREDI_CRESA`.
Se conserva el alcance del piloto: 14 entidades seleccionadas entre 34 contratos,
42 vistas Parquet y una tabla Delta de auditoría. `landing` se crea para recepción;
el piloto sigue siendo bootstrap vacío, sin carga de planos ni reglas nuevas.
La plantilla de ingesta por período usa `JOB_CRE_00_CARGA_DATOS_CREDI_CRESA`;
no se instala como segundo job del piloto. Los lanzadores antiguos mencionados
abajo que no existen en el paquete no deben usarse.

Las tablas Delta de control mantienen su prefijo `credicresa_` y nombre funcional.
La reversa conserva esquemas, volúmenes, Parquet y archivos de configuración;
solo elimina las vistas, el job y el notebook verificados en su manifiesto.
Los manifiestos históricos no se migran ni se usan para borrar objetos con los
nombres nuevos. El despliegue sigue rechazando catálogos existentes: no adopta
ni migra automáticamente un catálogo remoto.

Cambios validados localmente; no se ejecutó un despliegue ni una modificación remota.

## Fase 8 — ejecución desde línea de comandos

Los únicos puntos de entrada son los dos archivos PowerShell en `scripts/`:

```powershell
# Plan local de despliegue; agregar -Deploy para ejecutar el despliegue autorizado.
.\scripts\cresa_credicresa_desplegar.ps1

# Plan local de reversa, requiere el manifiesto del despliegue.
.\scripts\cresa_credicresa_reversar.ps1

# Inspección remota de reversa, sin eliminar objetos.
.\scripts\cresa_credicresa_reversar.ps1 -WhatIf

# Reversa efectiva, únicamente con solicitud explícita.
.\scripts\cresa_credicresa_reversar.ps1 -Execute
```

Ejecutar desde `pre_productiva/`. Para operaciones remotas se conservan los
parámetros `-AuthName`, `-WorkspaceUrl`, `-WorkspacePath` y `-SqlWarehouseId`.
`-Execute` y `-WhatIf` son excluyentes. El código compartido reside en
`lib/cresa_credicresa_common.psm1` y `lib/cresa_credicresa_pilot.py`; los lanzadores
lo invocan internamente. Los archivos LOG son evidencia, no comandos.
Se conservan las rutas de los manifiestos existentes para permitir la reversa.

## Referencia anterior e historial


## 1. Normalizacion e insumos

Base: `C:/desa/git/cresa/cre_implementacion`. Los scripts obtienen esa base desde
su ubicacion y rechazan una base distinta; admiten reubicar el paquete completo.

| Entrada solicitada | Resolucion |
|---|---|
| `analisis_caracterizacion` | `documentacion_insumo/analisis_caracterizacion`, solo lectura |
| `muestras_consultas_bases_datos/consultas_bases_datos` | No existe; evento `FLAT_FILES_MISSING_BOOTSTRAP_ONLY` |
| SQL de despliegue y diccionario | `pre_productiva/sql` |
| Contexto | `pre_productiva/docs/cresa_contexto_desplegar.md` |
| Ontologia | `pre_productiva/docs/CRESA_DATABRICK_DEFINICION_INICIAL.xlsx` |

Se revisaron las nueve pestanas indicadas. Los ejemplos de otras fuentes no se
agregan como entidades CRESA. Las referencias JDBC/DLT del Excel son historicas;
el paquete mantiene fuente interna, Parquet y un workflow de notebooks.
La solicitud actual define `cresa_credito`; los antecedentes `cresa.credicresa`
continuan documentados como otro destino. No se migra ni elimina ese destino.

## 2. Artefactos y alcance

| Artefacto | Ruta relativa a pre_productiva |
|---|---|
| Despliegue parametrizado | `scripts/cresa_credicresa_desplegar.ps1` |
| Reversa parametrizada | `scripts/cresa_credicresa_reversar.ps1` |
| Lanzamiento y errores PowerShell | `lib/cresa_credicresa_common.psm1` |
| Plan, propiedad, manifiesto y API | `lib/cresa_credicresa_pilot.py` |
| Configuracion del piloto | `config/cresa_credito_piloto.yml` |
| Pipeline consolidado | `notebooks/credicresa_pip_credito_oro.py` |
| Ejemplo de tipos | `docs/examples/cresa_credito_tipos.yml` |
| Consulta de defaults | `sql/cresa_credito_tipos_ejemplo.sql` |
| Inventario completo | `docs/CRESA_CREDITO_INVENTARIO.csv` |
| Pruebas locales | `tests/test_cresa_credito_pilot.py` |

Piloto por defecto: primeras 14 entidades por nombre. `-Entities` permite sustituir
la seleccion completa por hasta 14 nombres de los 34 contratos. Se conservan los
451 atributos y tipos ya corregidos del paquete; no se reescriben contratos validos.
El plan JSON/YAML materializa los contratos tipados seleccionados. El CSV documenta
la seleccion predeterminada; el manifiesto y el LOG contienen la seleccion efectiva.

**Limite:** 14 x 3 = 42 vistas de datos + 1 tabla Delta = **43 objetos consultables**,
inferior a 45 incluso contando cada representacion Medallion por separado. Catalogo,
cuatro esquemas, tres volumenes, notebook y job se inventarian como infraestructura,
no como entidades/tablas. Se validan las 34 entidades y se registran las 20 excluidas.

## 3. Objetos y correccion de tipos

| Recurso | Nombre |
|---|---|
| Catalogo solicitado | `cresa_credito` |
| Esquemas | `credicresa_datos_bronce`, `credicresa_datos_plata`, `credicresa_datos_oro` |
| Volumen por capa | `credicresa_archivos_<capa>` |
| Vista por entidad/capa | `credicresa_<entidad>_<capa>` |
| Esquema de control | `credicresa_control_bronce` |
| Tabla Delta de control | `credicresa_ejecuciones_bronce` |
| Job unico | `credicresa_job_credito_oro` |
| Pipeline notebook unico | `credicresa_pip_credito_oro` |

`job` y `pip` se insertan despues de la fuente como en los ejemplos solicitados;
`credito` representa el conjunto de entidades y `oro` su capa terminal. El catalogo
es la excepcion literal indicada por el cliente. No se crean jobs por tabla.

El pipeline recrea Bronce vacio con los tipos del diccionario, materializa snapshots
Parquet de Plata y Oro y expone vistas. Plata y Oro son temporales: no hay reglas
funcionales aprobadas ni productos certificados. Una estructura vacia valida el
bootstrap, no la ingesta de registros reales. No se fabrican registros de negocio.

Los tipos presentes prevalecen: VARCHAR -> STRING, BIT -> BOOLEAN, FLOAT(53) ->
DOUBLE, DATETIME -> TIMESTAMP_NTZ; DECIMAL conserva precision y escala. Ante ausencia
de tipo y clasificacion explicita numerica, el resolvedor usa DECIMAL(10,2); ante
clasificacion alfanumerica usa STRING. Sin evidencia usa STRING explicito y advierte.
No deduce categorias por nombres. Una discrepancia con el diccionario actual bloquea
el despliegue: primero debe reconciliarse mediante el flujo existente
`credicresa_actualizar_tipos.py`. El ejemplo de defaults no se ejecuta como migracion.

El SQL ilustrativo activa ANSI y usa CAST, evitando convertir silenciosamente una
entrada invalida a NULL. Los textos como `00123` conservan los ceros iniciales.

## 4. Automatizacion y recuperacion

`plan` valida rutas, diccionario y cobertura; escribe
`.deployment/cresa_credito_plan.json` y `.deployment/cresa_credito_plan.yml`.
No consulta Databricks ni requiere perfil. El despliegue valida perfil/host, exige
warehouse y cluster Unity Catalog, y rechaza un catalogo ya existente: no adopta
objetos ajenos ni sobrescribe un despliegue previo.

Antes de crear recursos escribe `.deployment/cresa_credito.json` con identificador
de propiedad, destino y lista exacta de objetos. Agrega IDs de job/run conforme los
recibe. Crea esquemas, volumenes y tabla Delta; importa el notebook renderizado en
una subcarpeta exclusiva del despliegue; crea un solo job sin horario, concurrencia
uno y sin reintentos; ejecuta y espera su resultado. El pipeline falla ante vistas
preexistentes o rutas Parquet existentes. No permite sobrescribir datos manualmente
volviendo a lanzar el job. El bootstrap no es un cargador periodico.

El pipeline es un recurso notebook de Jobs, no un objeto Lakeflow Declarative.
Crear/eliminar el pipeline significa importar/eliminar ese notebook. Esta decision
mantiene la arquitectura Parquet del paquete; no se simula un pipeline DLT.

La reversa usa exclusivamente el manifiesto. Valida nombres, destino, comentarios
de propiedad, etiquetas del job, contenido del notebook y ausencia de runs activos;
consulta inventarios paginados. Un error de API no equivale a ausencia. Elimina el
job, las vistas Oro -> Plata -> Bronce y el notebook. Luego vuelve a inventariar.
Conserva auditoria, volumenes, archivos, esquemas, catalogo y carpeta Workspace.
La reversa no es una purga ni restaura datos previos: este despliegue exige catalogo
nuevo y no reemplaza objetos existentes.

Ante fallo parcial: conservar el manifiesto y LOG, revisar el run, esperar su fin,
ejecutar `-WhatIf` y posteriormente `-Execute`. Un timeout local no cancela el run.
No hay rollback automatico ni reintentos de mutaciones con resultado desconocido.
Tras una respuesta perdida al crear el job, la reversa lo reconcilia por su marca.
No borrar el manifiesto para forzar otro deploy: los recursos retenidos requieren
una decision de retencion/limpieza antes de reutilizar el nombre de catalogo.

El bloqueo `.deployment/cresa_credito.lock` evita concurrencia local. Si el proceso
termina abruptamente, verificar primero que no siga activo y revisar el run remoto
antes de retirar manualmente el bloqueo. No coordina operadores en otras maquinas;
reservar una ventana exclusiva de despliegue/reversion.

## 5. LOG y errores

Ambos scripts anexan eventos JSON Lines UTF-8 a
`scripts/cresa_credito_desplegar.log`: fecha UTC, modo, fase, run de correlacion,
estado, codigo y recurso/entidad. El registro incluye las 34 entidades, seleccion,
exclusiones, fases SQL, IDs de statement/job/run y resultado de verificacion.
Los errores devuelven codigo distinto de cero; el mensaje no copia respuestas
crudas de autenticacion/API ni valores de registros. Los secretos no forman parte
del YAML, manifiesto, comandos generados ni LOG; se usa perfil OAuth externo.

Ejemplo de evento (ilustrativo):

```json
{"utc":"2026-09-09T22:00:00+00:00","run":"<correlacion>","mode":"plan","phase":4,"status":"EXCLUDED","code":"CONTRACT_VALIDATED","entity":"sis_peticiones","selected":false,"attributes":10}
```

Los eventos de capa/entidad remotos quedan en
`cresa_credito.credicresa_control_bronce.credicresa_ejecuciones_bronce`; el LOG local
contiene el run de Jobs para correlacionarlos. Se registra STARTED, VERIFIED o FAILED
por entidad/capa. Gold se marca TEMPORAL_NO_CERTIFICADO. Conservar ambos rastros bajo
la politica de acceso y retencion del cliente.

## 6. Verificacion

Local: sintaxis PowerShell/Python, 34 YAML/451 atributos, nombres y limite de 43
objetos, pruebas de seleccion, defaults, propiedad, paginacion y rechazo ante runs
activos. No se ejecuta SQL remoto durante la validacion local.

Remota al desplegar: notebook compara nombres/tipos/conteos por cada vista; se exige
SUCCESS del job; el orquestador confirma las 42 vistas propias, la tabla Delta y
los tres volumenes. La reversa comprueba ausencia de vistas, job y notebook antes
de declarar REVERSE_VERIFIED, manteniendo el inventario de recursos conservados.
No se declara exito remoto a partir de pruebas locales.

Requisitos de operacion: Python del entorno del paquete con `requirements.txt`,
Databricks CLI autenticada mediante OAuth, warehouse autorizado y cluster con Unity
Catalog y DBR 13.3 LTS o posterior. El operador necesita permisos para crear el
catalogo, esquemas, volumenes, tabla/vistas y job, usar el warehouse/cluster e importar
notebooks. Las credenciales de almacenamiento permanecen administradas en Databricks.

## 7. Sentencias PowerShell parametrizadas

```powershell
$base = 'C:\desa\git\cresa\cre_implementacion'
$scripts = Join-Path $base 'pre_productiva\scripts'
$python = Join-Path $base 'pre_productiva\.venv\Scripts\python.exe'

# Validacion y plan local, sin llamadas remotas.
& (Join-Path $scripts 'cresa_credicresa_desplegar.ps1') -BasePath $base -PythonPath $python

# Sustituir placeholders por valores autorizados. No incluir tokens.
$destino = @{
    BasePath       = $base
    PythonPath     = $python
    AuthName       = '<PERFIL_OAUTH>'
    WorkspaceUrl   = 'https://<HOST_DATABRICKS>'
    WorkspacePath  = '/Workspace/Users/<USUARIO>/cresa_credito'
    SqlWarehouseId = '<WAREHOUSE_ID>'
}

# Crear y verificar: hasta 14 entidades; omitir Entities usa seleccion alfabetica.
& (Join-Path $scripts 'cresa_credicresa_desplegar.ps1') @destino `
    -ClusterId '<CLUSTER_ID_UC>' -TimeoutSeconds 7200 -Deploy

# Alternativa de seleccion (sustituye la anterior, no ejecutar ambos despliegues).
# & (Join-Path $scripts 'cresa_credicresa_desplegar.ps1') @destino `
#     -ClusterId '<CLUSTER_ID_UC>' -Entities 'cat_almacen','sis_peticiones' -Deploy

# Plan local de reversa: requiere manifiesto de un despliegue.
& (Join-Path $scripts 'cresa_credicresa_reversar.ps1') -BasePath $base -PythonPath $python

# Verificacion remota de propiedad; no elimina recursos.
& (Join-Path $scripts 'cresa_credicresa_reversar.ps1') @destino -WhatIf

# Eliminacion explicita y verificacion posterior; conserva datos y auditoria.
& (Join-Path $scripts 'cresa_credicresa_reversar.ps1') @destino -Execute
```

Referencia tecnica: [Parquet en volumenes](https://docs.databricks.com/aws/en/query/formats/parquet),
[Jobs API](https://docs.databricks.com/api/jobs/v2/job).

## Evidencia local de esta entrega

Validacion realizada el 2026-09-10: 15 pruebas del piloto satisfactorias;
34 contratos y 451 atributos; sintaxis PowerShell y Python correctas. Plan
local ejecutado desde PowerShell: 14 entidades y 43 objetos consultables.
Se genero el LOG local. No se desplegaron ni revirtieron objetos remotos.
La integracion remota y los datos reales quedan pendientes de validacion.

Los scripts ausentes se reconstruyeron en esta revision; el transporte usa
Databricks CLI directamente. No se ejecutaron las pruebas de los scripts
historicos ausentes. Si una preparacion falla antes de crear la carpeta
Workspace, la reversa falla de forma conservadora al consultar esa carpeta:
requiere reconciliacion manual del manifiesto y de los recursos parciales.
Un error API nunca se interpreta como ausencia de recursos.
## Destino autorizado el 2026-09-10

La ejecucion actual usa CatalogName=credicresa, explicitamente solicitado por el
cliente. CatalogName es parametrico y se conserva cresa_credito como valor por
defecto. El notebook deriva catalogo y rutas de volumen del plan inyectado.
El manifiesto se separa por catalogo: .deployment/cresa_credito_credicresa.json.
La reversa de este destino requiere -CatalogName credicresa y los mismos host/ruta.

SourceRoot es alias de BasePath; GitWorkspacePath es alias de WorkspacePath.
LogPath selecciona el LOG local. Authenticate reutiliza OAuth y solo inicia login
si la sesion no es valida. Sin ClusterId el job de notebook usa serverless.
OutputRoot, DatabricksUser, WorkspaceId, ResourceId y GitHubRepository son datos
operativos de referencia; no crean infraestructura cloud ni sincronizan GitHub.
Se comprobo identidad, workspace y metastore antes de esta ejecucion. El artefacto
que se importa procede del paquete local validado. Parametros de esta entrega:
config/credicresa_despliegue.yml. El LOG solicitado esta en tests/credicresa_desplegar.log.

Referencia serverless: https://docs.databricks.com/aws/en/dev-tools/bundles/examples

## Despliegue remoto verificado: 2026-09-10

Catalogo credicresa. Job 770511509944147, run 689244546482216: SUCCESS.
42 vistas verificadas (14 entidades en Bronce, Plata y Oro), 1 tabla Delta de
control, 3 volumenes y 4 esquemas. Ejecucion serverless, cero filas de negocio.
Oro permanece TEMPORAL_NO_CERTIFICADO. No se ejecuto ninguna reversa.

LOG: tests/credicresa_desplegar.log.
Resultado: tests/credicresa_despliegue_resultado.json.
Manifiesto: .deployment/cresa_credito_credicresa.json, con huella del notebook.
Auditoria remota: credicresa.credicresa_control_bronce.credicresa_ejecuciones_bronce.
Run de auditoria: 1b76d52a6f644275a18dec139bee7970.
La verificacion externa termino con DEPLOY_VERIFIED el 2026-09-10 20:47:09 UTC.
