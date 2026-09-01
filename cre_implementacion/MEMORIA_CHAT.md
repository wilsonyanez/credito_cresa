# Memoria del chat — CRESA Fase 3

## Información general

| Campo | Valor |
|---|---|
| Proyecto | CRESA — Fase 3, Gobierno e ingesta de datos |
| Plataforma objetivo | Azure Databricks |
| Alcance técnico actual | Pruebas del nivel Bronze |
| Fecha de consolidación | 31 de agosto de 2026 |
| Zona horaria | America/Guayaquil |
| Ruta del proyecto | `C:\desa\git\credito_cresa\cre_implementacion` |

## Propósito de esta memoria

Registrar las preguntas y solicitudes realizadas durante la sesión, las sugerencias emitidas, las decisiones adoptadas y los archivos construidos. Este documento no contiene credenciales, tokens ni datos sensibles.

---

## 1. Análisis inicial y optimización del consumo

### Solicitud

> Analizar el repositorio en el que estamos trabajando y construir el Markdown del proyecto para optimizar el consumo.

### Análisis y sugerencias

- El repositorio era principalmente documental y contenía numerosas configuraciones repetitivas.
- Se recomendó evitar cargar en contexto todos los Markdown, JSON y YAML en cada tarea.
- Se sugirió utilizar lectura selectiva según capa, entidad o necesidad.
- Se identificó una diferencia entre el README histórico y el árbol real: ya existían YAML, JSON y scripts de jobs aunque parte de la documentación indicaba que todavía no había implementación.

### Resultado

- Se creó `AGENTS.md` con instrucciones de lectura selectiva, seguridad, validación y navegación del proyecto.
- Posteriormente se actualizó para reflejar la estructura reorganizada y la nueva arquitectura completamente interna en Databricks.

---

## 2. Configuración inicial de Databricks Connect

### Solicitud

> El desarrollo se probará en Databricks. Se necesita conectar el repositorio y una base Microsoft SQL local. Ayudar a configurar Databricks Connect.

### Sugerencias emitidas

- Databricks Connect permite ejecutar Spark remoto desde el IDE, pero no sincroniza Git.
- La versión de `databricks-connect` debe corresponder al Databricks Runtime.
- Se recomendó autenticación OAuth mediante un perfil de Databricks CLI.
- Se explicó que `localhost` desde Spark remoto no representa el computador del desarrollador.
- Para una base local se habría requerido VPN, ExpressRoute u otra ruta privada.

### Archivos construidos

- Script de preparación local de Databricks Connect.
- Archivo de variables de ejemplo sin secretos.
- Prueba mínima no destructiva de sesión.
- Guía de Databricks Connect.

### Decisión posterior

La conexión a Microsoft SQL Server fue descartada. Databricks Connect se conserva únicamente como herramienta de desarrollo local contra el workspace.

---

## 3. Recreación de entidades para pruebas

### Pregunta

> ¿Es posible crear las entidades de Microsoft SQL en una base de datos de Databricks para realizar pruebas?

### Sugerencias emitidas

- Crear un catálogo aislado, inicialmente denominado `cresa_dev`.
- No utilizar el catálogo productivo para pruebas.
- Considerar tres alternativas:
  1. Exportaciones Parquet o CSV.
  2. Copia JDBC, si existiera conectividad.
  3. Datos sintéticos.
- Preferir Parquet para conservar los tipos.
- Anonimizar datos sensibles.

### Decisión vigente

La base fuente se recreará dentro de Databricks, sin conexión a una base externa.

---

## 4. Construcción de archivos base desde los YAML

### Solicitud

> En el repositorio están todos los YAML necesarios para probar. Construir los archivos base para cargar y crear en Databricks.

### Hallazgos

- Se localizaron 34 YAML activos de ingesta.
- Los YAML enumeran tablas y columnas, pero no contienen tipos de datos completos.
- Algunos YAML tenían estructuras no estrictas, por ejemplo claves primarias sin indicador de lista.
- Se construyó un lector tolerante para obtener `source_table`, tabla destino y `columns.include`.

### Sugerencias emitidas

- Usar semillas Parquet cuando se necesiten tipos reales.
- Crear tablas vacías con columnas `STRING` solamente para validar contratos y orquestación.
- No inferir tipos a partir del nombre de una columna.
- Corregir progresivamente la sintaxis YAML antes de exigir un parser estricto.

### Resultado

Se construyeron notebooks y SQL base para crear el ambiente, cargar entidades y validar tablas.

---

## 5. Organización de pipelines por fuente

### Solicitud

> Organizar los pipelines. Existía uno por cada YAML y se necesitaba un mismo pipeline recursivo para recorrer toda la ingesta de una fuente, caracterizarla e inferir tipos.

### Sugerencias y decisiones

- Reemplazar el modelo de un job por tabla por un job por fuente.
- Descubrir recursivamente los YAML mediante un patrón `**/*.yml`.
- Ejecutar inicialmente de forma secuencial para controlar carga y errores.
- Continuar por las demás entidades si una falla y marcar el resultado global como parcial o fallido.
- Generar datos y caracterización en Parquet.
- Registrar diferencias entre columnas observadas y `columns.include`.
- Conservar todas las columnas observadas en la fuente recreada.

### Resultado

- Se creó un job consolidado por fuente.
- El job contiene actualmente dos tareas:
  1. Garantizar o recrear las tablas fuente internas.
  2. Ejecutar la ingesta de la fuente hacia Bronze.
- Los jobs individuales quedaron archivados y no deben desplegarse.

---

## 6. Construcción del control plane

### Solicitud

> Generar el script de creación del control plane y permitir que el pipeline registre sobre él las ingestas.

### Sugerencia de arquitectura

- Mantener datos Bronze y metadatos de caracterización en Parquet.
- Utilizar Delta únicamente para el control plane, porque requiere actualizaciones transaccionales del estado de ejecución.

### Objetos construidos

En `cresa_dev.audit01`:

| Objeto | Propósito |
|---|---|
| `ingestion_runs` | Cabecera y estado global de la ejecución |
| `ingestion_table_runs` | Resultado, conteos, tiempos y errores por tabla |
| `ingestion_columns` | Diccionario técnico observado durante cada ejecución |
| `ingestion_watermarks` | Preparación para futuras cargas incrementales |
| `v_latest_ingestion_run` | Última ejecución por fuente |
| `v_ingestion_errors` | Errores por entidad |

### Estados definidos

```text
RUNNING
SUCCEEDED
PARTIAL
FAILED
```

---

## 7. Reorganización del repositorio

### Solicitud

> Organizar toda la estructura en documentación/insumos, construcción técnica previa y pre-productiva.

### Estructura adoptada

```text
cre_implementacion/
├── documentacion_insumo/
├── construccion_tecnica_previa/
└── pre_productiva/
```

### Propósito de cada carpeta

- `documentacion_insumo/`: análisis, matrices, arquitectura y diagramas; no desplegable.
- `construccion_tecnica_previa/`: jobs individuales, JSON duplicados, scripts y prototipos reemplazados; solo trazabilidad.
- `pre_productiva/`: única fuente autorizada para pruebas y despliegue.

### Sugerencias emitidas

- No desplegar `construccion_tecnica_previa/`.
- No volver a crear jobs individuales por tabla.
- Modificar únicamente `pre_productiva/` para cambios desplegables.
- Mantener las rutas antiguas solo como referencia histórica.

---

## 8. Checklist de despliegue

### Solicitud

> Construir un checklist para controlar y ejecutar las acciones necesarias para desplegar los archivos en Databricks, incluyendo revisión, debate y aprobación.

### Resultado

Se creó:

`pre_productiva/docs/CHECKLIST_DESPLIEGUE_DATABRICKS.md`

### Contenido sugerido

- Revisión de arquitectura y alcance.
- Validación local.
- Creación del ambiente Databricks.
- Revisión de semillas y tipos.
- Recreación controlada de la base fuente.
- Despliegue del job en estado pausado.
- Prueba en seco de una entidad.
- Ejecución por olas.
- Reversa y aprobaciones finales.

---

## 9. Corrección de arquitectura: sin Microsoft SQL Server

### Solicitud

> Se detectó un error: no habrá conexión a Microsoft SQL. La base de datos será recreada dentro de Databricks con los artefactos existentes.

### Cambios aplicados

- Se eliminó la configuración JDBC del paquete activo.
- Se eliminaron las consultas `custom_sql` de los 34 YAML activos.
- Cada YAML utiliza ahora:

  ```yaml
  read:
    mode: table
  ```

- Se configuró `source_type: databricks`.
- Se creó `cresa_dev.credito_cresa_source` como fuente interna.
- El pipeline utiliza `spark.table` y no JDBC.
- Las consultas originales se preservaron únicamente en la construcción técnica previa.

### Política de tipos

- Semilla Parquet: conserva el esquema.
- Semilla CSV: Spark infiere el esquema y requiere revisión.
- Sin semilla: tabla vacía con columnas `STRING`.

---

## 10. Arquitectura Medallion y alcance Bronze

### Solicitud

> Proporcionar un paso a paso para desplegar en Databricks, crear las carpetas de la arquitectura Medallion y los volúmenes necesarios, considerando que las pruebas solo corresponden a Bronze.

### Decisiones

- Crear los esquemas Medallion:

  ```text
  cresa_dev.bronze
  cresa_dev.silver
  cresa_dev.gold
  ```

- Silver y Gold se crean vacíos y quedan fuera del alcance funcional.
- Crear además:

  ```text
  cresa_dev.landing
  cresa_dev.credito_cresa_source
  cresa_dev.audit01
  ```

- Volúmenes vigentes:

  ```text
  cresa_dev.landing.source_seed
  cresa_dev.bronze.data
  ```

- Ruta de salida Bronze:

  ```text
  /Volumes/cresa_dev/bronze/data/credito_cresa/
  ```

### Orden sugerido

1. Conectar el repositorio como Git folder.
2. Crear catálogo, esquemas y volúmenes.
3. Crear el control plane.
4. Cargar semillas opcionales.
5. Recrear una tabla fuente.
6. Ejecutar una prueba en seco.
7. Ejecutar una carga real de una tabla.
8. Avanzar por olas.
9. Ejecutar las 34 configuraciones.
10. Habilitar programación únicamente después de aprobación.

---

## 11. Notebook único para despliegue Bronze

### Solicitud

> Crear un archivo notebook descargable para utilizarlo durante el despliegue en Databricks.

### Resultado

Se creó:

`pre_productiva/notebooks/00_deploy_bronze.py`

Es un notebook Databricks Source importable directamente.

### Acciones que ejecuta

- Valida parámetros y restringe el catálogo a `cresa_dev`.
- Crea catálogo, esquemas Medallion y esquemas técnicos.
- Crea los volúmenes Landing y Bronze.
- Crea las tablas y vistas del control plane.
- Invoca opcionalmente la recreación de tablas fuente.
- Comprueba que Silver y Gold permanezcan vacíos.
- No crea ni habilita jobs automáticamente.

### Parámetros recomendados para la primera prueba

```text
catalog: cresa_dev
git_folder_path: /Workspace/<ruta-real-del-repositorio>
create_source_tables: true
seed_format: parquet
table_filter: ^sis_peticiones$
replace_existing_source: false
```

### Protección incluida

`replace_existing_source=true` exige un filtro explícito, evitando reemplazar accidentalmente las 34 tablas fuente.

---

## Archivos activos principales

| Propósito | Ruta |
|---|---|
| Guía general | `README.md` |
| Guía pre-productiva | `pre_productiva/README.md` |
| Checklist | `pre_productiva/docs/CHECKLIST_DESPLIEGUE_DATABRICKS.md` |
| Despliegue Bronze | `pre_productiva/notebooks/00_deploy_bronze.py` |
| Recreación de fuente | `pre_productiva/notebooks/01_create_source_database.py` |
| Pipeline Bronze | `pre_productiva/notebooks/ingest_databricks_source_to_parquet.py` |
| Fuente | `pre_productiva/config/sources/credito_cresa.yml` |
| YAML activos | `pre_productiva/config/ingestion/` |
| Job consolidado | `pre_productiva/config/jobs/ingest_credito_cresa_source.json` |
| Ambiente | `pre_productiva/sql/00_create_test_environment.sql` |
| Control plane | `pre_productiva/sql/01_create_control_plane.sql` |
| Validador | `pre_productiva/scripts/validate_package.ps1` |

## Validaciones realizadas

- Se confirmó la existencia de 34 YAML activos.
- Los 34 YAML contienen configuración `read.mode`.
- No quedan consultas `custom_sql` en el paquete activo.
- No quedan lecturas JDBC en los notebooks activos.
- El JSON del job consolidado es válido.
- El paquete pre-productivo pasa el validador local.

Resultado registrado:

```text
OK: paquete pre-productivo válido; 34 YAML y job JSON correcto.
```

## Pendientes antes de ejecutar en Databricks

- Definir la ruta real del Git folder.
- Definir Databricks Runtime y cluster ID.
- Confirmar permisos de Unity Catalog.
- Aprobar catálogo `cresa_dev`.
- Definir tablas que tendrán semillas.
- Revisar tipos de las tablas creadas sin semilla.
- Sustituir los placeholders del job.
- Ejecutar primero `sis_peticiones` con filtro.
- Mantener el job pausado hasta aprobar el lote completo.

## Recomendaciones finales

- Usar exclusivamente `pre_productiva/` para el despliegue.
- Iniciar con una tabla y avanzar por olas.
- Preferir semillas Parquet.
- No considerar una tabla vacía con tipos `STRING` como validación funcional completa.
- Exigir estado `SUCCEEDED`; `PARTIAL` no equivale a éxito.
- No escribir en Silver o Gold durante estas pruebas.
- No reemplazar tablas sin filtro y aprobación explícita.
- Conservar las evidencias de ejecución y aprobaciones en el checklist.

