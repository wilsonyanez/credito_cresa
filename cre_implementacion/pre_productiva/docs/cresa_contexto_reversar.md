> **Revisión de consistencia — 2026-09-16.** Antecedente documental o evidencia fechada. Para nombres, capacidad, estado de acceso y operación actuales prevalecen el [estado vigente](ESTADO_VIGENTE.md), la [arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y el [informe extendido](20_CRESA_MDM_ANALISIS_EXTENDIDO.md). Los comandos, límites y resultados anteriores del contenido siguiente se conservan como antecedentes; no acreditan un despliegue MDM ni una ejecución actual.

# Contexto CRESA — reversa del proyecto credicresa

Actualizado: 2026-09-07. Consolida el alcance del script y la vista previa probada. No acredita una reversa destructiva ejecutada.

## Identidad y entradas

- Cliente/catálogo: cresa.
- Proyecto/esquema: credicresa; base cresa.credicresa.
- Entrada solicitada: scripts/cresa_reversar.ps1.
- Implementación única: scripts/credicresa_reversar.ps1 → scripts/credicresa_cli.py.
- Lanzador externo: C:/desa/git/cresa/scripts/credicresa_reversar.ps1.
- Manifiesto: pre_productiva/.deployment/credicresa.json.
- Creación: [cresa_contexto_desplegar.md](cresa_contexto_desplegar.md).

cresa_reversar.ps1 delega los parámetros en el script del proyecto; no duplica la lógica de eliminación.

## Alcance predeterminado (sin DropProjectSchema)

| Acción con Execute | Objeto |
|---|---|
| Eliminar job propio | job_credicresa_ingesta_periodo; ID del manifiesto |
| Eliminar 34 vistas fuente | cresa.credicresa.<entidad> |
| Eliminar 34 vistas Bronze | cresa.bronze.credicresa_<entidad> |
| Eliminar carpeta del proyecto | /Workspace/Users/wilsonyanez@hotmail.com/cresa/credicresa |

Se conservan catálogo, esquemas, volúmenes, snapshots Parquet, cuatro tablas Delta y dos vistas de auditoría, logs y archivos locales. La carpeta del cliente /Workspace/Users/wilsonyanez@hotmail.com/cresa y los demás proyectos permanecen. No se usa DROP SCHEMA CASCADE ni DROP CATALOG. La opción DropProjectSchema se detalla al final.

Es una reversa de objetos consultables, job y artefactos; no una purga de datos ni una reversión transaccional de períodos.

## Protecciones y correcciones

1. Comprobar perfil OAuth, host y destino del manifiesto.
2. Exigir un despliegue verificado con job y las 68 vistas registradas.
3. Verificar etiquetas client=cresa, source=credicresa y managed_by=pre_productiva; el job también declara project=credicresa.
4. Rechazar la operación si hay runs activos.
5. Comparar el manifiesto con el inventario exacto de los 34 YAML.
6. Leer cresa_owner.json de la carpeta con AUTO, corrigiendo la exportación RAW rechazada.
7. Consultar el inventario completo y paginado; exigir VIEW y comentario de propiedad CRESA credicresa pre_productiva en cada objeto presente.
8. Completar todas las comprobaciones antes de eliminar.
9. Exigir Execute para eliminar; sin él, o con WhatIf, emitir solo el plan.
10. Comprobar SUCCEEDED de cada sentencia y el resultado CLI; consultar al terminar la ausencia de vistas, job, carpeta y, si se solicitó, esquema.

Esta delimitación reemplaza la reversa anterior que contemplaba eliminar esquemas compartidos. Execute y WhatIf son excluyentes. Un objeto ajeno, un manifiesto incompleto o un run activo detiene el proceso. La ausencia de job o vistas solo se acepta tras consultar inventarios completos; un fallo de consulta no se interpreta como ausencia.

La reversa no es atómica. Si Execute falla a mitad, revisar log, manifiesto e inventario antes de continuar; no forzar una eliminación global ni asumir idempotencia completa. Un timeout local puede requerir consultar el estado de la sentencia remota.

## Comandos y parámetros

Desde C:/desa/git/cresa/cre_implementacion/pre_productiva/scripts:

```powershell
# Vista previa de solo lectura remota; registra el plan en el LOG.
.\cresa_reversar.ps1 -WhatIf -AuthName "cresa-dev" -WorkspaceUrl "https://dbc-d87ef1e3-6c95.cloud.databricks.com" -WorkspacePath "/Workspace/Users/wilsonyanez@hotmail.com/cresa/credicresa" -SqlWarehouseId "61b8feaf5fbd763d"

# Reversa efectiva: ejemplo, no ejecutado en esta sesión.
.\cresa_reversar.ps1 -Execute -AuthName "cresa-dev" -WorkspaceUrl "https://dbc-d87ef1e3-6c95.cloud.databricks.com" -WorkspacePath "/Workspace/Users/wilsonyanez@hotmail.com/cresa/credicresa" -SqlWarehouseId "61b8feaf5fbd763d"
```

| Parámetro | Uso / valor predeterminado |
|---|---|
| WhatIf | Vista previa; también es el modo cuando se omite Execute |
| Execute | Elimina exclusivamente los objetos identificados |
| AuthName | cresa-dev |
| WorkspaceUrl | https://dbc-d87ef1e3-6c95.cloud.databricks.com |
| WorkspacePath | /Workspace/Users/wilsonyanez@hotmail.com/cresa/credicresa |
| SqlWarehouseId | 61b8feaf5fbd763d |
| PythonPath | .venv/Scripts/python.exe del paquete con requirements.txt instalado |

La reversa no acepta Authenticate. Si se requiere renovar OAuth, usar antes la CLI:

```powershell
databricks auth login --host "https://dbc-d87ef1e3-6c95.cloud.databricks.com" --profile "cresa-dev"
```

No se guardan credenciales en el proyecto. La vista previa consulta metadatos y registra el plan local; no elimina objetos ni inicia un run del pipeline.

## Prueba histórica del alcance inicial

La vista previa terminó correctamente el 2026-09-07. Identificó el job 1008661299620101, las 68 vistas y la carpeta del proyecto, y enumeró los datos y la auditoría que se conservarían.

- Rastro de vista previa: 29ebd279833e41a59301737b2e866b16.
- Log: C:/desa/git/cresa/tests/cresa_desplegar.log, modo REVERSE.
- Despliegue de referencia: run 1094185962105919, SUCCESS, 68 vistas y 902 comprobaciones de tipos.
- Auditoría del despliegue: 34 entidades, 451 atributos registrados, cero errores y cero filas de negocio (bootstrap).
- Pruebas locales del trabajo implementado: 20; incluyen rechazo de jobs ajenos, bloqueo con runs activos y vista previa con lecturas exclusivamente.

No se ejecutó Execute. Los objetos preparatorios del catálogo anterior credito_cresa y su carpeta no se eliminaron y están fuera del manifiesto activo. Los archivos de sql contienen definiciones, no registros de períodos.

C:/desa/git/cresa/tests solo recibe el LOG; no se copian scripts ni archivos ejecutados a test. La actualización de estos contextos no reejecuta la reversa.

Ver [evidencia detallada](RESULTADO_DESPLIEGUE_CRESA.md) y [procedimiento general](../README.md).

## Ampliación: eliminación del esquema del proyecto

La opción DropProjectSchema, combinada con Execute, amplía la reversa para eliminar
cresa.credicresa.data y el esquema cresa.credicresa. El volumen administrado contiene
los snapshots fuente: eliminarlo también afecta sus datos. Se conserva el catálogo
cresa, los esquemas compartidos Medallion, sus volúmenes y la auditoría del proyecto.

Antes de modificar, comprueba el inventario de hasta 68 vistas y la propiedad del job/carpeta, el comentario
del esquema, el inventario exacto del volumen data y la ausencia de funciones u otras
tablas en credicresa. Se rechazan inventarios desconocidos o consultas fallidas.
DROP SCHEMA usa RESTRICT, nunca CASCADE. La operación no es transaccional.

El pipeline de este paquete es el job de tres tareas; no existe un objeto Lakeflow
Declarative independiente administrado por este despliegue. No se eliminan pipelines
ni jobs de otros proyectos, ni objetos históricos fuera del manifiesto.

Desde C:/desa/git/cresa/scripts, o desde scripts del paquete:

```powershell
.\credicresa_reversar.ps1 -DropProjectSchema -WhatIf -AuthName "cresa-dev" -WorkspaceUrl "https://dbc-d87ef1e3-6c95.cloud.databricks.com" -WorkspacePath "/Workspace/Users/wilsonyanez@hotmail.com/cresa/credicresa" -SqlWarehouseId "61b8feaf5fbd763d"

# Eliminación efectiva; sustituye WhatIf por Execute:
.\credicresa_reversar.ps1 -DropProjectSchema -Execute -AuthName "cresa-dev" -WorkspaceUrl "https://dbc-d87ef1e3-6c95.cloud.databricks.com" -WorkspacePath "/Workspace/Users/wilsonyanez@hotmail.com/cresa/credicresa" -SqlWarehouseId "61b8feaf5fbd763d"
```

Sin DropProjectSchema se mantiene la reversa anterior, que conserva también el esquema fuente
y su volumen. Execute y WhatIf son excluyentes. PythonPath permite elegir Python con
las dependencias del paquete; al omitirlo se usa el entorno .venv del paquete.

Referencias: [DROP SCHEMA](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-ddl-drop-schema)
y [DROP VOLUME](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-ddl-drop-volume).

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
