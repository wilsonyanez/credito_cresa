# RECOMENDACIONES TÉCNICAS — Ingesta `cat_tipoverificacion` (Fase 3 CRESA)

Documento: Recomendaciones y Buenas Prácticas  
Fecha: 2026-08-27  
Versión: 1.0  
Destinatario: Equipo de Datos - Maestro, Architects, DBA Team

---

## 📌 RECOMENDACIONES INMEDIATAS (Implementar Antes de Producción)

### 1. Designar Data Owner Oficial

**Estado Actual**: Vacante (hito vencido 13 jun 2026)  
**Impacto**: CRÍTICO — Bloquea validación de calidad

**Acción**:
- Escalar a Comité Directivo para designación formal
- Documentar en CONTEXT_PROYECTO.md
- Actualizar `governance.data_owner` en YAML con nombre/email

**Plazo**: Antes de 1 septiembre 2026

---

### 2. Validar Conexión SMTP de Alertas

**Estado Actual**: Configurada en YAML, pero no probada end-to-end

**Checklist**:
```
☐ Solicitar a Gustavo García (Oficial Seguridad):
  ☐ Credenciales SMTP (usuario/contraseña) para databricks-alerts@empresa.local
  ☐ Confirmación puerto 587 y TLS habilitado
  ☐ Whitelist de IPs Databricks en firewall

☐ En Databricks Admin Console:
  ☐ Workspace Settings → SMTP Settings
  ☐ Ingresar credenciales y host: smtp.empresa.local
  ☐ Realizar test: Send test email
  
☐ Ejecutar job en test:
  ☐ Proveedores de email verifican alertas en inbox
  ☐ Validar formato y contenido del email
```

**Plazo**: Antes de pasar a producción

---

### 3. Validación de Reconciliación `CreditLimit` vs. Cupo Real

**Estado Actual**: Pendiente decisión Crédito

**Impacto**: Afecta derivación de `cupo_disponible` en golden record Cliente

**Acciones Requeridas**:
- Contactar Mauricio Ponce (Data Owner Crédito)
- Comparar muestra de 1,000 clientes en ambas fuentes
- Documentar regla de reconciliación en BOSQUEJO_TABLAS_CURADAS.md
- Actualizar lógica de transformación Silver/Gold si aplica

**Plazo**: Antes de 22 septiembre 2026 (fecha RELEX)

---

### 4. Configurar DLP (Data Loss Prevention) Inmediatamente

**Estado Actual**: 0/14 controles CIS implementados; incidente confirmado (Power BI)

**Riesgos Identificados**:
- Exportaciones no auditadas desde Databricks SQL
- Capturas de pantalla con datos sensibles (PII: Documento, Teléfono)
- Shadow IT (LLM local + n8n)

**Implementar**:
```
☐ Databricks: Unity Catalog + Column-level encryption para PII
☐ Databricks: Row-level security (RLS) para datos Crédito
☐ SQL Server: Auditoría de conexiones (SQL Audit)
☐ Databricks: Activity Logs + alertas en Admin Console
☐ Power BI: RLS habilitado; no permitir exportación a Excel de datos Crédito
☐ Email: No permitir envío de reportes con Documento/Teléfono sin hash
```

**Responsable**: Gustavo García (Seguridad)  
**Plazo**: INMEDIATO (riesgo confirmado)

---

## ⚙️ RECOMENDACIONES ARQUITECTÓNICAS

### 5. Ajustar Watermark para Incremental Auténtico

**Estado Actual**: `incremental_mode: full_snapshot` (sin incremental real)

**Razón**: Tabla de control (`actualizado`) existe, pero ingesta es full cada vez

**Beneficio**: Reducir tiempo ejecución de 5 min a <1 min; menor carga SQL Server

**Implementación**:
```yaml
load_strategy:
  incremental_mode: delta_incremental  # ← Cambiar
  watermark_column: actualizado        # ← Ya configurado
  delta_lookback_days: 1               # ← Lookback para late arrivals
  delete_detection: true               # ← Detectar borrados
```

**Esfuerzo**: Bajo (YAML)  
**Plazo**: Fase 4 (post-octubre)

---

### 6. Implementar Particionamiento Dinámico

**Estado Actual**: Particionado por `estado` (0, 1) — muy simple

**Propuesta**: Particionar también por año/mes de `creado` para queries históricas más rápidas

```yaml
target:
  partition_by: [estado, YEAR(creado), MONTH(creado)]
  cluster_by: jerarquia
```

**Beneficio**: Queries de auditoría 10-50× más rápidas  
**Esfuerzo**: Bajo  
**Plazo**: Fase 4

---

### 7. Habilitar Z-Ordering para Consultas Frecuentes

**Nuevas métricas a rastrear en queries de Reporting**:
```sql
SELECT jerarquia, COUNT(*) FROM credito_cresa_cat_tipoverificacion
GROUP BY jerarquia;  -- Consulta típica

-- Solución: Z-Ordering
ALTER TABLE dlh_cresa.bronze.credito_cresa_cat_tipoverificacion
OPTIMIZE ZORDER BY jerarquia;
```

**Esfuerzo**: Minimal (1 comando)  
**Plazo**: Fase 4

---

## 🔒 RECOMENDACIONES DE SEGURIDAD

### 8. Clasificación de Datos Refinada

**Estado Actual**: "Confidencial" (L2) global

**Propuesta**: Clasificación por columna
```yaml
columns:
  include:
    - id              # L1 (público)
    - nombre          # L2 (confidencial — no publicar)
    - jerarquia       # L1 (público)
    - estado          # L1 (público)
    - creado          # L1 (público)
    - actualizado     # L1 (público)
    - creado_por      # L3 (PII — auditor solo)
    - actualizado_por # L3 (PII — auditor solo)
    - naturaleza      # L2 (confidencial)
```

**Implementar en Unity Catalog** (próxima fase)

---

### 9. Auditoría de Acceso a Tabla

**Actual**: Registrado en `audit01.log_procesos` (lectura/escritura del pipeline)

**Propuesta**: Habilitar Unity Catalog audit + Databricks System Tables

```sql
SELECT 
  request.user_agent,
  request.client_ip,
  request.user_identity.email,
  request.action_type,
  response.status_code,
  request.timestamp
FROM system.access.audit
WHERE object_name LIKE '%cat_tipoverificacion%'
  AND timestamp >= CURRENT_DATE - 7;
```

**Plazo**: Fase 4 (después Unity Catalog)

---

## 📊 RECOMENDACIONES DE MONITOREO

### 10. Crear Dashboard de Salud de Ingesta

**Métricas a Rastrear**:
```
┌─────────────────────────────────────────┐
│ Dashboard: Ingesta Catálogos            │
├─────────────────────────────────────────┤
│ ✓ Job Success Rate (últimas 30 días)   │
│ ✓ Tiempo Prom. Ejecución (5 min?)      │
│ ✓ Registros Ingesta vs. Crecimiento (%) │
│ ✓ Validaciones Fallidas (últimas 7d)   │
│ ✓ Alertas SMTP Enviadas (trend)         │
│ ✓ Filas por Hora (picos de carga)      │
│ ✓ Errores por Tipo (TOP 10)             │
└─────────────────────────────────────────┘
```

**Herramienta**: Databricks SQL + Tableau/Power BI  
**Esfuerzo**: 2-3 días  
**Plazo**: Antes de octubre (quién visualizará estado)

---

### 11. Establecer SLA (Service Level Agreement)

**Propuesta para cat_tipoverificacion**:

| Métrica | Target | Alerta |
|---|---|---|
| Disponibilidad | 99,5% | < 99% |
| Tiempo ejecución | < 5 min | > 10 min |
| Validaciones OK | 100% | < 95% |
| Latencia datos | < 1 día | > 2 días |
| Alertas SMTP | < 5/mes | > 10/mes |

**Responsable**: Data Platform Team  
**Plazo**: Antes de octubre

---

## 📝 RECOMENDACIONES DOCUMENTACIÓN

### 12. Crear Runbook Operativo Integrado

**Falta**: Procedimiento de "qué hacer si X falla"

**Crear documento**:
```
RUNBOOK_cat_tipoverificacion_troubleshooting.md
├─ Job no ejecuta (no en schedule)
├─ Job tarda > 10 minutos
├─ Validación falla con PK duplicadas
├─ Tabla Bronze no aparece
├─ Email de alerta no llega
├─ Datos incompletos vs. SQL Server
└─ Recover de la última ejecución buena
```

**Esfuerzo**: 1 día  
**Plazo**: Antes de octubre

---

### 13. Documentar Cambios Futuros en Fuente

**Problema**: Si SQL Server agrega columna, ¿quién actualiza YAML?

**Solución**:
```
Crear: SCHEMA_CHANGE_PROTOCOL_cat_tipoverificacion.md
├─ Quién notifica cambios: Responsable CREDITO_CRESA
├─ Quién actualiza YAML: Data Owner Maestro
├─ Validación: Test en ambiente DEV primero
├─ Aprobación: Data Governance Committee
└─ Deploy: Incluir en próximo release Fase 3
```

---

## 🎯 RECOMENDACIONES FUNCIONALES

### 14. Enriquecer Metadata de `naturaleza`

**Observación**: Columna `naturaleza` está restringida pero sin transformación

**Análisis SQL**:
```sql
SELECT DISTINCT naturaleza, COUNT(*) AS cnt
FROM CREDITO_CRESA.dbo.cat_tipoverificacion WITH (NOLOCK)
GROUP BY naturaleza
ORDER BY cnt DESC;
```

**Acción**: Mapear `naturaleza` a dominio de negocio (Ejemplo: "Documental", "Facial", "Biométrica", etc.)  
**Plazo**: Fase 4 (propuesta a negocio)

---

### 15. Crear Tabla de Concordancia para Histórico

**Problema**: Si `cat_tipoverificacion` se actualiza, ¿qué pasa con histórico?

**Solución**: Mantener tabla `cat_tipoverificacion_dim` con SCD Type 2

```sql
CREATE TABLE dlh_cresa.gold.cat_tipoverificacion_dim AS
SELECT 
  id,
  nombre,
  jerarquia,
  estado,
  naturaleza,
  CURRENT_TIMESTAMP() AS fecha_inicio,
  NULL AS fecha_fin,
  1 AS es_activo,
  ROW_NUMBER() OVER (PARTITION BY id ORDER BY actualizado DESC) AS version
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;
```

**Esfuerzo**: Medio  
**Plazo**: Fase 4 (propuesta a Dominios)

---

## 📋 TABLA RESUMEN RECOMENDACIONES

| # | Recomendación | Criticidad | Esfuerzo | Plazo | Responsable |
|---|---|---|---|---|---|
| 1 | Designar Data Owner | 🔴 CRÍTICO | Alto | 1 sep | Comité Directivo |
| 2 | Validar SMTP | 🔴 CRÍTICO | Bajo | Pre-prod | Data Platform |
| 3 | Reconciliar CreditLimit | 🔴 CRÍTICO | Alto | 22 sep | Crédito (Mauricio) |
| 4 | Implementar DLP | 🔴 CRÍTICO | Alto | INMEDIATO | Seguridad (Gustavo) |
| 5 | Incremental Auténtico | 🟡 IMPORTANTE | Bajo | Fase 4 | Data Platform |
| 6 | Particionamiento Dinámico | 🟡 IMPORTANTE | Bajo | Fase 4 | DBA |
| 7 | Z-Ordering | 🟡 IMPORTANTE | Minimal | Fase 4 | DBA |
| 8 | Clasificación por Columna | 🟡 IMPORTANTE | Bajo | Fase 4 | Governance |
| 9 | Auditoría Unity Catalog | 🟡 IMPORTANTE | Medio | Fase 4 | Seguridad |
| 10 | Dashboard Monitoreo | 🟢 RECOMENDADO | Medio | Oct | Data Platform |
| 11 | Establecer SLA | 🟢 RECOMENDADO | Bajo | Oct | Data Platform |
| 12 | Runbook Operativo | 🟢 RECOMENDADO | Bajo | Oct | Data Platform |
| 13 | Protocolo de Cambios | 🟢 RECOMENDADO | Bajo | Oct | Governance |
| 14 | Enriquecer `naturaleza` | 🔵 FUTURO | Medio | Fase 4 | Negocio |
| 15 | Tabla SCD Type 2 | 🔵 FUTURO | Medio | Fase 4 | Dominios |

---

## ✅ CHECKLIST PRE-PRODUCCIÓN

Antes de activar job en Databricks Workflows (producción):

**Validaciones Técnicas**:
- [ ] YAML sintaxis correcta (parseable con Python `yaml`)
- [ ] JSON sintaxis correcta (validable con `jq`)
- [ ] Campos PII mapeados correctamente
- [ ] Reglas de validación probadas en test
- [ ] Alertas SMTP funcionan end-to-end
- [ ] Tabla Bronze creada sin errores
- [ ] Conteo de filas coincide con SQL Server (±1%)
- [ ] Cero duplicados por Primary Key
- [ ] Cero nulos en campos críticos

**Validaciones Funcionales**:
- [ ] Data Owner designado y confirmado
- [ ] Stakeholders notificados (Crédito, Negocio, DBA)
- [ ] Conocimiento transferido al equipo operativo
- [ ] Runbook disponible

**Validaciones de Seguridad**:
- [ ] PII campos enmascarados en logs
- [ ] Acceso a job limitado a roles correctos
- [ ] Secretos (SMTP) en Databricks Secrets, no hardcoded
- [ ] Auditoría habilitada en admin console

**Validaciones de Gobernanza**:
- [ ] Governance.data_owner poblado correctamente
- [ ] Purview collection asignado
- [ ] Linaje documentado
- [ ] Política de retención definida

---

## 🚨 PUNTOS DE ATENCIÓN CRÍTICOS

### A. Fecha Límite: 1 Octubre 2026 (Switch Salesforce)

Los campos `cupo_disponible`, `flag_contactable`, `optin_*`, `num_cuota_*` **DEBEN** estar listos.

**Dependencias**:
- cat_tipoverificacion ✓ (este job)
- Reconciliación CreditLimit ✗ (PENDIENTE)
- Golden record Cliente ✗ (Fase 3 Silver/Gold)

**Plan de Contingencia**: Si no está listo, switch se retrasa 2-4 semanas.

---

### B. Incidente de Seguridad Ya Confirmado

Fuga de datos en Power BI (captura de pantalla con Documento + Teléfono).

**Acciones Inmediatas Requeridas**:
1. Implementar DLP en Power BI (bloquear exportación)
2. Investigar quién accedió / cuándo
3. Comunicar a Comité de Riesgos
4. Documentar en risk register

---

### C. Shadow IT (LLM + n8n)

Iniciativa no documentada consumiendo datos potencialmente sensibles.

**Acción**: Inventariar fuentes de datos usadas; si incluye Cliente/Crédito, escalar a Seguridad.

---

## 📞 CONTACTOS Y ESCALACIÓN

| Rol | Nombre | Email | Teléfono | Tema |
|---|---|---|---|---|
| Data Owner | [POR ASIGNAR] | — | — | Decisiones datos |
| DBA | Team | dba-team@empresa.local | — | Rendimiento/Storage |
| Oficial Seguridad | Gustavo García | gustavo.garcia@empresa.local | — | DLP/Auditoría |
| Data Owner Crédito | Mauricio Ponce | mauricio.ponce@empresa.local | — | Reconciliación CreditLimit |
| Platform Lead | [TBD] | data-platform-team@empresa.local | — | Monitoreo/SLA |

---

## 📈 PRÓXIMOS PASOS

**Inmediato (Esta Semana)**:
1. Revisar este documento en sesión de equipo
2. Escalar puntos 1, 2, 4 a responsables
3. Ejecutar scripts de validación

**Corto Plazo (2 Semanas)**:
1. Completar pre-requisitos (DLP, Data Owner, CreditLimit)
2. Activar job en test
3. Validar alertas SMTP

**Mediano Plazo (1 Mes)**:
1. Activar job en producción
2. Monitorear 2 semanas
3. Crear dashboard

**Largo Plazo (Fase 4)**:
1. Implementar recomendaciones 5-15
2. Evaluar ROI de cambios propuestos

---

## 📝 Historial de Cambios

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-08-27 | Asistente IA | Creación inicial |
| — | — | — | — |

---

**Documento preparado para**: Equipo de Datos - Maestro, Arquitectura, Seguridad  
**Fase**: 3 — Gobierno de Datos (DataOn)  
**Período**: Agosto-Septiembre 2026  
**Criticidad**: Alta (preprod 1 oct 2026)  

---

**Generado por**: Asistente IA  
**Última revisión**: 2026-08-27  
**Formato**: Markdown (editable, versionable en Git)

