# Medición remota de fuentes — Persona y Producto

Consulta de lectura: `01f1b13b-0c1c-1f24-b35f-e89818fdceb7`, SUCCEEDED. Fecha de recuperación UTC: 2026-09-15T19:26:27.649669+00:00

## Parquet activo en volúmenes

| Ruta | Archivos | Bytes | Filas |
|---|---:|---:|---:|
| `/Volumes/dlh_cresa/bronze/vol_bronze_siac/genvtclientedirecciontelef_cresa/` | 1 | 55935289 | 377482 |
| `/Volumes/dlh_cresa/bronze/vol_bronze_siac/genmtelefono_cresa/` | 1 | 63651703 | 2490209 |
| `/Volumes/dlh_cresa/bronze/vol_bronze_siac/genmpersona_cresa/` | 1 | 58803558 | 1131674 |
| `/Volumes/dlh_cresa/bronze/vol_bronze_metas_dwtanque_cresa/tbl_proveedores_mktpl/tbl_proveedores_mktpl.parquet` | 1 | 846397 | 55516 |

## Tablas fuente Delta administradas

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

Los bytes corresponden exclusivamente a cuatro archivos Parquet listados. No incluyen las tablas Delta ni el cierre pendiente de Crédito/Cartera. Conteos y listado no están fijados a un snapshot común: repetir sobre un corte estable antes de copiar. Los bytes de una exportación Parquet de Delta no se deducen de estos conteos.

Desarrollo: identidad verificada, pero el catálogo dev_dlh_cresa devuelve falta de USE CATALOG. Las rutas suministradas de Persona y Producto no existen. No se copiaron datos ni se crearon objetos remotos.
