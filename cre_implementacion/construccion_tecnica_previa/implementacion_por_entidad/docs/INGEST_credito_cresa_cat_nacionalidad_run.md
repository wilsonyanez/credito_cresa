# Instrucciones de ejecución: `credito_cresa_cat_nacionalidad`

## 1. Objetivo

Ingerir `CREDITO_CRESA.dbo.cat_nacionalidad` en `dlh_cresa.bronze.credito_cresa_cat_nacionalidad` mediante el notebook metadata-driven, con controles de calidad, conteo de registros por tabla y alertas SMTP.

## 2. Configuración

YAML: `templates_ingenieria/config/ingestion/credito_cresa_cat_nacionalidad.yml`  
Job: `templates_ingenieria/config/ingestion/job/credito_cresa_cat_nacionalidad_job.json`  
JSON asociado: `templates_ingenieria/config/ingestion/JSON/credito_cresa_cat_nacionalidad.json`

La sentencia solicitada queda registrada en el YAML:

```sql
select id,nombre,es_activo from CREDITO_CRESA.dbo.cat_nacionalidad nolock
```

Para ejecución SQL Server con table hint explícito, usar la variante equivalente `FROM CREDITO_CRESA.dbo.cat_nacionalidad WITH (NOLOCK)`.

## 3. Pre-requisitos

- Secret `cresa_secrets/sql_connection_string` disponible.
- Acceso de escritura a `dlh_cresa.bronze` y tablas de control `audit01`.
- Notebook `template_pipeline_metadata_driven` publicado en Databricks.
- SMTP `smtp.empresa.local:587` con TLS y destinatarios autorizados.
- Data Owner y clasificación aprobados antes de producción.

## 4. Ejecución manual

Configurar los parámetros:

```text
config_yml = analisis_caracterizacion/templates_ingenieria/config/ingestion/credito_cresa_cat_nacionalidad.yml
run_mode = test
enable_quality_checks = true
enable_alerts = false
```

Ejecutar el notebook completo y confirmar que la escritura finaliza sin fallos.

## 5. Ejecución programada

Importar el JSON en Databricks Workflows. El job se programa a las **02:30 AM**, zona `America/Bogota`, con dos reintentos y timeout de 30 minutos. Mantener `enable_quality_checks=true` y `enable_alerts=true` en producción.

## 6. Controles post-ejecución

### Conteo de registros por tabla

```sql
SELECT COUNT(*) AS total_registros,
       COUNT(DISTINCT id) AS ids_unicos
FROM dlh_cresa.bronze.credito_cresa_cat_nacionalidad;
```

Esperado: `total_registros > 0` e `ids_unicos = total_registros`.

### Duplicados de clave primaria

```sql
SELECT id, COUNT(*) AS cantidad
FROM dlh_cresa.bronze.credito_cresa_cat_nacionalidad
GROUP BY id
HAVING COUNT(*) > 1;
```

Esperado: cero filas.

### Valores y nulos críticos

```sql
SELECT es_activo, COUNT(*) AS cantidad
FROM dlh_cresa.bronze.credito_cresa_cat_nacionalidad
GROUP BY es_activo;

SELECT COUNTIF(id IS NULL) AS nulos_id,
       COUNTIF(nombre IS NULL) AS nulos_nombre,
       COUNTIF(es_activo IS NULL) AS nulos_es_activo,
       COUNTIF(actualizado < creado) AS fechas_inconsistentes,
       COUNTIF(actualizado > CURRENT_TIMESTAMP()) AS fechas_futuras
FROM dlh_cresa.bronze.credito_cresa_cat_nacionalidad;
```

### Control de ejecución

```sql
SELECT TOP 20 run_id, config_path, status, records_processed,
       records_failed, execution_time_seconds, started_at, completed_at
FROM dlh_cresa.audit01.log_procesos
WHERE config_path LIKE '%cat_nacionalidad%'
ORDER BY started_at DESC;
```

## 7. Alertas SMTP

| Condición | Severidad | Acción |
|---|---|---|
| Cambio de conteo mayor a 30% | MEDIUM | Notificar equipo |
| Ejecución mayor a 300 segundos | MEDIUM | Notificar DBA |
| Cualquier validación fallida | CRITICAL | Bloquear y alertar |

Una alerta debe incluir `run_id`, tabla, validación fallida, conteos origen/destino y enlace al log. Nunca incluir tokens, contraseñas ni valores sensibles de columnas en el correo.

## 8. Respuesta ante fallos

1. Consultar `audit01.log_procesos` y `audit01.control_calidad_ingestion`.
2. Comparar el conteo del origen con el destino.
3. Revisar cambios en `cat_zona_id`, fechas y registros eliminados.
4. Corregir el origen o configuración, ejecutar nuevamente en test y luego reactivar producción.
5. Escalar fallos SMTP al equipo de plataforma y fallos de datos al Data Owner.

## 9. Observaciones de gobierno

- `creado_por`, `actualizado_por` y `gestor_id` se tratan como campos restringidos/identificables en los controles de gobierno.
- `NOLOCK` puede producir lecturas no consistentes; monitorear diferencias entre origen y Bronze.
- Validar dependencia referencial con `cat_nacionalidad` antes de la aprobación productiva.
