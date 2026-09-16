# Estado vigente e índice documental — CRESA

Consolidación: **2026-09-16**. Este documento establece cómo interpretar los documentos del repositorio. La publicación Git reúne cambios locales de código, contratos, documentación e insumos; no equivale a un despliegue en Databricks.

## Definiciones que prevalecen

1. [Arquitectura MDM, volúmenes y nomenclatura](17_CRESA_DATABRICK_DEFINICION_INICIAL.md).
2. [Cobertura productiva, brechas e insumos por atributo](20_CRESA_MDM_ANALISIS_EXTENDIDO.md).
3. [README operativo del paquete](../README.md), [pipeline](PIPELINE_POR_FUENTE.md) y [checklist](CHECKLIST_DESPLIEGUE_DATABRICKS.md).
4. [Mapa funcional de maestros](../../documentacion_insumo/analisis_caracterizacion/01_mapa_maestros.md), con diagnóstico histórico y nombres vigentes por ambiente.

| Ambiente | Dominio | Silver | Gold |
|---|---|---|---|
| Producción | Cliente | `dlh_cresa.silver.dw_cresa_cliente_conformado` | `dlh_cresa.gold.dw_cresa_maestro_cliente` |
| Producción | Producto | `dlh_cresa.silver.dw_cresa_producto_conformado` | `dlh_cresa.gold.dw_cresa_maestro_producto` |
| Desarrollo | Cliente | `dev_dlh_cresa.silver.dw_cresa_cliente_conformado` | `dev_dlh_cresa.gold.dw_cresa_maestro_cliente` |
| Desarrollo | Producto | `dev_dlh_cresa.silver.dw_cresa_producto_conformado` | `dev_dlh_cresa.gold.dw_cresa_maestro_producto` |

Proyecto: `mdm_clientes_productos`; fuente de crédito: `credicresa`. Desarrollo: **devstgdlh02, 1,2 TB disponibles declarados, sin restricción de espacio para esta etapa**. Los volúmenes propuestos separan paquetes originales, documentos, datos Medallion, cuarentena y evidencia. Datos del paquete en Parquet; control plane Delta. Las tablas Delta productivas existentes se conservan.

## Estado técnico y remoto

- Existen 34 contratos locales con 451 atributos derivados del diccionario. El piloto usa `cresa`, hasta 14 entidades, 42 vistas y una auditoría Delta; no construye los maestros MDM.
- Los lanzadores vigentes son `cresa_credicresa_desplegar.ps1` y `cresa_credicresa_reversar.ps1`. El job es `JOB_CRE_00_CARGA_DATOS_CREDI_CRESA`. Los scripts antiguos mencionados en históricos no son puntos de entrada.
- La plantilla por período tiene cinco tareas; su runtime es distinto del bootstrap del piloto. No se declara disponible un lanzador de carga de planos retirado.
- La evidencia del 15 de septiembre midió 15 tablas Delta y cuatro entradas Parquet. La consulta de metadatos del 16 confirmó 14 objetos y ausencia de los dos nombres exactos de maestros Gold. Son cortes y alcances diferentes.
- El acceso USE CATALOG a `dev_dlh_cresa` fue confirmado en el contexto 03. Las referencias anteriores a rechazo describen intentos históricos; no se han demostrado permisos de escritura ni materializado todos los destinos MDM.
- Persisten brechas de consentimiento, EAN, identidad VTEX/Venta Smart, reglas de crédito y calidad. Las etiquetas de certificación presentes en diseños anteriores no son una máquina de estados aprobada; debe acordarse antes de implementar.
- La referencia a DAMA-DMBOK3 permanece pendiente de verificación documental; no se afirma certificación de conformidad con una edición no consultada.

## Cambios reunidos en esta publicación

Se incorporan los contratos renombrados a `credicresa_*`, sus tipos de origen/Spark, runtime Medallion y calidad, lanzadores y biblioteca del piloto, protección de manifiestos y recuperación, notebooks/SQL/job, pruebas locales y evidencia de consultas. Se incluyen los documentos 17/20 y sus insumos de procesos. Se corrigen rutas, se retiran comandos obsoletos de las guías operativas y se sincronizan los ocho nombres de maestros/conformados.

Las configuraciones históricas y pruebas dependientes de módulos retirados se conservan identificadas; no se inventan sustitutos para hacer pasar validaciones. [Resultados de validación y limitaciones](VALIDACION_CONSOLIDACION.md).

## Tratamiento de documentos e insumos

| Clase | Interpretación |
|---|---|
| Vigente | Instrucciones y decisiones actuales; prevalecen los documentos 17/20 para MDM |
| Análisis funcional | Contenido de diseño útil; métricas y ausencia de fuentes conservan su fecha de corte; se aplica la ampliación 17/20 |
| Antecedente / contexto | Resultados y propuestas anteriores, conservados para trazabilidad; sus comandos no son operación vigente |
| Evidencia fechada | JSON, Markdown, LOG y exportaciones de metadatos/código; no se reescriben para aparentar un estado actual |
| Insumo original Office/CSV | Entrega recibida o inventario derivado, no contrato operativo de nombres vigente; se mantiene su contenido y procedencia |
| Archivo técnico previo | `construccion_tecnica_previa/`, solo lectura conforme a AGENTS.md; no ejecutar ni desplegar |

Los Excel `12`–`19` y el DOCX de lineamientos se conservan como originales. En particular, `17_CRESA_DATABRICK_DEFINICION_INICIAL-R1.xlsx` contiene ejemplos anteriores ajenos al MDM: la adaptación CRESA vigente es el Markdown 17. Alterar los originales invalidaría hashes y referencias de evidencia; la consistencia se establece mediante esta precedencia explícita. El documento `01_mapa_maestros.md` está en `documentacion_insumo/analisis_caracterizacion/`; se enlaza desde docs sin duplicarlo.

## Inventario documental completo

Cada entrada identifica su vigencia. Las carpetas técnicas de código no forman parte de este inventario de documentos. Los archivos originales se incluyen en Git cuando forman parte de los cambios locales autorizados.

| Documento | Clase |
|---|---|
| [AGENTS.md](<../../AGENTS.md>) | Vigente |
| [CONTEXTO_CRESA.md](<../../CONTEXTO_CRESA.md>) | Antecedente / contexto |
| [MEMORIA_CHAT.md](<../../MEMORIA_CHAT.md>) | Antecedente / contexto |
| [README.md](<../../README.md>) | Vigente |
| [construccion_tecnica_previa/README.md](<../../construccion_tecnica_previa/README.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/CHECKLIST_INGESTA_CRESA_GENERAL_cat_sector.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/CHECKLIST_INGESTA_CRESA_GENERAL_cat_sector.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/CHECKLIST_cat_estadoverificacion_cumplimiento.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/CHECKLIST_cat_estadoverificacion_cumplimiento.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/CHECKLIST_cat_tipoverificacion_cumplimiento.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/CHECKLIST_cat_tipoverificacion_cumplimiento.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/INDICE_ENTREGABLES_cat_estadoverificacion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/INDICE_ENTREGABLES_cat_estadoverificacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/INDICE_ENTREGABLES_cat_tipoverificacion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/INDICE_ENTREGABLES_cat_tipoverificacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/INGEST_credito_cresa_cat_estadoverificacion_run.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/INGEST_credito_cresa_cat_estadoverificacion_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/INGEST_credito_cresa_cat_nacionalidad_run.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/INGEST_credito_cresa_cat_nacionalidad_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/INGEST_credito_cresa_cat_sector_run.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/INGEST_credito_cresa_cat_sector_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/INGEST_credito_cresa_cat_sexo_run.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/INGEST_credito_cresa_cat_sexo_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_almacen.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_almacen.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_canton.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_canton.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_estadocivil.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_estadocivil.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_estadoverificacion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_estadoverificacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_modelo_aprobador.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_modelo_aprobador.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_modelo_calificacion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_modelo_calificacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_nacionalidad.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_nacionalidad.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_nivelinstruccion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_nivelinstruccion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_origen.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_origen.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_parroquia.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_parroquia.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_profesion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_profesion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_provincia.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_provincia.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_sector.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_sector.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_sector_riesgo_geocerca.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_sector_riesgo_geocerca.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_sexo.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_sexo.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_solicitud_estados.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_solicitud_estados.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_tipoverificacion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_tipoverificacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_tipovinculo.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cat_tipovinculo.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cobro_tipo_credito_tb.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cobro_tipo_credito_tb.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_com_cub_cobros_cuotas_cresa_tb.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_com_cub_cobros_cuotas_cresa_tb.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicitante.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicitante.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicitante_mina.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicitante_mina.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicitud.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicitud.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicitud_bitacora.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicitud_bitacora.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicituddomicilio.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicituddomicilio.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicitudlaboral.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cre_solicitudlaboral.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_cub_cobro_cuotas.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_cub_cobro_cuotas.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_lcr_cuentas.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_lcr_cuentas.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_lcr_graduacion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_lcr_graduacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_lcr_reserva_cuotas.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_lcr_reserva_cuotas.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_sec_usuario.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_sec_usuario.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_sis_peticiones.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_sis_peticiones.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/README_ver_respuesta_proveedor.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/README_ver_respuesta_proveedor.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/RECOMENDACIONES_cat_estadoverificacion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/RECOMENDACIONES_cat_estadoverificacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/RECOMENDACIONES_cat_tipoverificacion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/RECOMENDACIONES_cat_tipoverificacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/RESUMEN_EJECUTIVO_cat_estadoverificacion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/RESUMEN_EJECUTIVO_cat_estadoverificacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/implementacion_por_entidad/docs/RESUMEN_EJECUTIVO_cat_tipoverificacion.md](<../../construccion_tecnica_previa/implementacion_por_entidad/docs/RESUMEN_EJECUTIVO_cat_tipoverificacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/prototipos_databricks/README.md](<../../construccion_tecnica_previa/prototipos_databricks/README.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/CHECKLIST_credito_cresa_cat_modelo_aprobador.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/CHECKLIST_credito_cresa_cat_modelo_aprobador.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/CHECKLIST_credito_cresa_cat_modelo_calificacion.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/CHECKLIST_credito_cresa_cat_modelo_calificacion.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/CHECKLIST_credito_cresa_cat_origen.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/CHECKLIST_credito_cresa_cat_origen.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/CHECKLIST_credito_cresa_cat_solicitud_estados.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/CHECKLIST_credito_cresa_cat_solicitud_estados.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/CHECKLIST_credito_cresa_cat_tipovinculo.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/CHECKLIST_credito_cresa_cat_tipovinculo.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_canton_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_canton_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_estadocivil_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_estadocivil_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_modelo_aprobador_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_modelo_aprobador_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_modelo_calificacion_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_modelo_calificacion_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_nacionalidad_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_nacionalidad_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_nivelinstruccion_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_nivelinstruccion_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_origen_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_origen_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_parroquia_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_parroquia_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_provincia_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_provincia_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_sexo_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_sexo_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_solicitud_estados_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_solicitud_estados_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_tipoverificacion_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_tipoverificacion_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_tipovinculo_run.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/INGEST_credito_cresa_cat_tipovinculo_run.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/docs/template_documentacion_pipeline.md](<../../construccion_tecnica_previa/templates_ingenieria_original/docs/template_documentacion_pipeline.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/scripts/README.md](<../../construccion_tecnica_previa/templates_ingenieria_original/scripts/README.md>) | Archivo técnico previo — solo lectura |
| [construccion_tecnica_previa/templates_ingenieria_original/scripts/README_create_jobs.md](<../../construccion_tecnica_previa/templates_ingenieria_original/scripts/README_create_jobs.md>) | Archivo técnico previo — solo lectura |
| [documentacion_insumo/README.md](<../../documentacion_insumo/README.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/00_resumen_ejecutivo_caracterizacion.md](<../../documentacion_insumo/analisis_caracterizacion/00_resumen_ejecutivo_caracterizacion.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/01_mapa_maestros.md](<../../documentacion_insumo/analisis_caracterizacion/01_mapa_maestros.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/02_bronze_relevante.md](<../../documentacion_insumo/analisis_caracterizacion/02_bronze_relevante.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/03_silver_cleansing_riesgos.md](<../../documentacion_insumo/analisis_caracterizacion/03_silver_cleansing_riesgos.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/04_gold_temporal_dataproducts.md](<../../documentacion_insumo/analisis_caracterizacion/04_gold_temporal_dataproducts.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/06_hipotesis_validacion.md](<../../documentacion_insumo/analisis_caracterizacion/06_hipotesis_validacion.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/07_diagramas_arquitectura_dominios.md](<../../documentacion_insumo/analisis_caracterizacion/07_diagramas_arquitectura_dominios.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/08_alineacion_dominios_as_is_fase3.md](<../../documentacion_insumo/analisis_caracterizacion/08_alineacion_dominios_as_is_fase3.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/09_plan_ingesta_almacenamiento_lakehouse.md](<../../documentacion_insumo/analisis_caracterizacion/09_plan_ingesta_almacenamiento_lakehouse.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/10_metodologia_lakehouse_gobierno_fase3.md](<../../documentacion_insumo/analisis_caracterizacion/10_metodologia_lakehouse_gobierno_fase3.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/11_convenciones_nombramiento_databricks.md](<../../documentacion_insumo/analisis_caracterizacion/11_convenciones_nombramiento_databricks.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/README.md](<../../documentacion_insumo/analisis_caracterizacion/README.md>) | Análisis funcional / referencia |
| [documentacion_insumo/analisis_caracterizacion/bronze_relevante.csv](<../../documentacion_insumo/analisis_caracterizacion/bronze_relevante.csv>) | Insumo original Office/CSV |
| [documentacion_insumo/analisis_caracterizacion/candidatas_secundarias.csv](<../../documentacion_insumo/analisis_caracterizacion/candidatas_secundarias.csv>) | Insumo original Office/CSV |
| [documentacion_insumo/analisis_caracterizacion/matriz_tablas_dominios_scoring.csv](<../../documentacion_insumo/analisis_caracterizacion/matriz_tablas_dominios_scoring.csv>) | Insumo original Office/CSV |
| [documentacion_insumo/imagenes/diagramas/README.md](<../../documentacion_insumo/imagenes/diagramas/README.md>) | Análisis funcional / referencia |
| [pre_productiva/AGENTS.md](<../AGENTS.md>) | Vigente |
| [pre_productiva/README.md](<../README.md>) | Vigente |
| [pre_productiva/docs/12_Procesos_Credito_Cartera.xlsx](<12_Procesos_Credito_Cartera.xlsx>) | Insumo original Office/CSV |
| [pre_productiva/docs/13_Procesos_Producto_Cliente.xlsx](<13_Procesos_Producto_Cliente.xlsx>) | Insumo original Office/CSV |
| [pre_productiva/docs/14_Maestro-Cliente.xlsx](<14_Maestro-Cliente.xlsx>) | Insumo original Office/CSV |
| [pre_productiva/docs/15_cresa_datos.xlsx](<15_cresa_datos.xlsx>) | Insumo original Office/CSV |
| [pre_productiva/docs/16_Procesos_JOBs_Entidades_Dominios.xlsx](<16_Procesos_JOBs_Entidades_Dominios.xlsx>) | Insumo original Office/CSV |
| [pre_productiva/docs/17_CRESA_DATABRICK_DEFINICION_INICIAL-R1.xlsx](<17_CRESA_DATABRICK_DEFINICION_INICIAL-R1.xlsx>) | Insumo original Office/CSV |
| [pre_productiva/docs/17_CRESA_DATABRICK_DEFINICION_INICIAL.md](<17_CRESA_DATABRICK_DEFINICION_INICIAL.md>) | Vigente |
| [pre_productiva/docs/18_CRESA_CREDITO_INVENTARIO.xlsx](<18_CRESA_CREDITO_INVENTARIO.xlsx>) | Insumo original Office/CSV |
| [pre_productiva/docs/19_CRESA_REGLAS_COBERTURA.xlsx](<19_CRESA_REGLAS_COBERTURA.xlsx>) | Insumo original Office/CSV |
| [pre_productiva/docs/20_CRESA_MDM_ANALISIS_EXTENDIDO.md](<20_CRESA_MDM_ANALISIS_EXTENDIDO.md>) | Vigente |
| [pre_productiva/docs/CHECKLIST_DESPLIEGUE_DATABRICKS.md](<CHECKLIST_DESPLIEGUE_DATABRICKS.md>) | Vigente |
| [pre_productiva/docs/CONTEXTO_03_MAESTROS.md](<CONTEXTO_03_MAESTROS.md>) | Antecedente / contexto |
| [pre_productiva/docs/CRESA_CREDITO_INVENTARIO.csv](<CRESA_CREDITO_INVENTARIO.csv>) | Insumo original Office/CSV |
| [pre_productiva/docs/CRESA_CREDITO_SIETE_FASES.md](<CRESA_CREDITO_SIETE_FASES.md>) | Antecedente / contexto |
| [pre_productiva/docs/CRESA_LINEAMIENTOS_ETL_LOGICA_NEGOCIO_v1.1.docx](<CRESA_LINEAMIENTOS_ETL_LOGICA_NEGOCIO_v1.1.docx>) | Insumo original Office/CSV |
| [pre_productiva/docs/CRESA_REGLAS_COBERTURA.csv](<CRESA_REGLAS_COBERTURA.csv>) | Insumo original Office/CSV |
| [pre_productiva/docs/DATABRICKS_CONNECT.md](<DATABRICKS_CONNECT.md>) | Vigente |
| [pre_productiva/docs/ESTADO_VIGENTE.md](<ESTADO_VIGENTE.md>) | Vigente |
| [pre_productiva/docs/INSPECCION_DESPLIEGUE_PARCIAL.md](<INSPECCION_DESPLIEGUE_PARCIAL.md>) | Antecedente / contexto |
| [pre_productiva/docs/LIMPIEZA_CATALOGOS_CRESA.md](<LIMPIEZA_CATALOGOS_CRESA.md>) | Antecedente / contexto |
| [pre_productiva/docs/MEDALLION_CRESA.md](<MEDALLION_CRESA.md>) | Antecedente / contexto |
| [pre_productiva/docs/NOTIFICACION_ENTREGA_LINEAMIENTOS_CRESA.md](<NOTIFICACION_ENTREGA_LINEAMIENTOS_CRESA.md>) | Antecedente / contexto |
| [pre_productiva/docs/PIPELINE_POR_FUENTE.md](<PIPELINE_POR_FUENTE.md>) | Vigente |
| [pre_productiva/docs/REGLAS_ALMAR_CRESA.md](<REGLAS_ALMAR_CRESA.md>) | Antecedente / contexto |
| [pre_productiva/docs/RESPUESTA_FORMAL_OBSERVACIONES_CRESA.md](<RESPUESTA_FORMAL_OBSERVACIONES_CRESA.md>) | Antecedente / contexto |
| [pre_productiva/docs/RESULTADO_DESPLIEGUE_CRESA.md](<RESULTADO_DESPLIEGUE_CRESA.md>) | Antecedente / contexto |
| [pre_productiva/docs/VALIDACION_CONSOLIDACION.md](<VALIDACION_CONSOLIDACION.md>) | Vigente |
| [pre_productiva/docs/cresa_contexto_desplegar.md](<cresa_contexto_desplegar.md>) | Antecedente / contexto |
| [pre_productiva/docs/cresa_contexto_reversar.md](<cresa_contexto_reversar.md>) | Antecedente / contexto |
| [pre_productiva/tests/contexto_03/entidades_por_dominio.md](<../tests/contexto_03/entidades_por_dominio.md>) | Evidencia fechada |
| [pre_productiva/tests/contexto_03/procesos_fuentes.csv](<../tests/contexto_03/procesos_fuentes.csv>) | Insumo original Office/CSV |
| [pre_productiva/tests/contexto_03/remoto/MEDICION_FUENTES.md](<../tests/contexto_03/remoto/MEDICION_FUENTES.md>) | Evidencia fechada |
