# Guía de trabajo — CRESA Fase 3

## Objetivo

El repositorio recrea una fuente de prueba y ejecuta su ingesta íntegramente dentro de Databricks. No existe conexión activa a SQL Server. El paquete activo es `pre_productiva/`; las demás carpetas son insumos o archivo histórico.

## Lectura mínima

1. `README.md`.
2. `pre_productiva/README.md`.
3. Solo el archivo específico de la tarea.

| Necesidad | Ruta |
|---|---|
| Recrear fuente | `pre_productiva/notebooks/01_create_source_database.py` |
| Pipeline activo | `pre_productiva/notebooks/ingest_databricks_source_to_parquet.py` |
| Configuración de fuente | `pre_productiva/config/sources/credito_cresa.yml` |
| Entidad | `pre_productiva/config/ingestion/<entidad>.yml` |
| Job consolidado | `pre_productiva/config/jobs/ingest_credito_cresa_source.json` |
| Ambiente/control plane | `pre_productiva/sql/` |
| Operación | `pre_productiva/docs/PIPELINE_POR_FUENTE.md` |
| Contexto funcional | `documentacion_insumo/analisis_caracterizacion/` |
| Artefactos reemplazados | `construccion_tecnica_previa/` |

No cargar en bloque los 34 YAML ni la construcción previa. Buscar primero por fuente o entidad con `rg`.

## Reglas

- Modificar únicamente `pre_productiva/` para cambios desplegables.
- Tratar `construccion_tecnica_previa/` como solo lectura, salvo una solicitud explícita de recuperación.
- No duplicar nuevamente jobs por tabla; el job activo recorre los YAML por fuente.
- Mantener sincronizados fuente, YAML, notebook, job, SQL y documentación operativa.
- Las ingestas permanecen en Parquet; el control plane permanece en Delta.
- No inventar tipos por nombre: se preservan/infiere desde semillas o se usa `STRING` explícito.
- No reintroducir JDBC, credenciales o conectividad a una base externa sin una decisión de arquitectura aprobada.
- No activar incrementalidad sin watermark y estrategia de borrados.
- No ejecutar ni modificar objetos remotos sin solicitud explícita.

## Seguridad

- Nunca guardar tokens, contraseñas, cadenas de conexión ni valores `dapi-...`.
- Usar Databricks Secret Scope/Azure Key Vault.
- Mantener placeholders de host, clúster y Git folder hasta recibir valores autorizados.

## Validación

1. Validar sintaxis del archivo modificado.
2. Comprobar rutas con `rg`.
3. Confirmar cobertura de los 34 YAML.
4. Verificar ausencia de secretos.
5. No afirmar éxito remoto si solo se validó localmente.
