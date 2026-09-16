> **Revisión de consistencia — 2026-09-16.** Antecedente documental o evidencia fechada. Para nombres, capacidad, estado de acceso y operación actuales prevalecen el [estado vigente](ESTADO_VIGENTE.md), la [arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y el [informe extendido](20_CRESA_MDM_ANALISIS_EXTENDIDO.md). Los comandos, límites y resultados anteriores del contenido siguiente se conservan como antecedentes; no acreditan un despliegue MDM ni una ejecución actual.

Asunto: Respuesta a observaciones técnicas sobre el framework ETL / Lógica de Negocio CRESA

Estimado equipo de la Oficina de Datos de CRESA:

Gracias por la revisión y por las observaciones técnicas remitidas sobre el documento “Lineamientos de Desarrollo y Esquematización de Procesos ETL / Lógica de Negocio”.

Luego de analizarlas, confirmamos que las siete observaciones son pertinentes y serán incorporadas al framework. En consecuencia, aceptamos iniciar el proceso formal de actualización del documento y de sus artefactos técnicos asociados.

La versión 1.1 incorpora los siguientes ajustes:

1. Inclusión de `load_strategy` en la configuración Silver, separando el modo lógico de carga de su mecanismo de implementación.
2. Tipificación de SCD para dimensiones Gold, incluyendo soporte declarativo para SCD Tipo 1 y Tipo 2.
3. Ampliación del contrato Gold con un ejemplo de consumo JDBC para RELEX, contemplando SQL Warehouse, OAuth M2M, Service Principal, permisos de Unity Catalog y controles de red.
4. Adopción de Jobs API 2.1 como versión mínima para todos los jobs nuevos; los jobs existentes en 2.0 se mantendrán hasta ejecutar un plan controlado de migración.
5. Condicionamiento de Lakeflow Designer a la verificación de disponibilidad y aprobación en `adbdlh01`; Jobs API 2.1+ será el mecanismo base cuando dicha capacidad no esté habilitada.
6. Incorporación de una política declarativa `schema_evolution`, con tratamiento explícito de adición, eliminación, renombramiento y cambios de tipo.
7. Definición del RACI para la creación, revisión, aprobación y publicación de YAML, junto con contratos JSON Schema versionados y validación obligatoria tanto en CI como al inicio de cada ejecución.

La actualización mantiene el principio de catálogo único de CRESA y no modifica las ingestas Bronze existentes. Los cambios aplican a los nuevos desarrollos Silver y Gold y a las nuevas fuentes Bronze que sean aprobadas posteriormente.

Como siguiente paso, proponemos revisar conjuntamente la versión 1.1 y cerrar las decisiones de plataforma que requieren confirmación de CRESA: disponibilidad de Lakeflow Designer, identidad técnica de RELEX, reglas de conectividad, versión efectiva de Jobs API soportada por las herramientas institucionales y responsables nominales del RACI.

Hasta completar esta revisión y obtener la aprobación formal correspondiente, el documento conservará el estado “borrador para revisión interna / no socializable”.

Atentamente,

Equipo de Arquitectura e Ingeniería de Datos  
Programa DataOn — CRESA
