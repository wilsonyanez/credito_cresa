# Checklist de despliegue Databricks

## Registro

| Campo | Valor |
|---|---|
| Rama/commit | `[completar]` |
| Workspace/Git folder | `[completar]` |
| Runtime/cluster ID | `[completar]` |
| Responsable técnico | `[completar]` |
| Data Owner | `[completar]` |
| Ventana | `[completar]` |

## Puerta 1 — Revisión y debate

- [ ] Confirmar que no habrá conexión a Microsoft SQL Server.
- [ ] Confirmar que `cresa_dev.credito_cresa_source` será la fuente recreada.
- [ ] Aprobar las 34 entidades o definir una primera ola.
- [ ] Debatir si habrá semillas Parquet, CSV o tablas vacías.
- [ ] Aprobar que, sin semilla/diccionario, los tipos serán `STRING`.
- [ ] Revisar el riesgo de probar lógica de fechas/números sobre tablas `STRING`.
- [ ] Aprobar Parquet para fuente, landing y Bronze; Delta para control plane.
- [ ] Confirmar que `construccion_tecnica_previa/` no se desplegará.

| Rol | Decisión | Nombre/fecha | Observación |
|---|---|---|---|
| Arquitectura | `[ ] Aprobar [ ] Rechazar` | | |
| Data Owner | `[ ] Aprobar [ ] Rechazar` | | |
| Databricks Admin | `[ ] Aprobar [ ] Rechazar` | | |

## Puerta 2 — Validación local

- [ ] Ejecutar `.\pre_productiva\scripts\validate_package.ps1`.
- [ ] Confirmar 34 YAML y JSON válido.
- [ ] Revisar `config/sources/credito_cresa.yml`.
- [ ] Confirmar ausencia de JDBC, connection strings y secretos de base externa.
- [ ] Reemplazar `REEMPLAZAR_RUTA_GIT_FOLDER` y `REEMPLAZAR_CLUSTER_ID`.
- [ ] Revisar ambos notebooks mediante pull request.
- [ ] Mantener el job `PAUSED`.

## Puerta 3 — Creación del ambiente

- [ ] Aprobar catálogo `cresa_dev`.
- [ ] Revisar y ejecutar `sql/00_create_test_environment.sql`.
- [ ] Confirmar esquemas `landing`, `credito_cresa_source` y `bronze`.
- [ ] Confirmar volúmenes `source_seed` y `parquet`.
- [ ] Revisar y ejecutar `sql/01_create_control_plane.sql`.
- [ ] Validar las cuatro tablas y dos vistas de `audit01`.
- [ ] Adjuntar evidencia de objetos y permisos.

## Puerta 4 — Semillas y tipos

Para cada tabla de la ola:

- [ ] Decidir si requiere datos o puede quedar vacía.
- [ ] Si hay semilla, revisar origen, anonimización y autorización.
- [ ] Preferir Parquet para preservar tipos.
- [ ] Si es CSV, revisar tipos inferidos antes de aprobar.
- [ ] Cargar semilla en `/Volumes/cresa_dev/landing/source_seed/<tabla>/`.
- [ ] Registrar el esquema esperado y sus limitaciones.

No usar datos personales reales sin aprobación de Gobierno/Privacidad.

## Puerta 5 — Recreación de la base

Primera ejecución sugerida:

```text
notebook: 01_create_source_database.py
table_filter: ^sis_peticiones$
replace_existing: false
seed_format: parquet
```

- [ ] Revisar el resultado `CREATED_FROM_SEED` o `CREATED_EMPTY_STRING_SCHEMA`.
- [ ] Ejecutar `DESCRIBE TABLE cresa_dev.credito_cresa_source.sis_peticiones`.
- [ ] Aprobar columnas, tipos y nulabilidad.
- [ ] Insertar datos sintéticos si se requieren pruebas funcionales.
- [ ] Repetir por olas hasta recrear las 34 entidades aprobadas.

`replace_existing=true` puede eliminar y recrear tablas fuente de prueba. Requiere aprobación explícita y un filtro de tabla preciso.

## Puerta 6 — Despliegue y prueba del pipeline

- [ ] Crear `ingest_credito_cresa_source` con estado pausado.
- [ ] Confirmar un solo job por fuente y una sola ejecución concurrente.
- [ ] Ejecutar `dry_run=true`, `table_filter=^sis_peticiones$`.
- [ ] Revisar `audit01.ingestion_runs` e `ingestion_columns`.
- [ ] Resolver diferencias entre tabla recreada y YAML.
- [ ] Ejecutar `dry_run=false` con el mismo filtro.
- [ ] Confirmar Parquet en `/Volumes/cresa_dev/landing/parquet/credito_cresa/sis_peticiones/`.
- [ ] Confirmar tabla registrada en `cresa_dev.bronze`.
- [ ] Comparar conteos entre fuente interna y Bronze.

```sql
SELECT COUNT(*) FROM cresa_dev.credito_cresa_source.sis_peticiones;
SELECT COUNT(*) FROM cresa_dev.bronze.credito_cresa_sis_peticiones;
SELECT * FROM cresa_dev.audit01.v_latest_ingestion_run;
SELECT * FROM cresa_dev.audit01.v_ingestion_errors;
```

## Puerta 7 — Lote completo

- [ ] Aprobar lista exacta de tablas.
- [ ] Ejecutar primero por grupos `cat_*`, `cfg_*`, `cre_*`, `cub_*`, `lcr_*`, otros.
- [ ] Revisar esquemas, conteos, errores y costos por grupo.
- [ ] Ejecutar sin filtro solo después de aprobar todas las olas.
- [ ] Exigir estado final `SUCCEEDED`; `PARTIAL` no equivale a éxito.
- [ ] Mantener el schedule pausado hasta aprobación final.

## Reversa

- [ ] Pausar/cancelar el job.
- [ ] Preservar control plane y logs.
- [ ] Identificar objetos exactos por `run_id`.
- [ ] Obtener aprobación antes de borrar tablas o archivos.
- [ ] Para recrear una fuente, usar filtro preciso y `replace_existing=true` aprobado.
- [ ] Repetir revisión desde la puerta afectada.

## Aprobación final

| Rol | Decisión | Nombre | Fecha | Evidencia |
|---|---|---|---|---|
| Responsable técnico | `[ ] Aprobar [ ] Rechazar` | | | |
| Arquitectura | `[ ] Aprobar [ ] Rechazar` | | | |
| Gobierno/Privacidad | `[ ] Aprobar [ ] Rechazar` | | | |
| Data Owner | `[ ] Aprobar [ ] Rechazar` | | | |
| Operaciones Databricks | `[ ] Aprobar [ ] Rechazar` | | | |

Detenerse si falta una aprobación, se intenta usar un catálogo no autorizado, hay datos no autorizados o existen diferencias de esquema sin resolver.

