# Hipótesis a Validar y Decisiones a Escalar (CRESA, Fase 3)

> Consolidado de `../../Implementación/ROADMAP_GOBIERNO_DATOS.md` §5 y `MAPEO_CASOS_USO_FUENTES.md` §8, en el mismo formato de "hipótesis a validar con datos reales" que usa Almar Fase 3. Ninguno de estos puntos es resoluble desde el equipo técnico — todos requieren una persona o comité específico.

## 1. Microsoft Purview: ¿está desplegado, en qué estado?

**Hipótesis actual**: no está desplegado. Evidencia: cero menciones en 22 transcripciones de 4 meses de proyecto; sin evidencia en `ARQUITECTURA_DESPLEGADA_VS_TOBE.md`.
**Por qué es crítico**: la Arquitectura To-Be lo fija como plataforma base desde el inicio (no diferido). Si no existe, hay que replanificar el capítulo completo de gobierno técnico (cap. 7).
**A quién escalar**: Miguel Espinosa / Roque Cuenca.
**Cómo se valida**: solicitar acceso de lectura al portal de Purview de la cuenta Azure de CRESA, o confirmación directa de despliegue/no despliegue.

## 2. Data Owner de Producto sin designar

**Hipótesis actual**: sigue sin designarse (hito venció 13 jun 2026).
**Por qué es crítico**: bloquea la validación de calidad del catálogo de Producto, requerida antes del **22 de septiembre de 2026** (fecha RELEX).
**A quién escalar**: Comité Directivo.
**Cómo se valida**: acta de designación formal o confirmación en la próxima sesión del Comité Directivo.

## 3. Reconciliar `CreditLimit` (Dynamics) vs. cupo real (CrediCresa)

**Hipótesis actual**: son dos nociones de crédito distintas que conviven sin resolver — `CreditLimit` está 100% poblado en Dynamics pero probablemente no representa el cupo real que gestiona CrediCresa/Resuelve.
**Por qué es crítico**: sin esta decisión, `cupo_disponible` del golden record de Cliente puede calcularse sobre la fuente equivocada — afecta directamente CU-03/CU-04.
**A quién escalar**: Mauricio Ponce (Data Owner natural de Crédito).
**Cómo se valida**: comparar una muestra de clientes con ambos valores y pedir a Crédito que confirme cuál es la fuente de verdad; documentar la regla de reconciliación en `BOSQUEJO_TABLAS_CURADAS.md`.

## 4. Alcance real de BusinessIT/Handytech: ¿2 o 5 dominios de gobierno?

**Hipótesis actual**: según la reunión interna del 26 de marzo de 2026 (no explícito en documentos formales), Handytech no solo moderniza la arquitectura de Financiero/Crédito/Operaciones, sino que también los implementa como dominios de gobierno completos bajo la misma metodología de Azurian.
**Por qué es crítico**: cambia sustancialmente el tamaño real del programa (2 dominios de Azurian vs. 5 dominios totales) y determina si Fase 3 de Azurian debe coordinar activamente con Handytech en convenciones compartidas (ver `11_convenciones_nombramiento_databricks.md`).
**A quién escalar**: Javier Jácome / Vladimir Portillo (Handytech).
**Cómo se valida**: confirmar por escrito el alcance contractual de Handytech, o revisar el Plan de Implementación de 26 actividades de Handytech si se consigue (ver `CONTEXTO_PROYECTO.md` §10).

## 5. Definición `DISPO` vs. `EXH` para inventario (RELEX)

**Hipótesis actual**: sin definir cuál vista de inventario usar bloquea la validación de la interface `Balances` de RELEX, marcada como crítica (10/10) en el Interface File Assessment.
**Por qué es crítico**: es una decisión de negocio, no técnica — bloquea directamente el core de Forecasting/Replenishment antes del 22 de septiembre.
**A quién escalar**: Negocio/Compras (Sonnia Villacis, Verónica Ordóñez).
**Cómo se valida**: sesión de definición formal, documentar la decisión y actualizar el assessment de RELEX.

## 6. Fecha real de entrega del golden record

**Hipótesis actual**: inconsistente entre sesiones — se ha mencionado "octubre 2026" y también "Q4 2026/2027" según a quién se le pregunte.
**Por qué es crítico**: sin una fecha única acordada, no hay forma de secuenciar el resto del roadmap con confianza.
**A quién escalar**: Xavier Jácome / Comité Directivo.
**Cómo se valida**: confirmar en la próxima sesión de seguimiento y dejarlo escrito en `CONTEXTO_PROYECTO.md`.

## 7. Dueño del esquema `fivetran_log` (ingesta sin dueño identificado)

**Hipótesis actual**: es una ingesta activa (10 tablas) sin que ningún documento ni transcripción identifique qué sistema origen alimenta ni quién la administra.
**Por qué es crítico**: es un quick win de gobierno (bajo esfuerzo) que cierra un gap de trazabilidad concreto — hoy hay una fuente de datos corriendo sin dueño documentado.
**A quién escalar**: Miguel Espinosa.
**Cómo se valida**: pregunta directa + revisión de configuración del conector Fivetran.

## 8. Fuga de datos ya ocurrida (captura de pantalla de Power BI) sin DLP

**Hipótesis actual**: ya es un incidente confirmado, no un riesgo teórico.
**Por qué es crítico**: evidencia que el gap de seguridad (CIS 03, 13/14 controles sin implementar) ya tiene impacto real, no solo teórico.
**A quién escalar**: Gustavo García (Oficial de Seguridad).
**Cómo se valida**: confirmar si ya se abrió un caso formal de incidente y si se implementó alguna medida de DLP desde entonces.

## 9. Iniciativa de IA no oficial (LLM local + n8n)

**Hipótesis actual**: shadow IT real, fuera del radar de seguridad y del alcance formal del programa DataOn.
**Por qué es crítico**: el gobierno de datos debería al menos registrarla, aunque esté fuera de alcance de remediar directamente.
**A quién escalar**: Gustavo García / Comité Directivo.
**Cómo se valida**: inventariar qué datos consume esa iniciativa y si toca información de Cliente/Producto/Crédito.
