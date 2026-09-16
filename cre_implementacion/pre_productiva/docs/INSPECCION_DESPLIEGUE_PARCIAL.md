> **Revisión de consistencia — 2026-09-16.** Antecedente documental o evidencia fechada. Para nombres, capacidad, estado de acceso y operación actuales prevalecen el [estado vigente](ESTADO_VIGENTE.md), la [arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y el [informe extendido](20_CRESA_MDM_ANALISIS_EXTENDIDO.md). Los comandos, límites y resultados anteriores del contenido siguiente se conservan como antecedentes; no acreditan un despliegue MDM ni una ejecución actual.

# Inspección remota de solo lectura — 2026-09-14

Destino: `cresa`, carpeta `/Workspace/Users/wilsonyanez@hotmail.com/.git/cresa/credicresa`.
Manifiesto: `.deployment/cresa_credito_cresa.json`, estado `PREPARING`.
Marca verificada del catálogo y volúmenes: `CRESA_PILOT_02df316c074d48269a92372289a7795e`.

Se consultaron las APIs GET de catálogo, esquemas, tablas, volúmenes, Workspace y jobs.

- Existen los cinco esquemas de aplicación y tres volúmenes Medallion.
- Existe una tabla en audit01; landing, bronze, silver y gold no tienen tablas/vistas.
- No existe job de CRESA en el inventario de jobs accesibles.
- La carpeta notebooks está vacía.
- Configuración y librerías están importadas; SQL contiene únicamente los tres
  archivos iniciales: 00_create_credicresa_database.sql, 00_create_test_environment.sql
  y 01_create_control_plane.sql.
- El siguiente archivo por orden de importación, 02_credicresa_catalogos.sql,
  no figura en Workspace. El log original solo registra FileNotFoundError,
  sin ruta ni traceback; la causa exacta no está demostrada.

No se crearon, ejecutaron ni eliminaron objetos durante esta inspección.
No se alteró el manifiesto. La recuperación debe conservar la estructura existente,
verificar los archivos ya presentes y completar importación, notebook y job.
El lanzador actual no reanuda automáticamente: bloquea un manifiesto existente.

## Recuperación autorizada y verificada

El 2026-09-14 se ejecutó la nueva opción `-Resume`, con autorización explícita.
La comprobación previa verificó 49 archivos existentes. Se completó la importación
y se creó `JOB_CRE_00_CARGA_DATOS_CREDI_CRESA` (job 504115177941507).
La ejecución 758333090815966 y su tarea 969163049067170 finalizaron en SUCCESS.
El notebook devolvió VERIFIED, 42 vistas, 0 filas y Gold TEMPORAL_NO_CERTIFICADO.
La comprobación final registró 43 objetos (42 vistas y auditoría) y actualizó
el manifiesto a VERIFIED el 2026-09-14 a las 21:38:01 UTC.
No se eliminaron objetos ni se reemplazaron los archivos previamente verificados.
El estado parcial descrito arriba queda como evidencia histórica.
