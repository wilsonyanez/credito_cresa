# Alineación de Dominios AS-IS / TO-BE con Fase 3 (CRESA)

## Punto de control

La caracterización técnica de Fase 3 debe respetar la taxonomía de dominios ya decidida en el AS-IS/To-Be. Para el análisis de tablas se usan agrupaciones operativas (p. ej. "campos habilitadores de Salesforce", "conformación de crédito"); esas agrupaciones son útiles para ordenar el trabajo, pero **no son dominios corporativos nuevos**.

## Dominios de datos oficiales del programa DataOn

| # | Dominio | Responsable | Estado de gobierno |
|---|---|---|---|
| 1 | Cliente | Azurian | Data Owner "propuesto" (Carlos Salame Illingworth), sin ratificar |
| 2 | Producto | Azurian | Data Owner sin designar |
| 3 | Financiero | Handytech / BusinessIT | Fuera del alcance directo de este documento |
| 4 | Crédito | Handytech / BusinessIT (referencia natural: Mauricio Ponce) | Opera hoy como "isla de datos" — servidores y analistas propios fuera del lake corporativo |
| 5 | Operaciones | Handytech / BusinessIT | Fuera del alcance directo de este documento |

⚠️ El número real de dominios de gobierno completos (2 que implementa Azurian + ¿3 que solo moderniza arquitectura, o 5 que implementa Handytech como gobierno completo?) es una decisión pendiente de confirmar — ver `06_hipotesis_validacion.md` #4.

## Dominios que gobierna Fase 3 (Azurian)

| Dominio | Rol en Fase 3 | Fuentes / capacidades relacionadas |
|---|---|---|
| Cliente | Dominio corporativo central — golden record fundacional | Dynamics 365, SIAC, CrediCresa (crédito como atributo, no como dominio propio en este documento), Vtex (pendiente), Venta Smart (pendiente) |
| Producto | Dominio corporativo central — golden record fundacional | Dynamics 365, RELEX (export activo), Salesforce (export en prueba) |

## Cómo reinterpretar las agrupaciones técnicas usadas en la caracterización

| Agrupación técnica usada | No debe leerse como | Debe leerse como |
|---|---|---|
| "Campos habilitadores de Salesforce" (`cupo_disponible`, `flag_contactable`, `optin_*`) | Dominio nuevo | Producto de datos cross-referencia entre Cliente y los atributos de Crédito que CRESA necesita exponer, sin que eso convierta Crédito en un dominio de Azurian |
| "Conformación de crédito" | Dominio nuevo | Insumo del golden record de Cliente — el dominio Crédito en sí sigue siendo responsabilidad de Handytech / Mauricio Ponce |
| "Canal/Origen" (`base_concrecion_cliente`) | Dominio nuevo | Subatributo del maestro de Cliente |
| "Jerarquía comercial de Producto" | Dominio nuevo | Subdominio/capacidad dentro de Producto |

## Implicación para Bronze, Silver y Gold

Bronze sigue organizado como está hoy — por fuente/sistema origen (`d365_*`, SIAC, CrediCresa), sin reorganizar. Silver y Gold deben etiquetar cada entidad conformada con:

- `dominio_oficial`: Cliente o Producto (los 2 que gobierna Azurian en esta fase).
- `origen_atributo`: de qué dominio/sistema viene el dato que se incorpora como atributo (p. ej. `cupo_disponible` tiene `dominio_oficial = Cliente`, `origen_atributo = Crédito/CrediCresa`).

Ejemplo:

| Entidad / producto | dominio_oficial | origen_atributo |
|---|---|---|
| `dw_cresa_maestro_cliente` | Cliente | SIAC, Dynamics 365 |
| `dw_cresa_cliente_campos_salesforce.cupo_disponible` | Cliente | Crédito (CrediCresa) — atributo incorporado, no dominio propio |
| `dw_cresa_maestro_producto` | Producto | Dynamics 365, RELEX |

## Ajuste recomendado para comunicación al cliente

> Fase 3 no redefine los 5 dominios del programa DataOn. Azurian profundiza en Cliente y Producto; los atributos de Crédito que el golden record de Cliente necesita (cupo, mora, contactabilidad) se incorporan como referencia, sin que eso implique que Azurian está gobernando el dominio Crédito — esa responsabilidad sigue siendo de Handytech/BusinessIT, con Mauricio Ponce como referencia natural de negocio.

## Riesgo que se corrige

Si se presentan "campos habilitadores de Salesforce" o "conformación de crédito" como un tercer dominio nuevo de Azurian, se genera confusión sobre el alcance contractual real (2 dominios) y se corre el riesgo de que el Comité Directivo entienda que Azurian está asumiendo trabajo de Crédito sin que eso esté explícitamente acordado.
