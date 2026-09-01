# Paquete pre-productivo Databricks

Paquete autónomo para recrear la fuente y probar las ingestas íntegramente dentro de Databricks. No requiere conexión a Microsoft SQL Server.

## Flujo

```text
YAML + semillas opcionales
        |
        v
cresa_dev.credito_cresa_source   (tablas fuente Parquet)
        |
        v
pipeline metadata-driven
        |
        +--> /Volumes/cresa_dev/landing/parquet/credito_cresa/
        +--> cresa_dev.bronze.*   (tablas Parquet)
        +--> cresa_dev.audit01.*  (control plane Delta)
```

## Orden de implementación

1. Reemplazar la ruta del Git folder y el cluster ID en `config/jobs/ingest_credito_cresa_source.json`.
2. Ejecutar `notebooks/00_deploy_bronze.py` para crear el ambiente, volúmenes, control plane y tablas fuente.
3. Opcional: cargar semillas en `/Volumes/cresa_dev/landing/source_seed/<tabla>/` y repetir únicamente la tabla aprobada.
4. Revisar qué tablas obtuvieron tipos desde semillas y cuáles quedaron vacías con `STRING`.
5. Crear el job consolidado con `pause_status=PAUSED`.
6. Probar `dry_run=true` y `table_filter=^sis_peticiones$`.
7. Ejecutar la misma entidad con `dry_run=false` y luego avanzar por olas.

## Objetos desplegables

| Objeto | Ruta |
|---|---|
| Fuente interna | `config/sources/credito_cresa.yml` |
| 34 entidades | `config/ingestion/*.yml` |
| Despliegue Bronze | `notebooks/00_deploy_bronze.py` |
| Recreación de la base | `notebooks/01_create_source_database.py` |
| Pipeline | `notebooks/ingest_databricks_source_to_parquet.py` |
| Job consolidado | `config/jobs/ingest_credito_cresa_source.json` |
| Ambiente | `sql/00_create_test_environment.sql` |
| Control plane | `sql/01_create_control_plane.sql` |

## Tipos de datos

- Con semilla Parquet: se conserva el esquema del archivo.
- Con semilla CSV: Spark infiere los tipos; requiere revisión.
- Sin semilla ni diccionario: la tabla se crea vacía con columnas `STRING`.

No se aplican inferencias por nombre de columna. Una tabla vacía `STRING` sirve para validar contratos y orquestación, pero no transformaciones dependientes de tipos.

## Validación local

```powershell
.\pre_productiva\scripts\validate_package.ps1
```

Usar `docs/CHECKLIST_DESPLIEGUE_DATABRICKS.md` para revisión y aprobaciones.
