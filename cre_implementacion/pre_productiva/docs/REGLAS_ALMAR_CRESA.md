> **Revisión de consistencia — 2026-09-16.** Antecedente documental o evidencia fechada. Para nombres, capacidad, estado de acceso y operación actuales prevalecen el [estado vigente](ESTADO_VIGENTE.md), la [arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y el [informe extendido](20_CRESA_MDM_ANALISIS_EXTENDIDO.md). Los comandos, límites y resultados anteriores del contenido siguiente se conservan como antecedentes; no acreditan un despliegue MDM ni una ejecución actual.

# Reglas ALMAR aplicables a CRESA: análisis e implementación

Fecha: 2026-09-07. Alcance: paquete de pruebas cresa/credicresa, 34 entidades y
451 atributos. El análisis usa archivos locales; no verifica el estado actual del
catálogo productivo ni representa una aprobación de reglas por sus propietarios.

## Conclusión

Se pueden trasladar los patrones de diagnóstico, contrato tipado y control de
certificación. No hay respaldo para trasladar reglas acuícolas ni para usar las
llaves actuales como restricciones de negocio. Se implementan alertas agregadas,
sin limpieza destructiva, deduplicación, exclusión de registros o certificación.
Silver y Gold siguen siendo snapshots temporales. Gold vuelve a diagnosticar su
entrada Silver: no transforma estos snapshots en maestros Cliente/Producto.

## Evidencia revisada

- ALMAR: `C:/desa/git/almar/Fase 3/templates_ingenieria/config/silver/silver_entity_template.yml`:
  not_null, duplicate_natural_key, valid_date_parse, normalización, homologación y flag_only.
- ALMAR: `C:/desa/git/almar/Fase 3/templates_ingenieria/config/gold/gold_product_template.yml`:
  contrato, unique_key, allowed_values, reject_from_product y estado temporal.
- `C:/desa/git/almar/Fase 3/contratos_yaml/silver_entity.schema.json` contiene en
  realidad un contrato titulado CRESA con catálogo dlh_cresa. La ubicación ALMAR
  no prueba autoría ni aplicabilidad; no se copia sobre el contrato del paquete cresa.
- CRESA: [conformación y riesgos](../../documentacion_insumo/analisis_caracterizacion/03_silver_cleansing_riesgos.md),
  [productos temporales](../../documentacion_insumo/analisis_caracterizacion/04_gold_temporal_dataproducts.md)
  e [hipótesis pendientes](../../documentacion_insumo/analisis_caracterizacion/06_hipotesis_validacion.md).
- CRESA: [lineamientos v1.1](CRESA_LINEAMIENTOS_ETL_LOGICA_NEGOCIO_v1.1.docx),
  [diccionario](../sql/02_credicresa_catalogos.sql), contratos activos de ingesta y
  [correcciones de llaves](PIPELINE_POR_FUENTE.md).

Las cifras históricas sobre SIAC/Dynamics/Producto documentadas en esos insumos
no se presentan como mediciones de las 34 entidades actuales. No se encontraron
muestras de registros de este lote durante esta revisión; se dispone de estructura,
metadatos e hipótesis. Las pruebas usan datos sintéticos.

## Matriz de decisión

| Patrón o regla | Respaldo en CRESA | Implementación / decisión |
|---|---|---|
| not_null | Llaves declaradas en los YAML; SV_CLI_001 | Diagnóstico de nulos en cada llave candidata. No se asume que el DDL impone NOT NULL. |
| duplicate_natural_key / unique_key | Llaves YAML; SV_CLI_002 y riesgos de falsa duplicidad | Conteo de miembros de grupos duplicados para llaves primarias/naturales completas. flag_only en ambas capas. |
| Llave pendiente | cat_solicitud_estados y cre_solicitante tienen pending_definition | PENDING explícito; no se usa llave natural alternativa ni se infiere por nombre. |
| empty_source_alert | SV_CLI_006 / catálogo de reglas CRESA | Aplicación técnica a cada entrada de las 34 entidades. WARNING si vacía en carga; EXPECTED_EMPTY en bootstrap. |
| trim_strings / empty_string_as_null | Estandarización de ALMAR | Detectar cadena vacía o solo espacios, y espacios exteriores. No cambiar identificaciones, payloads ni otros textos. |
| Longitud de texto | 258 atributos CHAR/VARCHAR con tamaño explícito en DDL | Diagnóstico de longitud en caracteres; no truncar ni imponer semántica de bytes/collation de SQL Server. Es una adaptación técnica CRESA, no una regla acuícola. |
| Contrato de columnas/tipos | 34 YAML/451 atributos del diccionario | Mantener validación estricta existente, bloqueante ante drift o conversiones inválidas. No inferir fechas por nombre. |
| valid_date_parse | Solo se conocen tipos y fechas STRING sin formato de origen aprobado | Conversiones para tipos temporales explícitos ya las controla el runtime. No añadir parser para STRING ni asumir formato/zona. |
| Homologación de estados / allowed_values | Hay catálogos, pero no mapeo aprobado de equivalencias/dominios | Pendiente. No asumir ACTIVO de ALMAR, 0/1 de estado, ni relaciones por sufijo _id. |
| Surrogate key / MERGE / SCD | Llaves sin restricciones en DDL; algunas candidatas sospechosas | Pendiente de granularidad, secuencia y estrategia de borrados. No activar incrementalidad. |
| unit_normalization / VIN / EAN | Reglas Producto descritas; columnas/fuentes de ese dominio fuera de credicresa | No aplicables a las 34 entidades actuales. Requieren catálogo de unidades, es_vehiculo y fuentes Producto. |
| valid_format teléfono/email/identificación | CRESA los plantea, sin especificación completa por tipo/país | Pendiente de formatos y clasificación; no declarar válida/inválida una identificación con regex genérica. |
| address_standardization | CRESA documenta discrepancias, sin referencia geográfica/motor aprobado | Pendiente; el diagnóstico de espacios no equivale a normalizar domicilios. |
| Reconciliación CreditLimit/cupo, cupo_disponible | CRESA documenta decisión de Crédito pendiente y fuentes Dynamics/SIAC | No implementar fórmula ni escoger fuente de verdad. |
| flag_contactable / opt-in | Escalera de mora pendiente; consentimiento sin fuente | No inferir ni fabricar campos o consentimiento. |
| Gold reject_from_product / certificación | No hay contrato aprobado de producto ni autoridad de llaves | Mantener temporal y reglas pendientes. Un PASS técnico no habilita consumidores. |

## Semántica implementada

[Política](../config/quality/credicresa.yml) versionada, validada localmente y al
inicio del runtime. Solo acepta las seis familias implementadas y acción flag_only;
rechaza acciones/campos no soportados. Es un contrato operativo reducido, no la
implementación integral de JSON Schema normativos para maestros del documento v1.1.

[Motor](../lib/credicresa_quality.py): genera expresiones desde columnas tipadas y
llaves declaradas, sin ejecutar SQL arbitrario recibido en YAML. Una consulta agrega
los controles de nulos/texto por entidad y hasta dos consultas agrupan duplicados.
Para llave compuesta, un nulo en cualquier componente marca la fila como incompleta.
Las llaves incompletas se excluyen del conteo de duplicados. Se cuentan todos los
miembros del grupo repetido, no solo las filas que sobran. No se agrupa concatenando
valores ni se eliminan duplicados.

Las llaves no son restricciones probadas: `empresa` en `cub_cobro_cuotas` y
`com_cub_cobros_cuotas_cresa_tb`, o `ultimo_numero` en `cfg_controlsecuencia`, ilustran
por qué sus advertencias no deben convertirse automáticamente en rechazos.

TRIM diagnostica espacios ordinarios; no valida todos los separadores Unicode.
NULL se diferencia de cadena vacía. Las longitudes son señales de revisión en
caracteres, no una emulación de límites en bytes de la base original. No hay
umbrales de calidad o ponderaciones inventados.

Estados: PASS, WARNING, PENDING, EXPECTED_EMPTY y NOT_EVALUATED. En tabla vacía,
las reglas sobre filas quedan NOT_EVALUATED; no se anuncia calidad aprobada por
cero infracciones. BUSINESS_CERTIFICATION queda siempre PENDING.

## Persistencia y operación

[Integración](../lib/credicresa_medallion.py) antes de publicar Silver/Gold. La
pasada dry_run devuelve resumen de advertencias/pendientes sin escribir. Ambas
pasadas requieren control plane. Los datos conservan su contrato de 451 atributos,
sin agregar flags a cada fila ni cambiar las 136 vistas y 1804 comprobaciones.
Esta versión produce diagnóstico agregado; no implementa cuarentena o trazabilidad
individual de registros.

Nueva tabla Delta: `cresa.audit01.credicresa_quality_results`, creada por el SQL de
control plane existente. Registra ejecución, período, lote, capa, entidad, regla,
columnas, total, afectados, estado y acción. No guarda identificaciones, payloads,
valores de llaves ni muestras personales. Los resultados de reglas se vinculan por
run_id/layer/entity a `credicresa_medallion_runs`; solo ese estado SUCCEEDED confirma
publicación de la entidad. Si falla después del diagnóstico, este puede quedar
registrado con la ejecución FAILED. No hay transacción atómica entre esas tablas.
Un error de evaluación o escritura de auditoría detiene el Job; WARNING no lo detiene.
La reversa sigue conservando auditoría y volúmenes.

[Inventario por entidad](CRESA_REGLAS_COBERTURA.csv): 34 entidades, 451 atributos,
994 resultados previstos por capa (incluyen pendientes y alertas de tabla), 1988
entre Silver y Gold en ejecución completa con persistencia. No son 1988 reglas de
negocio aprobadas ni infracciones detectadas. El filtro de tablas reduce cobertura.

## Validación y límites

43 pruebas locales satisfactorias. Las consultas de diagnóstico se ejecutaron en
SQLite sobre datos sintéticos (duplicados compuestos, nulos, blancos, longitud y
fuente vacía); la integración Spark usa dobles de prueba. Esto comprueba semántica
SQL portable y contrato, no ejecución real en Databricks, permisos ni rendimiento.
Se preservan validaciones de las 34 entidades y 451 atributos. No se ejecutó Deploy,
reversa ni consulta remota. El SQL nuevo debe aplicarse al próximo despliegue antes
de ejecutar las tareas de Silver/Gold.

## Siguiente ampliación fundamentada

1. Medir el lote real y revisar llaves con resultados WARNING; confirmar granularidad.
2. Versionar reglas concretas de formato, catálogo y reconciliación con sus fuentes
   y responsables. Añadir pruebas de casos válidos, inválidos y excepciones.
3. Incorporar fuentes Cliente/Producto y contratos Gold específicos cuando estén
   disponibles en el alcance autorizado; definir SCD, vigencia y rechazos por producto.
4. Activar certificación/publicación solo cuando exista definición y aprobación
   de cada producto. Las configuraciones actuales rechazan esa activación automática.
