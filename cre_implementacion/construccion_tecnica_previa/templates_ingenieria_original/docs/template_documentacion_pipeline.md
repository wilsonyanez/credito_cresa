# Plantilla de Documentación de Pipeline (CRESA)

## 1. Metadata del artefacto

| Campo | Valor |
|---|---|
| Nombre del pipeline | `job_<capa>_<dominio>_<entidad_o_producto>` |
| Capa | Silver / Gold |
| Dominio oficial | Cliente / Producto |
| Fuente(s) | Pendiente — referenciar tablas ya existentes en `bronze`/`gold` de `dlh_cresa` |
| Destino(s) | Pendiente |
| Owner técnico | Data Engineering (Miguel Espinosa / equipo D&A CRESA) |
| Data Owner | Pendiente de designación — ver `analisis_caracterizacion/06_hipotesis_validacion.md` #2 |
| Data Steward | Pendiente |
| Estado | temporal / validado / certificado |
| Versión | `v0.1.0` |
| Fecha última actualización | `YYYY-MM-DD` |

## 2. Objetivo

Describir en un párrafo qué hace el pipeline, qué problema resuelve y qué caso de uso (CU-01 a CU-13) habilita.

## 3. Alcance

Incluye:
- Tablas/entidades/productos procesados.
- Reglas aplicadas.
- Salidas generadas.

No incluye:
- Renombrar o mover tablas Bronze/staging ya existentes.
- Resolver decisiones de negocio pendientes (ver `06_hipotesis_validacion.md`) — el pipeline debe poder correr con la regla en estado "pendiente" sin bloquearse.

## 4. Configuración YAML

| Archivo | Propósito |
|---|---|
| `config/silver/<dominio>.<entidad>.yml` | Parámetros de conformación Silver |
| `config/gold/<dominio>.<producto>.yml` | Contrato y publicación Gold |
| `config/environments/prod.yml` | Único ambiente real hoy en CRESA |

## 5. Parámetros de ejecución

| Parámetro | Obligatorio | Ejemplo | Descripción |
|---|---:|---|---|
| `config_path` | Sí | `/Repos/cresa-datahub/config/gold/cliente.dw_cresa_cliente_campos_salesforce.yml` | Ruta del YAML |
| `environment` | Sí | `prod` | Único ambiente disponible hoy |
| `batch_id` | No | `auto` | Identificador del lote |
| `run_mode` | Sí | `initial` / `delta` / `reprocess` | Modo de ejecución |
| `dry_run` | No | `false` | Valida sin persistir |

## 6. Entradas

| Entrada | Tipo | Llave esperada | Observaciones |
|---|---|---|---|
| Pendiente | Tabla `dlh_cresa.bronze.*` / `dlh_cresa.gold.*` | `num_identificacion` / `cod_producto` | Pendiente |

## 7. Salidas

| Salida | Capa | Catálogo.Esquema.Tabla | Granularidad |
|---|---|---|---|
| Pendiente | Silver / Gold | `dlh_cresa.<schema>.<tabla>` | Pendiente |

## 8. Lógica paso a paso

1. Leer parámetros de ejecución.
2. Leer YAML y validar llaves obligatorias.
3. Resolver secretos vía `keyvaultdlh01` (Managed Identity ya desplegada).
4. Leer fuentes Bronze/Gold ya existentes.
5. Aplicar reglas de la capa (conformación en Silver, certificación en Gold).
6. Persistir salida Delta en `dlh_cresa`.
7. Registrar ejecución en `audit01.gobierno_<capa>_*`.
8. Publicar métricas de control.

## 9. Reglas aplicadas

| Regla | Tipo | Capa | Acción | Criticidad |
|---|---|---|---|---|
| Pendiente | not_null / duplicate / cross_source_reconciliation / contract | Silver / Gold | flag / reject / warn | baja / media / alta / crítica |

## 10. Control plane

| Tabla de control | Uso |
|---|---|
| `dlh_cresa.audit01.gobierno_silver_reglas` | Reglas aplicadas en Silver |
| `dlh_cresa.audit01.gobierno_silver_resultados` | Resultado de reglas diagnósticas Silver |
| `dlh_cresa.audit01.gobierno_gold_certificacion` | Estado de certificación por producto Gold |
| `dlh_cresa.audit01.gobierno_gold_publicacion` | Publicaciones hacia Salesforce/RELEX/Power BI |

## 11. Reproceso

Indicar cómo reprocesar por lote, por rango de fechas o full, sin romper watermarks productivos de las fuentes ya existentes (Dynamics OData, Fivetran).

## 12. Observabilidad

| Métrica | Umbral esperado | Acción si falla |
|---|---:|---|
| Filas leídas | Pendiente | Revisar fuente/configuración |
| Filas escritas | Pendiente | Revisar filtros o reglas |
| % rechazado en Gold | Pendiente | Escalar a Data Steward |
| Duración | Pendiente | Revisar plan de ejecución |

## 13. Purview

Indicar collection, términos de glosario, owner, steward, sensibilidad y estado de certificación — **condicionado a confirmar que Purview esté desplegado** (ver `06_hipotesis_validacion.md` #1). Si no lo está, documentar aquí mismo en vez de en Purview.

## 14. Checklist de despliegue

- [ ] YAML validado.
- [ ] Notebook parametrico probado (único ambiente real: `prod` — extremar precaución, no hay DEV/TEST).
- [ ] Tablas de control en `audit01` actualizadas.
- [ ] Permisos definidos en Unity Catalog (pendiente cerrar `account users` con `ALL_PRIVILEGES`).
- [ ] Purview actualizado (si aplica).
- [ ] Documentación revisada por Data Engineering.
- [ ] Visto bueno de Data Owner / Data Steward cuando estén designados.
