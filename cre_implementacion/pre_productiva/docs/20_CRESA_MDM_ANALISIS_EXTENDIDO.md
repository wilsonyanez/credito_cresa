# 20 — CRESA: análisis extendido para MDM de clientes y productos

Fecha: **2026-09-16**. Alcance: diseño, contraste con producción mediante lectura de metadatos y revisión de evidencia de ingesta. No se ejecutaron ETL, transferencias ni escrituras remotas.

## 1. Dictamen de arquitectura

La capacidad declarada de **1,2 TB en devstgdlh02** permite abordar todas las entidades de esta etapa sin restricción de espacio. Las brechas que condicionan la publicación son de cobertura funcional, claves, calidad y reglas de negocio. La [definición inicial actualizada](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) especifica volúmenes, directorios, gobierno y nombres del proyecto `mdm_clientes_productos` para CRESA.

Existen insumos productivos para identidad/contacto, producto, jerarquía comercial y cartera. **En la verificación del 2026-09-16 (E4), los dos maestros con los nombres de diseño vigentes no estaban implementados:** UC devolvió que `dlh_cresa.gold.dw_cresa_maestro_cliente` y `dlh_cresa.gold.dw_cresa_maestro_producto` no existen. Esta conclusión se limita a esos nombres exactos; no demuestra inexistencia de cualquier solución MDM bajo otro nombre.

El MDM necesita construcción propia: resolver identidad, consolidar fuentes, aplicar supervivencia, separar grano SKU/unidad, completar insumos faltantes y certificar. Las dimensiones productivas existentes no equivalen a maestros certificados. Los 34 YAML de CrediCresa son contratos locales y no representan por sí solos la cobertura completa de ambos dominios.

### 1.1 Nombres de maestros por ambiente y nivel Medallion

Se adopta la definición del [mapa de maestros](../../documentacion_insumo/analisis_caracterizacion/01_mapa_maestros.md) para Producción y su correspondencia en Desarrollo, conforme a la definición suministrada por CRESA. El archivo se encuentra en `documentacion_insumo/analisis_caracterizacion/01_mapa_maestros.md`; no se encontró una copia en `pre_productiva/docs` al realizar esta actualización.

| Ambiente | Dominio | Conformación previa — Silver | Maestro — Gold |
|---|---|---|---|
| Producción | Cliente | `dlh_cresa.silver.dw_cresa_cliente_conformado` | `dlh_cresa.gold.dw_cresa_maestro_cliente` |
| Producción | Producto | `dlh_cresa.silver.dw_cresa_producto_conformado` | `dlh_cresa.gold.dw_cresa_maestro_producto` |
| Desarrollo | Cliente | `dev_dlh_cresa.silver.dw_cresa_cliente_conformado` | `dev_dlh_cresa.gold.dw_cresa_maestro_cliente` |
| Desarrollo | Producto | `dev_dlh_cresa.silver.dw_cresa_producto_conformado` | `dev_dlh_cresa.gold.dw_cresa_maestro_producto` |

Silver corresponde a la conformación previa y Gold a la publicación del maestro. Entre ambientes cambia únicamente el catálogo; se conservan los nombres de esquema y objeto. Esta definición sustituye la propuesta previa de prefijar estos cuatro objetos con `mdm_clientes_productos_` y añadirles el sufijo de capa. El documento 17 recoge la misma matriz. `mdm_clientes_productos` sigue identificando el proyecto, sus volúmenes y su operación.

La nomenclatura define los destinos; no cambia los resultados de existencia registrados en E4. Esta actualización es documental y no verifica nuevamente ni crea objetos en Desarrollo o Producción.

## 2. Evidencia, fechas y criterios de estado

| Código | Evidencia | Qué permite afirmar |
|---|---|---|
| E1 | [Mapa funcional](../../documentacion_insumo/analisis_caracterizacion/01_mapa_maestros.md) | Atributos y brechas de diseño; porcentajes y conteos son históricos |
| E2 | [Procesos y fuentes Excel](../tests/contexto_03/procesos_fuentes.csv), [21 referencias por dominio](../tests/contexto_03/entidades_por_dominio.md) | Archivo, hoja y fila; 5 referencias Cliente y 16 Producto; incluye entradas, intermedias y salidas |
| E3 | [Medición del 2026-09-15](../tests/contexto_03/remoto/MEDICION_FUENTES.md), [metadatos](../tests/contexto_03/remoto/fuentes_metadata.json) | 15 tablas Delta y 4 rutas Parquet con conteos en esa fecha |
| E4 | [Metadatos UC del 2026-09-16](../tests/contexto_04/verificacion_final_uc_mdm.json) | Existencia/formato/columnas de 14 objetos; ausencia de 2 nombres exactos; sin nuevos conteos |
| E5 | [SQL Persona](../tests/contexto_03/remoto/dlh_cresa/PERSONA_DIM/carga_dw_cresa_persona_dim_sql.txt), [SQL Producto](../tests/contexto_03/remoto/dlh_cresa/PRODUCTO_DIM/carga_dw_cresa_producto_dim_sql.txt), [base Producto](../tests/contexto_03/remoto/dlh_cresa/PRODUCTO_DIM/carga_temp_producto_dim_sql.txt) | Dependencias y reglas implementadas en el código exportado; no ejecución ni garantía de calidad |
| E6 | [Acceso a Desarrollo](../tests/contexto_03/remoto/revision_acceso_desarrollo.json) | USE CATALOG resuelto; no prueba permisos de escritura |

**SI:** existencia verificada por API o lectura de datos fechada. **NO:** ausencia comprobada de un nombre exacto. **BRECHA:** insumo no identificado en el material revisado o regla aún no implementada; no equivale a ausencia exhaustivamente demostrada en todo el lake. **DOCUMENTAL:** referencia sin verificación física actual. La presencia de columnas no garantiza valores ni calidad.

Los intentos iniciales de consulta desde un subproceso fallaron por la red del sandbox; se repitieron las consultas seleccionadas mediante la CLI de lectura autorizada. E4 conserva el resultado final. No se tomó `updated_at` como fecha de actualización del dato ni como watermark. No se consultaron filas personales.

## 3. Entidades que se utilizarán

La ruta preferida para esta etapa es recibir snapshots de las dimensiones/hechos productivos ya disponibles y conservar su linaje a las fuentes físicas. Reconstruir todos los procesos intermedios es una alternativa condicionada al cierre de dependencias; no se debe copiar cada tabla temporal como si fuese una fuente independiente.

### 3.1 Cliente: núcleo y enriquecimientos

Todos los nombres de la siguiente tabla pertenecen al catálogo `dlh_cresa`.

| Entidad | Estado | Función en el MDM y condición |
|---|---|---|
| `gold.dw_cresa_persona_dim` | SI, E4 | Núcleo: documento, nombre, contacto y dirección; depurar fila técnica y duplicados; confirmar vigencia |
| `bronze.d365_CustomersV3_OPT` | SI, E3; 808.211 filas | Fuente activa Dynamics en E5: CustomerAccount, VATNum, contacto y límite; preferida para reconstrucción |
| `bronze.customersv3` | SI, E4 | Fuente citada por E1; contiene CustomerAccount/CreditLimit; esquema observado distinto de OPT, sin VATNum en la respuesta. No intercambiar sin homologación |
| `gold.dw_cresa_persona_siac_dim` | SI, E4 | Puente candidato de cartera: PK_id_cod_cliente, numero_cedula, nombre y dirección; validar relación con el hecho |
| `gold.dw_cresa_cartera_saldos_fact` | SI, E4 | Saldo por fecha/cliente/operación y llaves de estado, atraso y mora; requiere corte y agregación aprobados |
| `gold.dw_cresa_estado_credito_dim` | SI, E4 | Catálogo PK_id_estado_credito → estado_credito |
| `gold.dw_cresa_dias_atraso_dim` | SI, E4 | PK_id_dias_atraso → dias_atraso e intervalos |
| `gold.dw_cresa_rango_mora_dim` | SI, E4 | pk_id_rango_mora → descripcion; no contiene por sí solo límites numéricos de rangos |
| `gold.dw_cresa_clasificacion_clientes_dim` | SI, E4 | cod_calificacion_cliente/unificada → clasificacion_clientes; validar que la semántica satisface segmento demográfico |
| `silver.base_concrecion_cliente` | SI estructura, E4 | Canal/origen por num_identificacion e id_fecha; 0 filas solo en evidencia histórica de julio, sin nuevo conteo |
| `bronze.AddressStates`, `bronze.AddressCities` | SI, E3 | Homologación geográfica; claves país/provincia/ciudad y validación de dirección |
| Parquet SIAC `genvtclientedirecciontelef_cresa`, `genmtelefono_cresa`, `genmpersona_cresa` | SI, E3 | Contacto/identidad auxiliar del proceso productivo; conservar secuencia, fecha y relación por persona |
| CrediCresa: solicitante, solicitud, domicilio, laboral, cuentas y catálogos de §6 | Contratos locales; producción no verificada individualmente | Completar crédito y atributos de cliente según contrato y fórmula; no generar integración externa |

El puente propuesto es `cartera.id_cliente → persona_siac.PK_id_cod_cliente → numero_cedula → persona.num_identificacion`. Es una **hipótesis de integración**, no una relación probada por igualdad de tipos. Requiere validación de cardinalidad, claves huérfanas y tasa de coincidencia. Dynamics usa `CustomerAccount` como `id_persona` y `VATNum` como `num_identificacion` en E5; cuenta y documento son identificadores diferentes.

### 3.2 Producto: núcleo, jerarquías y unidades

| Entidad de dlh_cresa | Estado | Función y condición |
|---|---|---|
| `gold.dw_cresa_producto_dim` | SI, E4 | Base de descripción, jerarquía y medidas; su grano incluye empresa, SKU, motor y chasis |
| `bronze.d365_ReleasedProductsV2` | SI, E3; 70.457 filas | Producto liberado: ItemNumber/dataAreaId, descripción, clasificaciones, ancho y profundidad |
| `bronze.d365_sums` | SI, E3; 8.637.632 filas | InventBatchId/InventSerialId y relación ItemId/dataAreaId; unidades de vehículos, no maestro SKU único |
| `bronze.CommercialHeirarchyCategories` | SI, E3 | Línea, grupo, subgrupo y capacidad; conservar grafía original |
| `bronze.ProductGroups` | SI, E3 | Categoría de producto |
| `bronze.InventPackagingGroups` | SI, E3 | Marca usada por SQL; no deducir significado del nombre técnico |
| `bronze.ProductLifecycleStates` | SI, E3 | Estado de ciclo; auxiliar del proceso existente |
| `bronze.ProductAttributeValuesV3` | SI, E3; 538.672 filas | Fuente EAV del proceso activo; diccionario y selección de atributo requeridos |
| `bronze.d365_productattributevaluesv3` | SI, E4 | Fuente EAV citada en E1; productnumber, attributename, valores tipados y unitofmeasure. Equivalencia con la anterior pendiente |
| `src.xls_comercial_categoria`, `src.xls_comercial_grupo_asistencia`, `src.xls_tipo_marca` | SI, E3 | Homologaciones comerciales versionadas; auxiliares si se reproduce toda la dimensión |
| Parquet `tbl_proveedores_mktpl` | SI, E3 | Enriquecimiento de proveedor del proceso existente; no atributo obligatorio de E1 |
| `staging.temp_dw_cresa_producto_dim_his` | SI, E4 | Entrada histórica efectiva de UNION; conservarla si se reconstruye la dimensión completa |
| `staging.temp_tipo_marca_web_dim`, `staging.temp_producto_anio_fabricacion_dim` | SI, E4 | Entradas adicionales de MERGE identificadas en E5; no estaban en las 21 referencias del Excel |
| `bronze.ProductReceiptLines`, `bronze.purchaseorderheadersv2` | SI, E3 | Recepción; dependencia auxiliar, no insumo obligatorio de los atributos del maestro |

### 3.3 Intermedias documentadas y reconstruibles

El Excel 13, hoja `Diciconario Azurian`, registra `staging.temp_persona_dim`, `staging.temp_provincia_dim`; el SQL añade `staging.temp_ciudad_dim` y `staging.tmp_telefonos_cresa`. Para Producto registra `temp_producto_dim`, `temp_marca_dim`, `temp_linea_dim`, `temp_grupo_dim`, `temp_subgrupo_dim`, `temp_categoria_producto_dim`, `temp_atributos_producto_dim`, `temp_ciclo_producto_dim`, `temp_capacidad_dim`, `temp_proveedores_mktpl_dim`, `temp_tipo_marca_dim`, `temp_producto_procedencia_dim`, `temp_tipo_producto_dim`, todas en `staging`. También registra la salida `silver.dw_cresa_fechas_recepcion_producto`.

Estas referencias tienen evidencia documental y código exportado, pero no se revalidó individualmente su existencia física en esta revisión. No son nuevas fuentes de negocio ni se suman a las 19 entradas físicas medidas. Para reconstrucción completa faltan productores de históricos y algunas intermedias, parámetros, reglas y dependencias recursivas del modelo de cartera. Para usar snapshots de Gold se necesitan contratos y corte consistente, sin reejecutar esas intermedias.

## 4. Detalle de fuentes SI implementadas con datos medidos

Conteos de E3 al **2026-09-15**, sin snapshot común y sin recontar el día 16. Son evidencia de datos existentes en ese corte, no frescura garantizada de todas las fuentes.



| Ruta | Archivos | Bytes | Filas |
|---|---:|---:|---:|
| `/Volumes/dlh_cresa/bronze/vol_bronze_siac/genvtclientedirecciontelef_cresa/` | 1 | 55935289 | 377482 |
| `/Volumes/dlh_cresa/bronze/vol_bronze_siac/genmtelefono_cresa/` | 1 | 63651703 | 2490209 |
| `/Volumes/dlh_cresa/bronze/vol_bronze_siac/genmpersona_cresa/` | 1 | 58803558 | 1131674 |
| `/Volumes/dlh_cresa/bronze/vol_bronze_metas_dwtanque_cresa/tbl_proveedores_mktpl/tbl_proveedores_mktpl.parquet` | 1 | 846397 | 55516 |

### Tablas fuente Delta administradas

| Tabla | Filas |
|---|---:|
| `dlh_cresa.bronze.AddressCities` | 234 |
| `dlh_cresa.bronze.d365_CustomersV3_OPT` | 808211 |
| `dlh_cresa.bronze.AddressStates` | 24 |
| `dlh_cresa.bronze.ProductReceiptLines` | 181291 |
| `dlh_cresa.bronze.purchaseorderheadersv2` | 115217 |
| `dlh_cresa.src.xls_comercial_categoria` | 28 |
| `dlh_cresa.src.xls_comercial_grupo_asistencia` | 31 |
| `dlh_cresa.bronze.ProductAttributeValuesV3` | 538672 |
| `dlh_cresa.bronze.CommercialHeirarchyCategories` | 8621 |
| `dlh_cresa.bronze.ProductGroups` | 133 |
| `dlh_cresa.bronze.ProductLifecycleStates` | 11 |
| `dlh_cresa.bronze.InventPackagingGroups` | 4361 |
| `dlh_cresa.bronze.d365_sums` | 8637632 |
| `dlh_cresa.bronze.d365_ReleasedProductsV2` | 70457 |
| `dlh_cresa.src.xls_tipo_marca` | 628 |


Las cuatro rutas suman **179.236.947 bytes y 4.054.881 filas**. No sumar estas filas como cantidad de clientes/productos: son entidades de distinto grano. Los tamaños de exportación de Delta siguen sin medirse. Esta limitación no cambia la decisión de capacidad del cliente.

## 5. Entidades NO implementadas y brechas necesarias

| Entidad o capacidad requerida | Diagnóstico | Insumo/acción para construirla |
|---|---|---|
| `dlh_cresa.gold.dw_cresa_maestro_cliente` | NO: nombre exacto ausente, E4 | Construir conformación, identidad y publicación con los nombres vigentes de §1.1 y del documento 17 |
| `dlh_cresa.gold.dw_cresa_maestro_producto` | NO: nombre exacto ausente, E4 | Construir maestro SKU y relación de unidades; no renombrar la dimensión actual como sustituto |
| Consentimiento por cliente/canal/finalidad | BRECHA: fuente no localizada, E1/E2/E5 | Entrega de eventos de aceptación/revocación con evidencia, fecha, canal, finalidad y llave de cliente |
| Identidad VTEX | BRECHA: integración no demostrada | Extracto customer_id, documento/identificador puente, origen y fecha; contrato del propietario |
| Cotizaciones Venta Smart | BRECHA: fuente/puente no demostrados | Cabecera de cotización, clave cliente, estado y fecha; confirmar definición del atributo agregado |
| Código EAN por SKU/variante/empaque | BRECHA: sin fuente identificada | Catálogo de códigos de barras del propietario, tipo, empaque, unidad comercial, vigencia y control de unicidad |
| Equivalencias de identidad y supervivencia MDM | BRECHA de implementación | Puente persistente de identificadores, regla de matching, excepciones, empates y decisión del steward |
| Certificación, owner y clasificación | BRECHA en los esquemas Gold inspeccionados | Registro de responsables y clasificación, reglas medibles y evidencia de aprobación |
| es_vehiculo y relación SKU/unidad | BRECHA de diseño MDM | Homologación de categoría/tipo de producto y relación de seriales; E5 usa Veh_moto como condición existente |
| Cupo disponible / contactabilidad | BRECHA de reglas | Fórmula oficial de Crédito con cupo, consumos, reservas, ajustes y corte; regla de contacto independiente de consentimiento |
| Dimensiones físicas completas | BRECHA de calidad, no tabla ausente | Ficha técnica/PIM/proveedor con medición y unidad por SKU; validación de cero/nulo/no aplicable |
| Canal/origen con datos | Estructura SI; población actual pendiente | Revalidar conteo y entregar eventos/relación con cliente y fecha; no imputar canal desde teléfono |

No se etiqueta una entidad como NO por no aparecer en un YAML, por fallo de permisos o por no encontrarla en una búsqueda parcial. Las ausencias de consentimientos/EAN/VTEX/Venta Smart se expresan como brechas del alcance inspeccionado, no como un inventario exhaustivo de todo Producción.

## 6. Cobertura de los 34 contratos CrediCresa

Inventario completo de nombres, sin equiparar contrato local a tabla productiva. Uso propuesto a confirmar por columnas/reglas: **núcleo** para solicitante/crédito; **referencia** para enriquecer; **auxiliar** para linaje o procesos; **condicional** sujeto a fórmula. Ninguno aporta por sí solo el maestro de Producto comercial.

| Entidad local | Uso propuesto para Cliente | Verificación productiva individual |
|---|---|---|
| `cat_almacen` | Referencia: tienda/almacén; no inferir canal preferido | Pendiente; contrato local disponible |
| `cat_canton` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_estadocivil` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_estadoverificacion` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_modelo_aprobador` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_modelo_calificacion` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_nacionalidad` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_nivelinstruccion` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_origen` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_parroquia` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_profesion` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_provincia` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_sector` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_sector_riesgo_geocerca` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_sexo` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_solicitud_estados` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_tipoverificacion` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_tipovinculo` | Referencia: catálogo de códigos/descripciones; aplicar solo con vínculo validado | Pendiente; contrato local disponible |
| `cat_usuario` | Auxiliar: operador del proceso; no cliente | Pendiente; contrato local disponible |
| `cfg_controlsecuencia` | Auxiliar técnico; no atributo del maestro | Pendiente; contrato local disponible |
| `cobro_tipo_credito_tb` | Referencia: tipos de crédito | Pendiente; contrato local disponible |
| `com_cub_cobros_cuotas_cresa_tb` | Condicional: cobros/cuotas; validar grano y corte | Pendiente; contrato local disponible |
| `cre_solicitante` | Núcleo: identificación, nombres, contacto y demografía | Pendiente; contrato local disponible |
| `cre_solicitante_mina` | Auxiliar: contraste de solicitante; semántica por validar | Pendiente; contrato local disponible |
| `cre_solicitud` | Núcleo: vínculo solicitante/crédito y fecha | Pendiente; contrato local disponible |
| `cre_solicitud_bitacora` | Auxiliar: trazabilidad de estados | Pendiente; contrato local disponible |
| `cre_solicituddomicilio` | Núcleo: dirección y relación con solicitud | Pendiente; contrato local disponible |
| `cre_solicitudlaboral` | Referencia: ocupación y domicilio laboral | Pendiente; contrato local disponible |
| `cub_cobro_cuotas` | Condicional: cobros/cuotas; evitar doble conteo | Pendiente; contrato local disponible |
| `lcr_cuentas` | Condicional: cuenta/línea de crédito para fórmula | Pendiente; contrato local disponible |
| `lcr_graduacion` | Condicional: evolución/calificación de crédito | Pendiente; contrato local disponible |
| `lcr_reserva_cuotas` | Condicional: reservas en fórmula de cupo | Pendiente; contrato local disponible |
| `sis_peticiones` | Auxiliar: trazabilidad de peticiones | Pendiente; contrato local disponible |
| `ver_respuesta_proveedor` | Auxiliar: verificación; no sustituye consentimiento | Pendiente; contrato local disponible |

E2 registra 34 menciones y 33 nombres únicos en la fila 2 del Excel 12: se repite `cat_estadoverificacion`. Coinciden literalmente **30 de los 34 contratos**. `cre_solicitudreferencia`, `sec_usuario` y `ver_transaccional_verificacion` aparecen allí y no tienen contrato del mismo nombre; `cat_usuario`, `cobro_tipo_credito_tb`, `com_cub_cobros_cuotas_cresa_tb` y `cub_cobro_cuotas` están en los YAML y no en esa fila. No asumir equivalencia sec_usuario/cat_usuario. El Excel 14 contiene jobs y transformaciones de extracción; su título no lo convierte en un diccionario final del maestro Cliente.

## 7. Insumos para poblar cada atributo de Cliente

Grano propuesto: una identidad de cliente, con identificador MDM estable y tabla de equivalencias por sistema/empresa/tipo de documento. Preservar ceros iniciales. Las cuentas múltiples pertenecen a relaciones, no a duplicados descartables.

| Atributo de diseño | Columna/insumo identificado | Transformación y condición de aceptación |
|---|---|---|
| `id_cliente` | Persona.id_persona/num_identificacion, Dynamics.CustomerAccount/VATNum, persona_siac.PK_id_cod_cliente/numero_cedula | Crear identificador estable y crosswalk; validar empresa, documento, duplicados, huérfanos y resolución manual |
| `num_identificacion` | Persona.num_identificacion y cod_tipo_identificacion; solicitante.identificacion como candidato local | Normalizar por tipo/país sin convertir a número ni mezclar documentos distintos |
| `nombre_completo` | Persona.des_nombre_completo; solicitante.nombre_1/nombre_2/apellido_1/apellido_2 | Fuente de autoridad y manejo de vacíos/alias; excluir fila técnica 00000 |
| `email` | Persona.des_email; Dynamics y solicitante.email | Validación de formato, fecha de contacto y supervivencia; los timestamps por contacto no están demostrados en Gold |
| `teléfono` | Persona.des_direccion_particular_telefono, des_telefono_trabajo, des_telefono2; Parquet SIAC | País/tipo, normalización, fecha y prioridad; preservar múltiples contactos y elegir principal con regla |
| `dirección_estandarizada` | Persona.des_direccion_particular y componentes país/provincia/ciudad/sector; AddressStates/Cities | Homologación geográfica y evidencia de dirección validada; no certificar por existir texto |
| `canal_origen` | base_concrecion_cliente.origen/num_identificacion/id_fecha | Snapshot poblado, calendario y primera interacción según regla aprobada |
| `canal_preferido` | base_concrecion_cliente.canal | Definir preferencia explícita o regla derivada; origen no implica preferencia |
| `segmento_demográfico` | clasificacion_clientes_dim.clasificacion_clientes y códigos; Persona.cod_calificacion | Aprobar semántica y join; una clasificación crediticia no es automáticamente demográfica |
| `credit_limit_dynamics` | customersv3.CreditLimit; OPT como fuente activa a homologar | Moneda, empresa, vigencia y prioridad; no sustituye cupo disponible |
| `estado_crédito` | cartera.id_estado_credito → estado_credito_dim.PK_id_estado_credito/estado_credito | Corte cartera.fecha y regla cuando hay varios créditos |
| `días_atraso` | cartera.id_dias_atraso → dias_atraso_dim.PK_id_dias_atraso/dias_atraso | Agregación y fecha oficial; no imponer MAX sin aprobación |
| `rango_mora` | cartera.id_rango_mora → rango_mora_dim.pk_id_rango_mora/descripcion | Definir rangos vigentes y prioridad; preservar trazabilidad al crédito |
| `cupo_disponible` | cartera.saldo/monto/fecha + cuentas/reservas/ajustes aprobados | Fórmula pendiente; el hecho observado no demuestra todos sus componentes ni moneda |
| `flag_contactable` | Resultado de escalera de mora y reglas de gestión | Reglas de negocio y exclusiones; separar aptitud operativa de permiso legal de contacto |
| `optin_email` | Fuente de consentimiento pendiente | Último evento válido por cliente/finalidad/canal; ausencia significa desconocido, nunca aceptación |
| `optin_whatsapp` | Fuente de consentimiento pendiente | Evidencia, fecha, revocación y número asociado |
| `optin_llamadas` | Fuente de consentimiento pendiente | Evidencia y vigencia; independiente de los otros canales |
| `vtex_customer_id` | Extracto VTEX no localizado | Puente verificable con id_cliente y control de colisiones |
| `venta_smart_cotizaciones` | Extracto Venta Smart no localizado | Definir si es cantidad, lista o relación; ventana temporal, estados y llave |
| `_certification_status` | Resultados de calidad y decisiones de gobierno | Estados propuestos pendiente/observado/certificado; umbrales y aprobación antes de certificar |
| `_data_owner` | Registro de responsables por dominio | Miguel Espinoza citado en documento base; ratificar y registrar identificador corporativo |
| `_sensitivity_classification` | Catálogo de clasificación de información | Clasificar identidad, contacto y crédito; aplicar controles por atributo |

Supervivencia de E1: contacto más reciente, prioridad Dynamics > SIAC > Venta Smart; crédito de CrediCresa; dirección validada. Antes de implementar: precisar si prioridad desempata o prevalece sobre fecha, tratar timestamps ausentes y registrar fuente ganadora. El Gold actual no contiene un timestamp de modificación por contacto; no utilizar la fecha de actualización técnica de la tabla como reemplazo.

## 8. Insumos para poblar cada atributo de Producto

Grano propuesto inicial: empresa + SKU y variante cuando corresponda. Una clave global por SKU exige demostrar unicidad entre empresas. `producto_unidad` conserva motor/chasis y relación al maestro; E5 hace MERGE por empresa + SKU + motor + chasis.

| Atributo de diseño | Columna/insumo identificado | Transformación y condición de aceptación |
|---|---|---|
| `cod_producto` | Producto.cod_producto/id_empresa; Dynamics.ItemNumber/dataAreaId | Unicidad al grano acordado, variantes y equivalencias entre empresas |
| `des_producto` | Producto.des_producto/des_producto_full | Regla entre ProductSearchName, SearchName y productname; tratar SIN DEFINIR como indicador de calidad |
| `des_marca` | Producto.des_marca; InventPackagingGroups vía temp_marca_dim | Código/empresa, equivalencia y vigencia; evitar joins muchos-a-muchos |
| `des_categoria` | Producto.des_categoria; ProductGroups | Diferenciar categoría del producto y categoría comercial |
| `des_grupo` | Producto.des_grupo; CommercialHeirarchyCategories | Integridad de jerarquía y código/empresa |
| `des_subgrupo` | Producto.des_subgrupo; CommercialHeirarchyCategories | Correspondencia con grupo, vigencia y jerarquía aprobada |
| `ancho` | Producto.ancho; Dynamics.GrossProductWidth | Valor físico, unidad y ficha técnica; no rellenar faltantes con cero |
| `altura` | Producto.altura; histórico/ficha técnica | E5 asigna NULL en la rama Dynamics; obtener fuente que lo capture |
| `longitud` | Producto.longitud; Dynamics.GrossDepth | Homologar significado profundidad/longitud y unidad |
| Unidad normalizada de cada dimensión | Producto.ancho_um/altura_um/longitud_um; catálogo corporativo de unidades | Factor y unidad de origen obligatorios para conversión; E5 asigna NULL en Dynamics |
| `num_motor` | Producto.num_motor; sums.InventBatchId | Conservar en entidad de unidad; no elegir un único motor por SKU |
| `serie_chasis` | Producto.serie_chasis; sums.InventSerialId | Diferenciar 00000, serial genérico y VIN; regla vehicular antes de validar formato |
| `es_vehiculo` | Clasificación comercial; E5 usa ProductGroupId = Veh_moto | Homologación de familias vehiculares aprobada; longitud 17 no basta para clasificar |
| `especificaciones_técnicas` | EAV: productnumber/attributename/attributetypename/datatype y valores tipados | Diccionario, unidades, idioma, vigencia y multivalores; puente con ItemNumber; no pivotar con MAX arbitrario |
| `ean` | Catálogo de códigos de barras pendiente | Asociación SKU/variante/empaque, tipo, longitud y dígito de control según estándar adoptado |
| `_certification_status` | Calidad, completitud y decisiones del steward | Certificar según criterios; métricas históricas no son validación actual |
| `_data_owner` | Registro de responsables de Producto | Ratificar responsable y mantener vigencia |

El 92,4% de medidas faltantes y el 55,6% de chasis de 17 caracteres provienen de E1 y requieren nueva medición. E5 aporta una explicación parcial: altura/unidades nulas en Dynamics, seriales técnicos 00000 fuera de Veh_moto y mezcla con histórico. El código no permite afirmar que todos los chasis largos sean VIN válidos.

## 9. Riesgos de integración y decisiones pendientes

1. **Identidad:** aprobar crosswalk, documento/empresa y tratamiento de clientes sin documento; comprobar cardinalidades antes de fusionar.
2. **Teléfono SIAC:** E5 combina MAX(ISECUENCIA) y MAX(DFECHAINGRESO) calculados por separado y exige ambos; pueden no corresponder a la misma fila. Validar con perfilado agregado y regla de orden total.
3. **Fuentes de nombres parecidos:** customersv3/CustomersV3_OPT y ProductAttributeValuesV3/d365_productattributevaluesv3 existen como objetos separados; no asumir equivalencia o intercambiabilidad.
4. **Producto:** conservar histórico y entradas auxiliares si se reconstruye E5; revisar joins por SKU sin empresa y duplicados de proveedor antes de reproducir MERGE.
5. **Cartera:** fijar fecha de corte y grano del hecho; id_cliente no está demostrado como el nuevo id MDM. No sumar snapshots ni hechos de distinto grano.
6. **Gobierno:** resolver consentimiento, EAN y fuentes comerciales faltantes; acordar umbrales, clasificación y autorización de datos de Desarrollo.
7. **Publicación:** usar manifiesto único por versión que apunte a snapshots completos. Con Parquet no hay transacción conjunta entre vistas; verificar la versión común antes de exponer ambos maestros y conservar la publicación previa para recuperación.

## 10. Entregas requeridas y secuencia de implementación

| Responsable funcional propuesto | Entrega requerida | Criterio de cierre |
|---|---|---|
| Plataforma / productor | Snapshots Parquet de núcleo y referencias, manifiestos y diccionarios; permisos sobre volúmenes | Corte, filas, bytes/checksum, tipos y archivos conciliados |
| Comercial / Cliente | Reglas de identidad, preferencia de canal, segmentación y puentes VTEX/Venta Smart | Matriz atributo-columna-clave aprobada y extractos poblados |
| Crédito | Fórmula de cupo, reservas/ajustes, escalera, agregación y corte | Casos de ejemplo conciliados con fuente de autoridad |
| Producto / proveedores | Fichas técnicas, unidades, EAN y clasificación vehicular | Cobertura por SKU/variante y excepciones explícitas |
| Gobierno / responsables de canales | Consentimiento, clasificación, owners, retención y certificación | Evidencia versionada y permisos acordes a finalidad |
| Ingeniería | Crosswalk, conformación, maestro SKU/unidad, calidad y publicación | Pruebas de unicidad, integridad, supervivencia y conciliación |

Secuencia: (1) formalizar contratos y decisiones; (2) habilitar los volúmenes propuestos; (3) recibir snapshots completos; (4) conformar Cliente y Producto/unidad; (5) completar o explicitar atributos pendientes; (6) validar calidad y reglas; (7) publicar versión aprobada. Una entrega parcial debe declarar atributos pendientes, nunca presentar el maestro completo como certificado.

La creación/copia/despliegue requiere una solicitud de ejecución posterior. El alcance actual solicita arquitectura y análisis; solo se hicieron lecturas remotas. El despliegue del piloto no debe invocarse contra los catálogos existentes para implementar automáticamente este diseño.

## 11. Validación de la entrega

Se valida UTF-8, estructura Markdown, tablas, enlaces locales y JSON de evidencia. Se reconfirma inventario de **34 YAML / 451 atributos** contra el diccionario, sin modificar contratos, notebooks, jobs ni SQL. Se comprueba ausencia de patrones de secretos en los documentos y evidencia nuevos. La comprobación remota es exclusivamente existencia/esquema de E4; los conteos pertenecen a E3. No se afirma despliegue ni ejecución de los maestros.

## Consolidación documental y publicación Git

El [estado vigente](ESTADO_VIGENTE.md) registra la precedencia de esta definición, el inventario de documentos y las fuentes originales conservadas. La publicación Git incorpora los cambios locales y no despliega objetos en Databricks. Los nombres completos Silver/Gold indicados para ambos ambientes permanecen vigentes.
