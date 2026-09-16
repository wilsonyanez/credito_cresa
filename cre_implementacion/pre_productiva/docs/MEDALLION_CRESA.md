> **Revisión de consistencia — 2026-09-16.** Antecedente documental o evidencia fechada. Para nombres, capacidad, estado de acceso y operación actuales prevalecen el [estado vigente](ESTADO_VIGENTE.md), la [arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y el [informe extendido](20_CRESA_MDM_ANALISIS_EXTENDIDO.md). Los comandos, límites y resultados anteriores del contenido siguiente se conservan como antecedentes; no acreditan un despliegue MDM ni una ejecución actual.

# Adaptación Medallion CRESA

## Hallazgos

El despliegue sin -Deploy únicamente valida. El paquete previo tenía tres tareas
(fuente, Bronze y verificación); Silver y Gold solo tenían esquemas vacíos.
La revisión histórica del 2026-09-07 registra Job y Bronze ausentes después de un
despliegue anterior exitoso. No hay evidencia suficiente para atribuir su ausencia
a un fallo específico del último comando del usuario: falta su salida de ejecución.

## Referencias inspeccionadas

C:/desa/git/almar/Fase 3/templates_ingenieria contiene configuración de fuente,
ambiente, ingesta, entidad Silver, producto Gold, notebook genérico y documentación.
Se revisaron silver_entity_template.yml y gold_product_template.yml: Silver marca
problemas sin descartar; Gold declara contrato, certificación y control de publicación.
No se copian fuentes, llaves, estados ACTIVO ni reglas de producción acuícola de Almar.

El documento local CRESA_LINEAMIENTOS_ETL_LOGICA_NEGOCIO_v1.1.docx permite productos
temporales y pending_business_rule. Su sección 18.4 establece Jobs API 2.1+ como base
y condiciona Lakeflow Designer. El paquete mantiene el requisito vigente de Parquet.

## Implementación técnica disponible

Un Job por fuente: fuente -> Bronze -> Silver -> Gold -> verificar. Las 34 vistas
Silver y las 34 Gold mantienen el mismo contrato tipado y las filas de la capa
anterior; son snapshots temporales para validación técnica. Se implementan ahora diagnósticos agregados de calidad; véase [reglas aplicables](REGLAS_ALMAR_CRESA.md). No hay limpieza,
homologación, deduplicación, SCD, cálculo de cupo ni certificación implícitos.
Las configuraciones por capa aceptan exclusivamente este modo y rechazan cambios
no soportados. No son una implementación completa de los contratos normativos de
entidades/productos del documento v1.1 ni sustituyen sus JSON Schema.

Datos en Parquet, control de ejecuciones en Delta audit01.credicresa_medallion_runs.
Cada capa ejecuta dry_run antes de escribir; requiere control plane incluso en
lectura. Un fallo deja el Job fallido; la publicación de varias entidades no es
atómica. Los snapshots anteriores permanecen disponibles. Bootstrap crea vistas
vacías si no existen registros fuente. La verificación revisa propiedad, tipos y
conteos, sin afirmar calidad o certificación de negocio.

La reversa admite manifiestos completos antiguos de 68 vistas o nuevos de 136,
y limita la eliminación al inventario validado y marcado. No se ejecutó reversa.

## Pendientes para completar el alcance funcional

Confirmar si se requiere un objeto Lakeflow independiente y resolver su diseño con
la restricción Parquet. Definir productos CRESA, fuentes, granularidad, llaves,
reglas, propietarios y consumidores; los ejemplos Cliente/Salesforce del documento
usan fuentes Dynamics y SIAC que no pertenecen a las 34 entidades credicresa.
No se inventan esas dependencias ni se crean productos aparentemente certificados.

Validación y preparación local no prueban creación remota. Ejecutar el despliegue
con -Deploy solo con solicitud explícita; revisar el run y las cinco tareas.

## Validación local

35 pruebas unitarias satisfactorias; cobertura de 34 YAML/451 atributos;
sintaxis Python y dependencias de los cinco notebooks verificadas. No se ejecutó
Spark ni Databricks: los ensayos nuevos del runtime usan dobles de prueba.
La revisión del notebook de Almar confirmó JDBC/Delta y auditoría mediante print;
se adaptó el patrón de etapas, conservando el runtime Parquet y auditoría Delta real
del paquete CRESA, sin importar ese notebook como ejecutable.

Ampliación posterior: 43 pruebas locales y motor diagnóstico en ambas capas. La cifra anterior de 35 pruebas corresponde a la base previa.
