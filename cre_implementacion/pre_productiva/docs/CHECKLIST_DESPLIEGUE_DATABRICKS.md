# Checklist vigente — CRESA

Revisión: 2026-09-16. Aplicar junto con [README del paquete](../README.md).

## Revisión local

- Validar 34 YAML / 451 atributos contra `sql/02_credicresa_catalogos.sql`.
- Validar sintaxis Python/PowerShell y archivos JSON/YAML activos.
- Verificar los ocho nombres de maestros/conformados en [arquitectura](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) e [informe](20_CRESA_MDM_ANALISIS_EXTENDIDO.md).
- Revisar resultados y limitaciones de pruebas en [validación](VALIDACION_CONSOLIDACION.md); no declarar aprobada la suite completa mientras falten sus módulos antiguos.
- Comprobar ausencia de secretos y consistencia de rutas.
- Ejecutar el lanzador sin `-Deploy` ni `-Resume` para un plan local.

## Despliegue del piloto, únicamente cuando se solicite

- Confirmar perfil/destino/manifiesto y no adoptar un catálogo remoto existente.
- Seleccionar hasta 14 entidades entre los 34 contratos.
- Verificar esquemas `audit01`, `landing`, `bronze`, `silver`, `gold`; no crear esquema por proyecto.
- Verificar job `JOB_CRE_00_CARGA_DATOS_CREDI_CRESA`, notebook por ejecución y propiedad de objetos.
- Para selección de 14 entidades, comprobar 42 vistas y una tabla Delta de auditoría.
- Registrar IDs/resultados remotos en manifiesto y LOG; un bootstrap vacío no acredita carga real.
- Inspeccionar la reversa solo cuando proceda; no ejecutarla como parte del despliegue.

## Implementación futura del MDM

- Usar catálogos `dev_dlh_cresa` / `dlh_cresa` y los nombres del documento 17.
- Mantener 1,2 TB declarados en `devstgdlh02` como capacidad sin restricción en esta etapa.
- Habilitar volúmenes/destinos, permisos y entrega de snapshots consistentes.
- Resolver identidad de cliente, grano SKU/unidad, consentimiento, EAN y reglas de crédito.
- Conservar Parquet para datos del paquete y Delta para control; certificar únicamente con evidencia de reglas aprobadas.

Esta revisión documental y su publicación Git no ejecutan ningún despliegue ni reversa.
