# Evidencia de entidades por dominio

Generado desde `13_Procesos_Producto_Cliente.xlsx`, hoja `Diciconario Azurian`. Referencias documentales; existencia, formato, columnas y dependencia física pendientes de inspección remota.

| Fila Excel | Dominio | Entidad en R | Proceso en M |
|---|---|---|---|
| 2 | Cliente | `dlh_cresa.bronze.d365_CustomersV3_OPT` | `ExtraccionCatalogosFull - CustomersV3_OPT_zip` |
| 3 | Cliente | `dlh_cresa.staging.temp_persona_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PERSONA_DIM/PROCESOS/carga_temp_persona_dim_sql` |
| 4 | Cliente | `dlh_cresa.staging.temp_provincia_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PERSONA_DIM/PROCESOS/carga_temp_provincia_dim_sql` |
| 5 | Cliente | `dlh_cresa.bronze.AddressCities;` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PERSONA_DIM/PROCESOS/carga_temp_ciudad_dim_sql` |
| 6 | Cliente | `dlh_cresa.gold.dw_cresa_persona_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PERSONA_DIM/PROCESOS/carga_dw_cresa_persona_dim_sql` |
| 8 | Producto | `dlh_cresa.bronze.d365_ReleasedProductsV2` | `ExtraccionCatalogosFull - ReleasedProductsV2_zip` |
| 9 | Producto | `dlh_cresa.staging.temp_producto_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_producto_dim_sql` |
| 10 | Producto | `dlh_cresa.staging.temp_marca_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_marca_dim_sql` |
| 11 | Producto | `dlh_cresa.staging.temp_linea_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_linea_dim_sql` |
| 12 | Producto | `dlh_cresa.staging.temp_grupo_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_grupo_dim_sql` |
| 13 | Producto | `dlh_cresa.staging.temp_subgrupo_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_subgrupo_dim_sql` |
| 14 | Producto | `dlh_cresa.staging.temp_categoria_producto_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_categoria_producto_dim_sql` |
| 15 | Producto | `dlh_cresa.staging.temp_atributos_producto_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_atributos_producto_dim_sql` |
| 16 | Producto | `dlh_cresa.staging.temp_ciclo_producto_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_ciclo_producto_dim_sql` |
| 17 | Producto | `dlh_cresa.staging.temp_capacidad_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_capacidad_dim_sql` |
| 18 | Producto | `dlh_cresa.staging.temp_proveedores_mktpl_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_proveedores_mktpl_dim_sql` |
| 19 | Producto | `dlh_cresa.staging.temp_tipo_marca_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_tipo_marca_dim_sql` |
| 20 | Producto | `dlh_cresa.staging.temp_producto_procedencia_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_procedencia_dim_sql` |
| 21 | Producto | `dlh_cresa.staging.temp_tipo_producto_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_temp_tipo_producto_dim_sql` |
| 22 | Producto | `dlh_cresa.gold.dw_cresa_producto_dim` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_dw_cresa_producto_dim_sql` |
| 23 | Producto | `dlh_cresa.silver.dw_cresa_fechas_recepcion_producto` | `/Workspace/Shared/DLHCRESA01/TRANSFORMACIONES/DIMENSIONES_GENERALES/PRODUCTO_DIM/PROCESOS/carga_dw_cresa_fechas_recepcion_producto_sql` |

Las rutas completas L/M y el resto de hojas se conservan en `excel_evidencia.json`. No se rellenan celdas vacías ni se infiere dominio a partir de hojas sin T. Los rangos combinados y hashes se conservan en `excel_manifest.json`.
