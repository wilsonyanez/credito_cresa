# RECOMENDACIONES TÉCNICAS — Ingesta `cat_estadoverificacion` (Fase 3 CRESA)

Documento: Recomendaciones y Buenas Prácticas  
Fecha: 2026-08-27  
Versión: 1.0  
Destinatario: Equipo de Datos - Maestro, Architects, DBA Team

---

## 📌 RECOMENDACIONES INMEDIATAS (Implementar Antes de Producción)

### 1. Designar Data Owner Oficial

**Estado Actual**: Vacante (heredado de cat_tipoverificacion)  
**Impacto**: CRÍTICO — Bloquea validación de calidad

**Acción**:
- Escalar a Comité Directivo para designación formal
- Quien sea Data Owner responsable también de ambas tablas (cat_tipoverificacion + cat_estadoverificacion)
- Actualizar `governance.data_owner` en ambos YAML

**Plazo**: Antes de 1 septiembre 2026

---

### 2. Validar Conexión SMTP End-to-End

**Estado Actual**: Configurada en YAML, no probada

**Checklist**:
```
☐ Solicitar a Gustavo García (Oficial Seguridad):
  ☐ Credenciales SMTP para databricks-alerts@empresa.local
  ☐ Confirmación puerto 587, TLS habilitado
  ☐ Whitelist IPs Databricks
  
☐ En Databricks Admin Console:
  ☐ Admin → Workspace Settings → SMTP
  ☐ Ingresar credenciales (usuario, contraseña, host, puerto)
  ☐ Send test email
  
☐ Ejecutar test:
  ☐ Trigger job en "test" mode
  ☐ Provocar alerta (validación fallida)
  ☐ Verificar email en inbox
```

**Plazo**: Antes de pasar a producción

---

### 3. Documentar Relación de Precedencia entre Tablas

**Observación Importante**: `cat_estadoverificacion` depende lógicamente de `cat_tipoverificacion`

**Acciones**:
```yaml
# En credito_cresa_cat_estadoverificacion.yml, añadir:
dependencies:
  - table: credito_cresa_cat_tipoverificacion
    reason: "tipo_verificacion es FK a cat_tipoverificacion.id"
    schedule_offset: "+15 minutes"  # Ejecutar 15 min después de cat_tipoverificacion
```

**En Databricks Workflows**: Si se implementa orquestación avanzada, crear workflow que ejecute en orden:
1. `cat_tipoverificacion` (03:00 AM)
2. `cat_estadoverificacion` (03:15 AM)

**Plazo**: Fase 4 (post-octubre)

---

### 4. Implementar DLP (Data Loss Prevention) — URGENTE

**Estado Actual**: 0/14 controles CIS implementados; incidente confirmado

**Campos Sensibles en `cat_estadoverificacion`**:
- `tipo_verificacion` (L2: Confidencial)
- `naturaleza` (L2: Confidencial)

**Implementar**:
```
☐ Databricks Unity Catalog: Aplicar Column-level encryption
☐ Databricks RLS: Row-level security para datos de Crédito
☐ SQL Server: Auditoría de accesos
☐ Power BI: Desactivar exportación a Excel de estos campos
☐ Email: Validar que alertas no expongan valores de tipo_verificacion
```

**Responsable**: Gustavo García (Seguridad)  
**Plazo**: INMEDIATO

---

## ⚙️ RECOMENDACIONES ARQUITECTÓNICAS

### 5. Mejorar Watermark para Incremental Real

**Estado Actual**: Aunque YAML menciona `watermark_column`, ingesta es full_snapshot

**Propuesta**:
```yaml
load_strategy:
  incremental_mode: true  # Habilitar auténtico
  watermark_column: "updated_at"  # Usar timestamp SQL Server
  delta_lookback_days: 2  # Lookback de 2 días para late arrivals
  delete_detection: true  # Detectar borrados en origen
```

**Beneficio**: Reducir tiempo de ejecución de 5 min → < 1 min  
**Esfuerzo**: Bajo (1-2 días)  
**Plazo**: Fase 4

---

### 6. Crear Tabla Dimensional con SCD Type 2

**Problema**: Si `cat_estadoverificacion` se actualiza, ¿qué pasa con histórico?

**Solución**: Mantener tabla `cat_estadoverificacion_dim` con versiones:

```sql
CREATE TABLE dlh_cresa.gold.cat_estadoverificacion_dim AS
SELECT 
  id,
  nombre,
  es_activo,
  tipo_verificacion,
  resolutivo,
  naturaleza,
  CURRENT_TIMESTAMP() AS fecha_inicio,
  NULL AS fecha_fin,
  1 AS es_actual,
  ROW_NUMBER() OVER (PARTITION BY id ORDER BY es_activo DESC) AS version
FROM dlh_cresa.bronze.credito_cresa_cat_estadoverificacion;
```

**Esfuerzo**: Medio (Silver pipeline)  
**Plazo**: Fase 4

---

### 7. Habilitar Z-Ordering para `tipo_verificacion`

```sql
ALTER TABLE dlh_cresa.bronze.credito_cresa_cat_estadoverificacion
OPTIMIZE ZORDER BY tipo_verificacion;
```

**Beneficio**: Queries que filtran por `tipo_verificacion` 10-50× más rápidas  
**Esfuerzo**: Minimal (1 comando)  
**Plazo**: Fase 4

---

## 🔒 RECOMENDACIONES DE SEGURIDAD

### 8. Clasificación Granular por Columna (Unity Catalog)

**Propuesta**:
```yaml
columns:
  - id              # L1 (público)
  - nombre          # L2 (confidencial)
  - es_activo       # L1 (público)
  - tipo_verificacion # L3 (RESTRICTO — no exponer sin audit)
  - resolutivo      # L2 (confidencial)
  - naturaleza      # L3 (RESTRICTO)
```

**Implementar en**: Próxima versión de Purview/Unity Catalog  
**Plazo**: Fase 4

---

### 9. Auditoría de Acceso — System Tables

**SQL para monitorear**:
```sql
SELECT 
  request.user_identity.email,
  request.action_type,
  response.status_code,
  request.timestamp
FROM system.access.audit
WHERE object_name LIKE '%cat_estadoverificacion%'
  AND timestamp >= CURRENT_DATE - 7;
```

**Plazo**: Cuando Unity Catalog esté disponible

---

## 📊 RECOMENDACIONES DE MONITOREO

### 10. Crear Dashboard de Salud de Catálogos

**Métricas a Rastrear**:
```
┌─────────────────────────────────────────┐
│ Dashboard: Ingesta Catálogos (v2)       │
├─────────────────────────────────────────┤
│ ✓ Job Success Rate (últimas 30 días)   │
│ ✓ Tiempo Prom. Ejecución                │
│ ✓ Cambio de Conteo % (alertar si >30%) │
│ ✓ Validaciones Fallidas                 │
│ ✓ Alertas SMTP Enviadas (trend)         │
│ ✓ Comparativa Tipoverificacion vs Estadoverificacion │
│ ✓ Errores por Tipo (TOP 10)             │
└─────────────────────────────────────────┘
```

**Esfuerzo**: 2-3 días  
**Plazo**: Antes de octubre

---

### 11. Establecer SLA para Ambas Tablas

**Propuesta**:

| Métrica | Target | Alerta |
|---|---|---|
| Disponibilidad | 99,5% | < 99% |
| Tiempo ejecución | < 5 min | > 10 min |
| Validaciones OK | 100% | < 95% |
| Cambio conteo OK | ±25% | > 50% |
| Alerts SMTP | < 5/mes | > 10/mes |

**Responsable**: Data Platform Team  
**Plazo**: Antes de octubre

---

## 📝 RECOMENDACIONES DOCUMENTACIÓN

### 12. Crear Runbook de Troubleshooting Integrado

**Falta**: "Qué hacer si X falla"

**Crear**:
```
RUNBOOK_cat_estadoverificacion_v1.md
├─ Job no ejecuta en schedule
├─ Job tarda > 10 minutos (lento)
├─ Validación falla: "PK duplicada" → acción
├─ Tabla Bronze no aparece → debug
├─ Email de alerta no llega → revisar SMTP
├─ Cambio de conteo > 50% → investigar
├─ Comparar vs. cat_tipoverificacion (precedencia)
└─ Recover de última ejecución buena
```

**Esfuerzo**: 1 día  
**Plazo**: Antes de octubre

---

### 13. Documentar Cambios de Schema en Origen

**Protocolo**:
```
Si en CREDITO_CRESA.dbo.cat_estadoverificacion se agregan/cambian columnas:

1. Quién notifica: Responsable CREDITO_CRESA/DB
2. Quién actualiza: Data Owner Maestro
3. Validación: Test en ambiente DEV primero
4. Aprobación: Data Governance Committee
5. Deploy: Incluir en próximo release
```

---

## 🎯 RECOMENDACIONES FUNCIONALES

### 14. Enriquecer Metadata de `naturaleza`

**Acción**: Mapear `naturaleza` a dominio de negocio

**Ejemplo SQL** (para entender valores):
```sql
SELECT DISTINCT naturaleza, COUNT(*) AS cnt
FROM CREDITO_CRESA.dbo.cat_estadoverificacion WITH (NOLOCK)
GROUP BY naturaleza
ORDER BY cnt DESC;
```

**Clasificación Propuesta**:
- "Documental" (verificación por documento)
- "Biométrica" (análisis facial/dactilar)
- "Conductual" (scoring)
- "Oficial" (consulta registros públicos)

**Plazo**: Fase 4 (cuando Data Owner sea asignado)

---

### 15. Validar Relación con Cat_Tipoverificacion

**Verificar en origen**:
```sql
-- Ver qué valores de tipo_verificacion existen
SELECT DISTINCT ev.tipo_verificacion, COUNT(*) AS cnt
FROM CREDITO_CRESA.dbo.cat_estadoverificacion ev WITH (NOLOCK)
LEFT JOIN CREDITO_CRESA.dbo.cat_tipoverificacion tv WITH (NOLOCK)
  ON ev.tipo_verificacion = tv.id
GROUP BY ev.tipo_verificacion
ORDER BY cnt DESC;

-- Si hay NULLs o IDs inválidos: ALERTAR
```

**Plazo**: Antes de producción

---

## 📋 TABLA RESUMEN

| # | Recomendación | Criticidad | Esfuerzo | Plazo | Responsable |
|---|---|---|---|---|---|
| 1 | Designar Data Owner | 🔴 CRÍTICA | Alto | 1 sep | Comité |
| 2 | Validar SMTP | 🔴 CRÍTICA | Bajo | Pre-prod | Platform |
| 3 | Documentar precedencia | 🟡 IMPORTANTE | Bajo | Oct | Governance |
| 4 | Implementar DLP | 🔴 CRÍTICA | Alto | INMEDIATO | Seguridad |
| 5 | Incremental auténtico | 🟡 IMPORTANTE | Bajo | Fase 4 | Platform |
| 6 | SCD Type 2 dim | 🟡 IMPORTANTE | Medio | Fase 4 | Engineers |
| 7 | Z-Ordering | 🟡 IMPORTANTE | Minimal | Fase 4 | DBA |
| 8 | Clasificación granular | 🟡 IMPORTANTE | Bajo | Fase 4 | Governance |
| 9 | Auditoría (System Tables) | 🟡 IMPORTANTE | Medio | Fase 4 | Seguridad |
| 10 | Dashboard monitoreo | 🟢 RECOMENDADO | Medio | Oct | Platform |
| 11 | Establecer SLA | 🟢 RECOMENDADO | Bajo | Oct | Platform |
| 12 | Runbook operativo | 🟢 RECOMENDADO | Bajo | Oct | Platform |
| 13 | Protocolo cambios schema | 🟢 RECOMENDADO | Bajo | Oct | Governance |
| 14 | Enriquecer naturaleza | 🔵 FUTURO | Medio | Fase 4 | Negocio |
| 15 | Validar FK con tipoverificacion | 🟡 IMPORTANTE | Bajo | Pre-prod | DBA |

---

## ✅ CHECKLIST PRE-PRODUCCIÓN (Final)

Antes de activar job en Databricks Workflows:

**Validaciones Técnicas**:
- [ ] YAML parseablecon Python yaml
- [ ] JSON válido con jq
- [ ] Campos L2/L3 mapeados correctamente
- [ ] Validaciones probadas end-to-end
- [ ] SMTP funcionando
- [ ] Tabla Bronze creada sin errores
- [ ] Conteo ≈ igual a SQL Server
- [ ] Cero duplicados por PK
- [ ] Cero nulos en críticos
- [ ] Dependencia con cat_tipoverificacion documentada

**Validaciones Funcionales**:
- [ ] Data Owner designado
- [ ] Stakeholders (Crédito, Negocio, DBA) notificados
- [ ] Runbook disponible

**Validaciones Seguridad**:
- [ ] PII campos enmascarados en logs
- [ ] Acceso limitado a roles correctos
- [ ] Secretos en Databricks Secrets
- [ ] Auditoría habilitada

**Validaciones Gobernanza**:
- [ ] governance.data_owner poblado
- [ ] Purview collection asignado
- [ ] Linaje documentado
- [ ] Retención definida

---

## 🚨 PUNTOS CRÍTICOS

### A. Fecha Límite: 1 Octubre 2026

Ambas tablas (`cat_tipoverificacion` y `cat_estadoverificacion`) deben estar productivas.

**Plan de Contingencia**: Si no está listo, comunicar a Comité 2 semanas antes.

### B. Incidente de Seguridad Confirmado

Fuga de datos en Power BI ya ocurrió.

**Acción**: Implementar DLP **inmediatamente** (no esperar a Fase 4).

---

## 📞 CONTACTOS ESCALACIÓN

| Rol | Email | Tema |
|---|---|---|
| Data Owner | [TBD] | Decisiones datos |
| DBA | dba-team@empresa.local | Rendimiento |
| Seguridad | gustavo.garcia@empresa.local | DLP/SMTP |
| Platform | data-platform-team@empresa.local | Monitoreo |

---

## 📈 PRÓXIMOS PASOS

**Inmediato**:
1. Revisar este documento en sesión equipo
2. Escalar puntos 1, 2, 4 a responsables
3. Ejecutar validación SMTP

**Corto Plazo (2 semanas)**:
1. Completar pre-requisitos
2. Activar jobs en test
3. Monitorear alertas

**Mediano Plazo (1 mes)**:
1. Activar en producción
2. Monitorear 2 semanas
3. Crear dashboard

**Largo Plazo (Fase 4)**:
1. Implementar recomendaciones 5-15
2. Evaluar ROI

---

**Documento preparado para**: Equipo de Datos - Maestro  
**Fase**: 3 — Gobierno de Datos (DataOn)  
**Período**: Agosto-Septiembre 2026  
**Criticidad**: Alta (preprod 1 oct 2026)  

