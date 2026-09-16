> **Revisión de consistencia — 2026-09-16.** Antecedente documental o evidencia fechada. Para nombres, capacidad, estado de acceso y operación actuales prevalecen el [estado vigente](ESTADO_VIGENTE.md), la [arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y el [informe extendido](20_CRESA_MDM_ANALISIS_EXTENDIDO.md). Los comandos, límites y resultados anteriores del contenido siguiente se conservan como antecedentes; no acreditan un despliegue MDM ni una ejecución actual.

# Limpieza de objetos de credito_cresa y cresa

Entrada Bash: `scripts/cresa_eliminar_catalogos.sh`.
Implementación única: `scripts/cresa_eliminar_catalogos.py`, que reutiliza el
cliente CLI, autenticación, SQL y registro operativo de `credicresa_cli.py`.

## Uso

Desde el paquete, con Bash/Git Bash y el entorno .venv preparado:

```bash
bash scripts/cresa_eliminar_catalogos.sh
bash scripts/cresa_eliminar_catalogos.sh --execute
```

La primera llamada crea `.deployment/eliminar_catalogos_plan.json` mediante
inventario remoto. La segunda vuelve a inventariar y exige los mismos objetos,
identificadores y sentencias. Se rechazan objetos desconocidos, vistas sin marca
del proyecto, volúmenes externos, funciones, pipelines relacionados o runs activos.
No cancela ejecuciones. Los argumentos opcionales son `--profile`,
`--workspace-url` y `--warehouse`; CRESA_PYTHON permite elegir el intérprete.

## Alcance destructivo

Elimina las vistas y tablas reconocidas de credicresa, las tablas de auditoría,
los volúmenes administrados **con sus datos**, los esquemas vacíos inventariados
y el Job del proyecto. Esta operación es más amplia que la reversa habitual que
conserva auditoría y volúmenes. No es transaccional y no constituye un respaldo.
Conserva los catálogos `credito_cresa` y `cresa`, así como `information_schema`.
Las carpetas y notebooks del Workspace no son objetos internos de esos catálogos
y quedan conservados. No elimina objetos de otros clientes.

DROP SCHEMA usa RESTRICT; no hay CASCADE. El script no permite indicar otros
catálogos. Para repetir tras un fallo parcial, revisar el resultado, crear un nuevo
plan y ejecutar sobre los objetos restantes; un plan anterior ya no coincide.

## Evidencia

Plan y resultado: `.deployment/eliminar_catalogos_plan.json` y
`.deployment/eliminar_catalogos_resultado.json`. El LOG histórico se conserva en
`C:/desa/git/cresa/tests/cresa_desplegar.log`. La verificación final vuelve a
inventariar ambos catálogos y los Jobs; solo al completarla se invalida el Job y
el inventario activo en `.deployment/credicresa.json`.

Pruebas locales: seis casos de protección (catálogo ajeno, tabla desconocida,
marca de propiedad, volumen externo, identidad cambiada y DROP SCHEMA RESTRICT),
sintaxis Bash y validación de los 34 contratos/451 atributos satisfactorias.

## Resultado remoto ejecutado — 2026-09-07

Ejecución del .sh con --execute completada y verificada a las 22:05:59 UTC
(17:05:59 America/Guayaquil). Rastro: db061c36908c4557b56beb6537836c72.
Se eliminaron 70 vistas, 4 tablas Delta, 3 volúmenes administrados, 7 esquemas y
el Job 777730216940602. Las 84 sentencias SQL terminaron satisfactoriamente.
La consulta posterior verificó cero esquemas de usuario en credito_cresa y cresa,
y ausencia de Jobs del proyecto. No se detectaron pipelines relacionados.
Permanecen ambos catálogos e information_schema; las carpetas Workspace se conservaron.
Se invalidaron job_id y verified_objects en el manifiesto activo para evitar cargas
por período contra objetos eliminados. Un nuevo despliegue será necesario para cargar.

## Eliminación final solicitada — 2026-09-07

Completada y verificada a las 22:13:11 UTC (17:13:11 America/Guayaquil).
Se eliminaron los catálogos credito_cresa y cresa mediante DROP CATALOG RESTRICT;
sus information_schema desaparecieron con los catálogos. No se utilizó CASCADE.
Se eliminaron recursivamente estas carpetas del Workspace:

- /Users/wilsonyanez@hotmail.com/credicresa
- /Users/wilsonyanez@hotmail.com/credito_cresa (carpeta Git del Workspace)
- /Users/wilsonyanez@hotmail.com/cresa
- /Users/wilsonyanez@hotmail.com/Cresa (incluye Persona y Producto)

La consulta posterior verificó ausencia de los dos catálogos y de las cuatro
carpetas. No se modificó el repositorio GitHub ni los archivos locales del proyecto.
Procedimiento: scripts/cresa_eliminar_final.py. Evidencia:
.deployment/eliminacion_final_resultado.json. Rastro:
63ce5fca8155486d944f82f521038a3a, registrado en el LOG operativo.
El manifiesto local queda con workspace_owned=false y catalog_removed=true.
Este estado reemplaza el resultado previo que conservaba catálogos y carpetas.

Referencia: https://learn.microsoft.com/en-au/azure/databricks/catalogs/manage-catalog
