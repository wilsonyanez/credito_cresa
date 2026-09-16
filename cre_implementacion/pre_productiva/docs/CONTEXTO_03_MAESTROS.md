> **Revisión de consistencia — 2026-09-16.** Análisis previo con ampliación en los documentos 17 y 20. Para nombres, capacidad, estado de acceso y operación actuales prevalecen el [estado vigente](ESTADO_VIGENTE.md), la [arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y el [informe extendido](20_CRESA_MDM_ANALISIS_EXTENDIDO.md). Los comandos, límites y resultados anteriores del contenido siguiente se conservan como antecedentes; no acreditan un despliegue MDM ni una ejecución actual.

# Contexto 03 — fuentes para maestros Cliente y Producto

> Revisión posterior: el [informe extendido del 2026-09-16](20_CRESA_MDM_ANALISIS_EXTENDIDO.md)
> actualiza existencia y esquemas mediante metadatos productivos. La
> [definición inicial revisada](17_CRESA_DATABRICK_DEFINICION_INICIAL.md)
> incorpora 1,2 TB disponibles en `devstgdlh02`, sin restricción de espacio en
> esta etapa, y propone volúmenes/nombres MDM. Las afirmaciones históricas
> inferiores sobre ausencia de verificación o rechazo de USE CATALOG no
> sustituyen esa evidencia posterior. No se realizaron copias ni despliegues.

Última revisión de acceso a Desarrollo: **resuelto el rechazo USE CATALOG**.
El perfil `dev-dlh_cresa` consultó correctamente `dev_dlh_cresa` y listó
`bronze`, `default` e `information_schema`. Esta comprobación sustituye los
rechazos de permisos descritos en las mediciones históricas inferiores.
No prueba permisos de escritura ni revalida las rutas Workspace.
[Evidencia de revisión](../tests/contexto_03/remoto/revision_acceso_desarrollo.json).

Fecha de revisión: 2026-09-15. Estado: análisis documental y medición parcial remota. Se ejecutó un SELECT de conteos; no se ejecutaron notebooks, copias ni cambios de datos u objetos remotos.

Actualización de acceso: perfiles corregidos por el usuario a `dlh_cresa` y
`dev-dlh_cresa`. Se completó OAuth en ambos hosts y se verificó en ambos la
identidad activa `desarrollo.externowy@cresa.ec`. Se confirmó por API de lectura
que Producción contiene los cuatro notebooks SQL indicados bajo
`/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PERSONA_DIM/PROCESOS`.
Las referencias inferiores a perfiles no configurados describen intentos
anteriores y ya no son el bloqueo vigente. Se exportó el código de Persona y
Producto de Producción; la inspección completa de fuentes de los maestros sigue
pendiente del cierre de Crédito/Cartera.

## Resultado remoto vigente — sustituye el estado preliminar inferior

[Medición por fuente: archivos, bytes y filas](../tests/contexto_03/remoto/MEDICION_FUENTES.md).
[Inventario de notebooks y errores de Desarrollo](../tests/contexto_03/remoto/inventario.json).
[Metadatos de fuentes y archivos](../tests/contexto_03/remoto/fuentes_metadata.json).

- Cuatro rutas Parquet activas, un archivo cada una: `genvtclientedirecciontelef_cresa`, `genmtelefono_cresa`, `genmpersona_cresa` y `tbl_proveedores_mktpl`. Total parcial: **179.236.947 bytes y 4.054.881 filas**.
- Quince tablas fuente consultadas son **Delta administradas**, incluidas `d365_CustomersV3_OPT` (808.211 filas), `d365_ReleasedProductsV2` (70.457), `ProductAttributeValuesV3` (538.672) y `d365_sums` (8.637.632). Las restantes y sus conteos están en la medición enlazada. Sus tamaños de exportación Parquet no se han medido.
- Las rutas Dynamics Parquet del ejemplo están comentadas en los procesos revisados; el código activo consulta tablas Bronze. No usarlas como plan de copia sin verificar equivalencia y vigencia.
- Aparecen fuentes adicionales no explícitas en el mapa: `src.xls_comercial_categoria`, `src.xls_comercial_grupo_asistencia`, `src.xls_tipo_marca`, `bronze.ProductReceiptLines` y `bronze.purchaseorderheadersv2`. La dependencia de fechas de recepción no convierte ese atributo en obligatorio del maestro solicitado.
- Desarrollo devuelve **falta de USE CATALOG sobre dev_dlh_cresa**. Las carpetas suministradas de Persona y Producto, y sus subcarpetas PROCESOS, devuelven ruta inexistente. No se ha probado la capacidad de copia/escritura ni creado el destino.

Factibilidad actual: lectura y conteo de las fuentes inspeccionadas de Producción demostrados; copia a Desarrollo pendiente de permisos y diseño del destino. Las tablas Delta requieren definir una exportación consistente si la entrega debe permanecer en Parquet; no copiar archivos internos de Unity Catalog. El inventario no cierra todavía cartera, segmentación y canal. El total parcial no debe presupuestarse como volumen total de ambos maestros.

Hallazgo de calidad del SQL de persona: el teléfono SIAC usa MAX(ISECUENCIA) y MAX(DFECHAINGRESO) por separado y después exige coincidencia de ambos. Es posible que no correspondan a la misma fila; además, varias filas por identificación pueden afectar el MERGE. Es una observación estática a validar con diagnóstico agregado, no un fallo de ejecución demostrado. No se modificó el ETL productivo.

## Evidencia y alcance

Se revisó `documentacion_insumo/analisis_caracterizacion/01_mapa_maestros.md`, apartados 1 y 2. Sus métricas son históricas: no representan mediciones de esta revisión. Tras recibir su ubicación, se localizaron y leyeron íntegramente las celdas de los archivos `12_Procesos_Credito_Cartera.xlsx` y `13_Procesos_Producto_Cliente.xlsx` en `pre_productiva/docs`. La CLI v1.14.1 sigue rechazando ambos perfiles solicitados porque no están configurados. Los nombres de perfil y las URL suministradas identifican ambientes, pero no constituyen sesiones autenticadas.

## Resultado de los Excel

Se extrajeron 135 filas no vacías de 8 hojas (incluye encabezados y notas). El archivo 12 contiene 15 filas de procesos; el 13 contiene 30 filas de procesos y 21 referencias de dominio en `Diciconario Azurian`: 5 Cliente y 16 Producto. No hay celdas combinadas. La evidencia conserva nombres originales, celdas, filas, fórmulas si existen y SHA-256 de ambos archivos. Algunos textos ya contienen caracteres de sustitución en el archivo; no se corrigen nombres de entidades por aproximación.

- [Inventario de las 21 referencias con proceso y fila](../tests/contexto_03/entidades_por_dominio.md).
- [CSV de procesos, rutas, tablas y dominios](../tests/contexto_03/procesos_fuentes.csv).
- [Evidencia completa de celdas](../tests/contexto_03/excel_evidencia.json) y [manifiesto de archivos](../tests/contexto_03/excel_manifest.json).

El encabezado T de dominios corresponde a `Diciconario Azurian` del archivo 13; no existe en la hoja de procesos del archivo 12. No se asigna un dominio automáticamente a todas las filas de Crédito/Cartera. R mezcla tablas fuente, intermedias, salidas y nombres de cargas: la dirección del linaje requiere el SQL.

### Cliente: detalle adicional confirmado documentalmente

Todas las filas siguientes corresponden al archivo 13, hoja `Diciconario Azurian`:

| Fila | Entidad | Uso previsto e insumo pendiente |
|---|---|---|
| 2 | `dlh_cresa.bronze.d365_CustomersV3_OPT` | Extracción `CustomersV3_OPT_zip`: candidata de cliente Dynamics. Confirmar columnas de identificación, cuenta, contacto, límite y fecha; equivalencia con `customersv3` pendiente. |
| 3 | `dlh_cresa.staging.temp_persona_dim` | Conformación intermedia de persona. Revisar JOIN, limpieza, prioridad y claves en `carga_temp_persona_dim_sql`. |
| 4 | `dlh_cresa.staging.temp_provincia_dim` | Catálogo intermedio de provincia para dirección. Se necesitan códigos de país/provincia y correspondencia de origen. |
| 5 | `dlh_cresa.bronze.AddressCities` | La fila del proceso `carga_temp_ciudad_dim_sql` referencia esta tabla Bronze, no una tabla temporal de ciudad. Necesita claves de ciudad/provincia/país. |
| 6 | `dlh_cresa.gold.dw_cresa_persona_dim` | Salida de persona que alimentaría el maestro; confirmar columnas y reglas de `carga_dw_cresa_persona_dim_sql`. |

La ruta de los cuatro SQL queda documentada bajo `PERSONA_DIM/PROCESOS/`; L incluye el archivo `sp_persona_dim_py`, no solo un directorio. Son referencias del Excel, aún no exportaciones de Workspace.

### Producto: detalle adicional confirmado documentalmente

Mismo archivo y hoja; los SQL se ubican bajo `PRODUCTO_DIM/PROCESOS/` y L señala `sp_producto_dim_py`.

| Fila | Entidad | Papel previsto respecto de los atributos |
|---|---|---|
| 8 | `dlh_cresa.bronze.d365_ReleasedProductsV2` | Fuente candidata de SKU, descripción y propiedades del producto. Confirmar columnas y grano por empresa/variante. |
| 9 | `dlh_cresa.staging.temp_producto_dim` | Base intermedia del producto; verificar identificación, medidas y seriales reales en SQL. |
| 10 | `dlh_cresa.staging.temp_marca_dim` | Candidata para `des_marca`; claves y relación al SKU pendientes. |
| 11 | `dlh_cresa.staging.temp_linea_dim` | Jerarquía de línea; confirmar si aporta a categoría/grupo o es una extensión. |
| 12 | `dlh_cresa.staging.temp_grupo_dim` | Candidata para `des_grupo`; requiere código y descripción. |
| 13 | `dlh_cresa.staging.temp_subgrupo_dim` | Candidata para `des_subgrupo`; requiere relación jerárquica con grupo. |
| 14 | `dlh_cresa.staging.temp_categoria_producto_dim` | Candidata para `des_categoria`; claves y vigencias pendientes. |
| 15 | `dlh_cresa.staging.temp_atributos_producto_dim` | Intermedia de especificaciones; confirmar relación EAV, valores múltiples y unidades. |
| 16 | `dlh_cresa.staging.temp_ciclo_producto_dim` | Ciclo de vida: dependencia del proceso existente; no es atributo explícito del mapa. Revisar si filtra SKU. |
| 17 | `dlh_cresa.staging.temp_capacidad_dim` | Capacidad: candidata de especificaciones técnicas; no equiparar a dimensiones físicas. |
| 18 | `dlh_cresa.staging.temp_proveedores_mktpl_dim` | Proveedores marketplace: dependencia del proceso, exigibilidad para el maestro pendiente del JOIN. |
| 19 | `dlh_cresa.staging.temp_tipo_marca_dim` | Tipo de marca: soporte de clasificación; evaluar necesidad real para atributos solicitados. |
| 20 | `dlh_cresa.staging.temp_producto_procedencia_dim` | Procedencia: tabla cuyo nombre difiere del SQL `carga_temp_procedencia_dim_sql`; conservar ambos. |
| 21 | `dlh_cresa.staging.temp_tipo_producto_dim` | Candidata para clasificación y contraste de `es_vehiculo`; no asumir correspondencia sin catálogo. |
| 22 | `dlh_cresa.gold.dw_cresa_producto_dim` | Dimensión de salida que aporta la mayoría de atributos del mapa. |
| 23 | `dlh_cresa.silver.dw_cresa_fechas_recepcion_producto` | Salida de fechas de recepción; no demuestra timestamp de modificación ni obligación de incorporarla al maestro. |

Estas 16 referencias no equivalen a 16 fuentes Parquet a copiar: incluyen intermedias y salidas potencialmente reconstruibles. Solo el cierre del linaje permite escoger entre copiar fuentes y reconstruir, o recibir snapshots de dimensiones.

### Fuentes auxiliares y Crédito/Cartera

| Evidencia (archivo / hoja Procesos / fila) | Entidades documentadas | Evaluación para el maestro |
|---|---|---|
| 13 / 5 | `GENMCLIENTE_CRESA`, `GENMPERSONA_CRESA`, `GENMTELEFONO_CRESA`, `GENMDIRECCION_CRESA`, `GENVTCLIENTEDIRECCIONTELEF_CRESA`, `GENVTCLIENTE_CRESA` (prefijo `DWTANQUE_CRESA`) | Candidatas SIAC de identidad/contacto/dirección. Confirmar sus réplicas en el lake y campos; no habilitar conexión externa. |
| 13 / 5 | `GENMCLIENTEFORMALIDAD_CRESA`, `GENPCLASIFICADOR_CRESA`, `GENMCLIENTECALIFICACION_CRESA` | Candidatas de clasificación; falta puente a segmento demográfico. |
| 13 / 5 | `GENMCLIENTECUPO_CRESA`, `GENMCLIENTETARJETA_CRESA`, `CREHBITACORATARJETA_CRESA`, `CRETSOLICITUD_CRESA` | Candidatas de cupo y vigencia; requieren fórmula aprobada y relación a cliente. |
| 13 / 5 | `CARTOPERACION_CRESA`, `CARTCUOTA_CRESA`, `CARTCUOTADETALLE_CRESA`, `CARTRECIBO_CRESA`, `CARTRECIBODETALLE_CRESA`, `CARHCONSUMOSALDO_CRESA` | Candidatas transaccionales de saldos/atraso. No sumar importes sin conocer grano, anulaciones y corte. |
| 12 / 7 | `dw_cresa_cartera_saldos_fact`, `dw_cresa_operacion_dim`, `dw_cresa_detalle_operacion_dim`, `dw_cresa_persona_siac_dim`, `dw_cresa_solicitud_dim`, `dw_cresa_amortizacion_fact` | Modelo de cartera generado por `ppl_cresa_procesar_modelo_cartera`; seguir dependencias de saldos, no copiar todas sus salidas de reportes por defecto. |
| 13 / 22 | `AddressStates`, `AddressCities` | Candidatas Dynamics de geografía para dirección. |
| 13 / 22 | `ReleasedProductsV2`, `CommercialHeirarchyCategories`, `ProductGroups`, `InventPackagingGroups`, `ProductLifecycleStates`, `ProductAttributeValuesV3` | Candidatas Dynamics de producto, jerarquía, empaque, ciclo y atributos. No corregir `CommercialHeirarchyCategories` sin evidencia remota. |
| 13 / 25 y 30 | `CustomerV3`, `customersv3` | Dos nombres adicionales a `d365_CustomersV3_OPT` y `customerv3` del ejemplo. No se consideran datasets distintos ni equivalentes hasta verificar rutas y contenido. |
| 13 / 2–3 y 27 | `lw_tbl_base_clientes`, `lw_tbl_gestion_cotizaciones`, `dw_cresa_solicitudes_cotizacion`, `tbl_t_adm_prospecto` y otras tablas LiquidWeb | Pistas de base/cotizaciones; no demuestran disponibilidad de Venta Smart, VTEX ni consentimiento. Investigar puente con `base_concrecion_cliente`. |

El inventario completo de R permanece en el CSV; las agrupaciones anteriores priorizan fuentes candidatas por función, no certifican joins ni columnas. Los archivos no cierran las fuentes de consentimiento, EAN ni metadatos de gobierno.

### Conciliación con los 34 contratos activos

La fila 2 de `12_Procesos_Credito_Cartera.xlsx` contiene **34 menciones pero 33 nombres únicos**: repite `cat_estadoverificacion`. Coinciden literalmente 30 con los 34 YAML activos. Solo en esa fila: `cre_solicitudreferencia`, `sec_usuario`, `ver_transaccional_verificacion`. Solo en los YAML respecto de esa fila: `cat_usuario`, `cobro_tipo_credito_tb`, `com_cub_cobros_cuotas_cresa_tb`, `cub_cobro_cuotas`. Esto compara nombres, no demuestra ausencias en el lake ni equivalencia entre `sec_usuario` y `cat_usuario`.

La fila 4 del archivo 13 incluye variantes adicionales (`modelo_calificacion`, `cat_tipo_vinculo`, `cre_solicitud_laboral`, entre otras) y una separación ambigua `ver_transaccional,verificacion`. Debe contrastarse con SQL antes de crear contratos. No se cambiaron los 34 YAML ni sus tipos a partir de estas listas.

Los valores 700000 y 600000 de `Hoja5` del archivo 13 son anotaciones sin consulta, fecha de corte ni vínculo a archivos. **No son conteos validados para copiar**. Tampoco los porcentajes 0.4/0.6 demuestran volúmenes de transferencia.

La siguiente matriz cubre los atributos del mapa; no certifica la totalidad de dependencias físicas. Un nombre de tabla Gold no identifica por sí solo sus fuentes Parquet. No se asimilan automáticamente los 34 contratos CrediCresa a las fuentes de estos maestros.

## Maestro Cliente: entidades e insumos

| Entidad referida por el mapa | Atributos que aporta | Insumos y definición necesarios |
|---|---|---|
| `gold.dw_cresa_persona_dim` | `num_identificacion`, nombre completo, email, teléfonos, dirección; componente de `id_cliente` | Columnas exactas, tipo de documento, claves de origen, timestamps de actualización, procedencia y señal de validación de dirección. Revisar grano y duplicados antes del cruce. |
| `bronze.customersv3` | `CustomerAccount`, `CreditLimit`; componente de `id_cliente` | Confirmar el campo de identificación y su relación con CustomerAccount. No asumir que cuenta e identificación son equivalentes. Moneda, vigencia y entidad legal del límite; timestamps de contacto si participan en supervivencia. |
| `silver.base_concrecion_cliente` | `canal_origen`, `canal_preferido`; componente de `id_cliente` | `origen`, `canal`, clave de cliente y fecha. El mapa reporta cero filas al 2026-07-14: reconfirmar; una tabla vacía no permite poblar atributos. |
| `gold.dw_cresa_clasificacion_clientes_dim` | `segmento_demográfico` | Clave de clasificación, descripción, vigencia y relación efectiva con persona o hecho. El nombre no demuestra que toda clasificación sea demográfica. |
| `gold.dw_cresa_cartera_saldos_fact` | Base para estado, atraso, mora y cupo | Claves de cliente, crédito y dimensiones; fecha de corte, moneda, saldo y componentes de cupo según fórmula aprobada. Determinar grano y agregación de múltiples créditos por cliente. |
| `gold.dw_cresa_estado_credito_dim` | `estado_crédito` | Clave y catálogo de estados; regla de prioridad cuando un cliente tiene varios créditos. |
| `gold.dw_cresa_dias_atraso_dim` | `días_atraso` | Clave, valor o intervalo, fecha de cálculo y regla de agregación. No asumir MAX sin aprobación. |
| `gold.dw_cresa_rango_mora_dim` | `rango_mora` | Claves, límites de intervalos, vigencia y relación con atraso y hecho. |
| Fuente aún no identificada | `optin_email`, `optin_whatsapp`, `optin_llamadas` | Consentimiento por canal, finalidad, fecha, revocación y evidencia. No derivarlo de disponer de teléfono o correo. |
| Fuente aún no identificada | `vtex_customer_id`, `venta_smart_cotizaciones` | Identificadores y puente con cliente; fuente VTEX y Venta Smart no localizada por el mapa. |
| Metadatos de gobierno por definir | `_certification_status`, `_data_owner`, `_sensitivity_classification` | Responsable designado, clasificación y criterios verificables de certificación. No certificar por defecto. |

`cupo_disponible` requiere fórmula validada por Crédito y no equivale a `CreditLimit`. `flag_contactable` requiere escalera de mora y reglas aprobadas; tampoco sustituye consentimiento. Para `id_cliente` se necesita un puente auditable entre identificadores y una política de deduplicación que preserve ceros iniciales y excepciones.

Supervivencia indicada en el mapa: contacto más reciente por timestamp, prioridad Dynamics > SIAC > Venta Smart; crédito desde CrediCresa; dirección solo validada. Faltan confirmar timestamps disponibles, resolución de empates y tratamiento de fechas nulas. Las entidades físicas de SIAC y Venta Smart siguen pendientes de rastreo.

## Maestro Producto: entidades e insumos

| Entidad referida por el mapa | Atributos que aporta | Insumos y definición necesarios |
|---|---|---|
| `gold.dw_cresa_producto_dim` | `cod_producto`, `des_producto`, `des_marca`, `des_categoria`, `des_grupo`, `des_subgrupo` | Columnas, clave SKU, empresa, variantes y vigencia. Confirmar unicidad al grano del maestro. |
| `gold.dw_cresa_producto_dim` | `ancho`, `altura`, `longitud` y unidad normalizada | Valores y columnas `*_um`, catálogo de unidades y conversiones corporativas. Distinguir cero, nulo y no aplicable. La carencia histórica de 92,4% debe volver a medirse. |
| `gold.dw_cresa_producto_dim` | `num_motor`, `serie_chasis`, insumo de `es_vehiculo` | Confirmar grano: motor y chasis pueden corresponder a unidad serializada, no a SKU. Evitar perder múltiples seriales por SKU. Validar bandera con clasificación comercial; longitud de chasis por sí sola no certifica que sea vehículo. |
| `bronze.d365_productattributevaluesv3` | `especificaciones_técnicas` | Clave de producto, atributo, valor tipado, unidad, idioma y vigencia. Identificar diccionario y relaciones EAV en código real. Resolver valores múltiples antes del pivote, sin escoger arbitrariamente un MAX. |
| Fuente aún no identificada | `ean` | Catálogo de códigos de barras, tipo de código y relación SKU/variante/empaque. No inventar EAN a partir del SKU. |
| Metadatos de gobierno por definir | `_certification_status`, `_data_owner` | Responsable y reglas de certificación; pendientes. |

`rlx_products`, `rlx_products_ms` y `sf_producto_test` son salidas consumidoras según el mapa, no fuentes obligatorias demostradas. La publicación común exige revisar sus contratos. El 55,6% histórico de chasis con 17 caracteres no demuestra validez VIN ni identifica todas las unidades vehiculares.

## Estado del rastreo desde los Excel y notebooks

1. Completado: registrar archivo, hoja y número de fila; extraer L (`Ruta_Proceso`), M (`Nombre_Proceso / JOB`), R (`Tabla`) y T (`Dominio/Colección`). Registrar fórmulas separadas de sus valores almacenados; no hay celdas combinadas en estos archivos.
2. Completada la selección documental de Cliente/Producto y candidatas de Crédito/Cartera. Pendiente confirmar mediante SQL cuáles alimentan los atributos y sus dependencias auxiliares.
3. Exportar el código como lectura y seguir recursivamente `dbutils.notebook.run`, `%run`, SQL, vistas y funciones, resolviendo rutas relativas desde cada notebook. Registrar parámetros y rutas construidas dinámicamente como pendientes si no pueden resolverse.
4. Distinguir entradas de salidas de cada sentencia. Resolver vistas hasta tablas y archivos, con claves JOIN, filtros, agregaciones, fecha de corte y columnas usadas. Identificar ciclos y reutilización de fuentes.
5. Registrar cada dependencia con evidencia `Excel/hoja/fila → notebook/línea → entidad/columna → ruta física`. Validar en ambos ambientes sin ejecutar los procesos ETL.

El ejemplo suministrado identifica `sp_persona_dim_py` y cuatro procesos: `carga_temp_persona_dim_sql`, `carga_temp_provincia_dim_sql`, `carga_temp_ciudad_dim_sql` y `carga_dw_cresa_persona_dim_sql`. Provincia y ciudad son dependencias candidatas de dirección, pero sus entidades físicas no están demostradas. La ruta de ejemplo `/Volumes/dlh_cresa/bronze/vol_bronze_dynamics/customerv3/customerv3.parquet` es una candidata aportada por el usuario, no un archivo verificado. Existe diferencia ortográfica entre `customerv3` en el ejemplo y `customersv3` en el mapa: debe resolverse mediante código y listado real.

## Producción → Desarrollo: factibilidad

| Dato | Producción | Desarrollo |
|---|---|---|
| Perfil | `dlh_cresa` | `dev-dlh_cresa` |
| Host | `https://adb-1077365077848684.4.azuredatabricks.net` | `https://adb-7405619726358379.19.azuredatabricks.net` |
| Workspace ID | `1077365077848684` | `7405619726358379` |
| Catálogo | `dlh_cresa` | `dev_dlh_cresa` |
| Carpeta de referencia | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PERSONA_DIM/` | `/Workspace/Shared/DEV-DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PERSONA_DIM/` |

Usuario esperado: `desarrollo.externowy@cresa.ec`. Las carpetas anteriores contienen procesos existentes; no son destinos aprobados para sobrescribir artefactos del piloto.

Resultado actual por cada entidad de ambas matrices: existencia física **no verificada**, ruta Parquet **pendiente**, cantidad de archivos **no medida**, bytes **no medidos**, filas **no medidas**, permisos de destino **no verificados**. Factibilidad **indeterminada**, no rechazada ni aprobada. No presentar valores pendientes como cero.

Para cerrar el análisis se necesita inventario recursivo paginado de todos los archivos de cada dataset, formato real, bytes, particiones, última modificación y snapshot estable. Sumar bytes de archivos únicos evita doble conteo de fuentes compartidas. Obtener filas desde metadatos Parquet completos o `COUNT(*)` de lectura sobre el mismo snapshot; los conteos de Gold no sustituyen conteos de archivos fuente. No copiar archivos internos de Delta como si fueran un dataset Parquet independiente.

Comprobar identidad, catálogo y permisos de lectura en origen; existencia, capacidad y permisos de escritura en volúmenes de destino. Validar compatibilidad de esquemas y rutas de referencia. Para datos personales, definir alcance permitido en Desarrollo y enmascaramiento requerido antes de copiar. La evaluación de permisos no requiere crear objetos de prueba.

El plan de copia deberá fijar mapeo explícito origen/destino, manifiesto de archivos, snapshot, lotes sin sobrescritura, verificación de bytes/checksum y conteos, reanudación y reverso restringido a los archivos creados por ese lote. Estimar duración con bytes medidos y transferencia efectiva, incluyendo verificación; hoy no existe base para una estimación numérica. No se ha implementado ni ejecutado esa copia.

## Comandos PowerShell copiables

Autenticación interactiva por el operador, sin compartir secretos:

```powershell
databricks auth login --host https://adb-1077365077848684.4.azuredatabricks.net --profile dlh_cresa
databricks auth login --host https://adb-7405619726358379.19.azuredatabricks.net --profile dev-dlh_cresa
databricks current-user me --profile dlh_cresa --output json
databricks current-user me --profile dev-dlh_cresa --output json
```

Los lanzadores actuales siguen siendo del piloto CrediCresa: no construyen estos maestros y rechazan adoptar catálogos existentes. Pasarles `dev_dlh_cresa` no los convierte en un despliegue de maestros. Mientras no exista diseño cerrado, los comandos siguientes son exclusivamente planes locales del piloto y no usan las carpetas productivas:

```powershell
& 'C:\desa\git\cresa\cre_implementacion\pre_productiva\scripts\cresa_credicresa_desplegar.ps1' -SourceRoot 'C:\desa\git\cresa\cre_implementacion' -OutputRoot 'C:\desa\git\cresa\cre_implementacion\pre_productiva\tests'
& 'C:\desa\git\cresa\cre_implementacion\pre_productiva\scripts\cresa_credicresa_reversar.ps1' -SourceRoot 'C:\desa\git\cresa\cre_implementacion' -OutputRoot 'C:\desa\git\cresa\cre_implementacion\pre_productiva\tests'
```

La reversa local requiere manifiesto compatible. `-Deploy`/`-Resume` y `-Execute` son opciones remotas del piloto, no instrucciones de esta entrega. El despliegue y reverso específicos de maestros quedan pendientes de inventario, contratos, reglas aprobadas y definición de objetos propios.

## Validación de esta entrega

Sintaxis PowerShell correcta en ambos lanzadores y módulo compartido. Validación directa de contratos: 34 entidades y 451 atributos. Plan local de despliegue satisfactorio: 43 objetos del piloto, sin ejecución remota. Referencias revisadas con `rg`; búsqueda de patrones de secretos sin coincidencias en los scripts, módulo e informe revisados. La suite `test_credicresa_contracts.py` no pudo iniciar por ausencia del módulo preexistente `credicresa_cli`; no se declara aprobada. No se validó la reversa remota ni la construcción de maestros.

Ampliación con Excel: extractor ejecutado con biblioteca estándar, sintaxis Python validada y comprobación de 135 filas/21 referencias, incluidas 5 de Cliente. Cobertura de contratos reconfirmada: 34/451. Búsqueda de patrones de secretos sin coincidencias en la evidencia generada. Los dos intentos de identidad CLI volvieron a fallar por perfil no configurado. Para reproducir la extracción:

```powershell
& 'C:\desa\git\cresa\cre_implementacion\pre_productiva\.venv\Scripts\python.exe' 'C:\desa\git\cresa\cre_implementacion\pre_productiva\scripts\extraer_fuentes_maestros.py'
```
