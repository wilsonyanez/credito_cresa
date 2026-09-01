# Kit de pruebas Databricks basado en YAML

Este directorio crea un ambiente aislado y materializa las entidades declaradas en:

`analisis_caracterizacion/templates_ingenieria/config/ingestion/`

## Orden de ejecución

1. Ejecutar `sql/00_create_test_environment.sql` con permisos para crear objetos.
2. Ejecutar `sql/01_create_control_plane.sql` para crear las bitácoras Delta.
3. Exportar cada tabla SQL Server preferentemente como Parquet.
4. Cargar cada exportación en una carpeta del volumen con el nombre de `source_table`:

```text
/Volumes/cresa_dev/landing/sqlserver/cat_nacionalidad/*.parquet
/Volumes/cresa_dev/landing/sqlserver/sis_peticiones/*.parquet
/Volumes/cresa_dev/landing/sqlserver/cre_solicitud/*.parquet
```

5. Ejecutar `notebooks/01_load_yaml_entities.py` desde el Git folder raíz.
6. Revisar el reporte. El notebook falla al final si alguna entidad tuvo error, sin ocultar las demás.
7. Ejecutar `notebooks/02_validate_test_entities.py`.

Para la lectura JDBC recursiva y el registro automático en el control plane, usar el pipeline documentado en `analisis_caracterizacion/templates_ingenieria/docs/PIPELINE_POR_FUENTE.md`.

## Modos de funcionamiento

- Con Parquet: conserva los tipos exportados y crea/reemplaza la tabla Delta.
- Con CSV: infiere tipos; usar solo para pruebas simples.
- Sin archivo y `create_empty=true`: crea la tabla con todas las columnas como `STRING`. Sirve para probar rutas, jobs y contratos, no transformaciones dependientes de tipos.

Los parámetros permiten cambiar catálogo, esquemas, volumen, formato y modo de escritura sin modificar código.

## Limitaciones detectadas

- Los YAML no contienen tipos de datos SQL Server.
- Algunas claves primarias están escritas como `columns:` seguido de `id`, sin el indicador de lista `-`. El cargador usa un lector tolerante solo para metadatos de creación; conviene corregir esos YAML antes de usarlos con un parser YAML estricto.
- El kit no copia datos desde SQL Server. La transferencia debe hacerse por una ruta de red aprobada o mediante exportación controlada y anonimizada.
- No ejecutar con `catalog=dlh_cresa` durante pruebas.
