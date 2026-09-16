# 17 — CRESA: arquitectura y nomenclatura del MDM de clientes y productos

Revisión: **2026-09-16**. Estado: propuesta de arquitectura para Desarrollo; no constituye un despliegue. Cliente: **CRESA**. Proyecto: **mdm_clientes_productos**. Fuente de crédito existente: **credicresa**.


## 1. Capacidad y alcance de Desarrollo

Por definición suministrada por CRESA, **devstgdlh02 dispone de 1,2 TB y el espacio no restringe esta etapa**. Se elimina la capacidad como motivo para limitar la publicación al piloto de 14 entidades. La cobertura local continúa siendo 34 contratos CrediCresa; el MDM necesita además Dynamics, SIAC y otras fuentes detalladas en el informe.

Los 1,2 TB son capacidad disponible declarada por el cliente, no una medición de Azure realizada en esta revisión. Los 179.236.947 bytes medidos el 15 de septiembre cubren solo cuatro archivos Parquet; no representan el tamaño de los dos maestros. Se mantienen mediciones de bytes, filas y tiempos para operación y trazabilidad, sin convertirlas en un bloqueo por capacidad.

La arquitectura propuesta usa `dev_dlh_cresa` en Desarrollo y `dlh_cresa` en Producción. `cresa` sigue siendo el catálogo del piloto local. No se renombra ni adopta automáticamente ninguno. QA queda como `<catalogo_qa_autorizado>`; host, clúster, contenedor y Git folder de nuevos despliegues conservan placeholders hasta su definición autorizada.

## 2. Medallion y gobierno DAMA

Medallion organiza la madurez de los datos; DAMA orienta responsabilidades, metadatos, calidad, datos maestros, seguridad y ciclo de vida. **La estructura y los nombres siguientes son una propuesta de Arquitectura CRESA, no una nomenclatura prescrita por DAMA.** La solicitud denomina la referencia DAMA-DMBOOK3; se usa la grafía DAMA-DMBOK y queda pendiente validar con CRESA la edición y sus apartados aplicables. No se afirma conformidad certificada con una tercera edición: no se dispuso de su texto y la consulta web no pudo completarse.

| Esquema | Propósito | Persistencia del proyecto |
|---|---|---|
| `landing` | Recepción inmutable de paquetes y documentos asociados; no es una capa adicional de calidad Medallion | Archivos originales, manifiestos y extracción controlada |
| `bronze` | Captura fiel, tipada y trazable por fuente, entidad, corte y lote | Snapshots Parquet |
| `silver` | Conformación, equivalencias, normalización y diagnóstico de calidad | Snapshots Parquet; rechazos identificados, sin descarte silencioso |
| `gold` | Maestros y relaciones con reglas de supervivencia y certificación verificables | Snapshots Parquet publicados mediante vistas |
| `audit01` | Lotes, ejecuciones, calidad, linaje, decisiones de identidad y publicación | Tablas Delta de control; archivos de evidencia en volumen separado |

Las fuentes productivas Delta se leen como tablas. Si se requiere transferirlas, se exportan a Parquet desde un corte estable; no se copian sus archivos internos. Las vistas del paquete consultan Parquet en volúmenes; no se registran tablas sobre directorios de un volumen. Las tablas Delta de control utilizan almacenamiento de tablas UC separado. Gold no implica certificación automática.

## 3. Volúmenes y directorios recomendados

Objeto UC: `<catalogo>.<esquema>.<volumen>`. Acceso a archivos: `/Volumes/<catalogo>/<esquema>/<volumen>/...`. Un volumen es un objeto gobernado; sus subdirectorios no son esquemas ni tablas. Se proponen volúmenes externos para recepción compartida con el productor y volúmenes administrados para trabajo exclusivo de Databricks; la elección física debe reflejar la custodia de archivos acordada.

| Esquema | Volumen propuesto | Uso y acceso |
|---|---|---|
| landing | `cresa_mdm_clientes_productos_paquetes` | Paquetes fuente originales y extracción; escritura del receptor, lectura de ingesta |
| landing | `cresa_mdm_clientes_productos_documentos` | Contratos, diccionarios, reglas, diseños y aprobaciones versionados; edición de gobierno |
| bronze | `cresa_mdm_clientes_productos_datos` | Capturas Parquet por fuente; escritura de ingesta |
| silver | `cresa_mdm_clientes_productos_datos` | Datos conformados; escritura de transformación |
| silver | `cresa_mdm_clientes_productos_cuarentena` | Registros observados, motivo y referencia al lote; acceso restringido |
| gold | `cresa_mdm_clientes_productos_datos` | Snapshots certificados y publicables; consumidores acceden por vistas |
| audit01 | `cresa_mdm_clientes_productos_evidencias` | Manifiestos técnicos, conciliaciones y resultados sin valores personales |

La repetición del nombre `..._datos` es válida porque cambia el esquema. Para una ubicación externa, la raíz propuesta es `abfss://<contenedor_autorizado>@devstgdlh02.dfs.core.windows.net/cresa/mdm_clientes_productos/dev/<esquema>/<proposito>/`. Cada volumen debe apuntar a una raíz exclusiva, sin solaparse con otros volúmenes ni ubicaciones de tablas. La ruta física es propuesta, no una external location creada.

```text
/Volumes/dev_dlh_cresa/
├── landing/
│   ├── cresa_mdm_clientes_productos_paquetes/
│   │   └── <fuente>/<entidad>/fecha_corte=YYYY-MM-DD/lote=<id>/
│   │       ├── original/              # ZIP, CSV, Parquet u otro formato acordado
│   │       ├── manifiesto/            # JSON, checksum y esquema de entrega
│   │       └── extraido/              # extracción controlada sin alterar original
│   └── cresa_mdm_clientes_productos_documentos/
│       ├── arquitectura/version=<version>/
│       ├── contratos/<fuente>/<entidad>/version=<version>/
│       ├── diccionarios/<fuente>/version=<version>/
│       ├── reglas/<cliente_o_producto>/version=<version>/
│       ├── homologaciones/<catalogo>/version=<version>/
│       ├── calidad/version=<version>/
│       ├── aprobaciones/<decision>/version=<version>/
│       └── operacion/version=<version>/
├── bronze/cresa_mdm_clientes_productos_datos/
│   └── <fuente>/<entidad>/fecha_corte=YYYY-MM-DD/lote=<id>/data/*.parquet
├── silver/
│   ├── cresa_mdm_clientes_productos_datos/
│   │   └── <entidad>/fecha_corte=YYYY-MM-DD/lote=<id>/data/*.parquet
│   └── cresa_mdm_clientes_productos_cuarentena/
│       └── <entidad>/fecha_corte=YYYY-MM-DD/lote=<id>/<regla>/
├── gold/cresa_mdm_clientes_productos_datos/
│   └── <entidad>/version=<version_publicacion>/data/*.parquet
└── audit01/cresa_mdm_clientes_productos_evidencias/
    └── <pipeline>/ejecucion=<id>/
        ├── manifiesto.json
        ├── conciliacion.json
        └── calidad.json
```

Fuentes iniciales: `dynamics`, `siac`, `credicresa`, `dwh_cresa` y `referencias_comerciales`. Incorporar `vtex` o `venta_smart` solo cuando exista contrato y entrega identificados. Una entidad compartida se almacena una vez por lote; los dominios Cliente/Producto referencian el mismo insumo.

El manifiesto debe registrar productor, fuente, entidad, versión de contrato, fecha de corte UTC, zona horaria original, identificador de lote, formato, codificación/separador, lista de archivos, bytes, SHA-256, conteos esperados, snapshot/versión de origen, clasificación y referencia a la autorización de uso. Las entregas comprimidas se verifican antes y después de extraer; rechazar rutas que salgan del directorio del lote. Un reenvío idéntico se identifica por checksum; una corrección genera otro lote.

Retención y eliminación requieren plazos por clase de información acordados con CRESA. Conservar originales y publicación anterior durante la conciliación; no programar purgas ni históricos ilimitados por tener capacidad disponible. Los documentos no contienen credenciales ni copias de datos personales. El enmascaramiento y el alcance autorizado de datos personales en Desarrollo se fijan antes de transferir.

## 4. Nomenclatura de objetos

Minúsculas, ASCII y `snake_case`, sin espacios ni abreviaturas forzadas a seis caracteres. El catálogo identifica cliente/ambiente. Los maestros y sus capas de conformación adoptan los nombres del [mapa de maestros](../../documentacion_insumo/analisis_caracterizacion/01_mapa_maestros.md), ratificados en la definición solicitada para Producción y Desarrollo. Para estos cuatro objetos, la capa se expresa en el esquema `silver` o `gold`, sin añadir un sufijo de capa al nombre. El proyecto conserva el identificador `mdm_clientes_productos` para volúmenes, código y operación.

Para recepción/Bronze se mantiene `mdm_clientes_productos_<fuente>_<entidad>_<capa>`; para objetos auxiliares Silver/Gold, `mdm_clientes_productos_<entidad>_<capa>`. Estas reglas auxiliares no sustituyen los nombres de los maestros y conformados definidos a continuación.

### 4.1 Maestros y conformación por ambiente

| Ambiente | Dominio | Conformación previa — Silver | Maestro — Gold |
|---|---|---|---|
| Producción | Cliente | `dlh_cresa.silver.dw_cresa_cliente_conformado` | `dlh_cresa.gold.dw_cresa_maestro_cliente` |
| Producción | Producto | `dlh_cresa.silver.dw_cresa_producto_conformado` | `dlh_cresa.gold.dw_cresa_maestro_producto` |
| Desarrollo | Cliente | `dev_dlh_cresa.silver.dw_cresa_cliente_conformado` | `dev_dlh_cresa.gold.dw_cresa_maestro_cliente` |
| Desarrollo | Producto | `dev_dlh_cresa.silver.dw_cresa_producto_conformado` | `dev_dlh_cresa.gold.dw_cresa_maestro_producto` |

Estos son los nombres vigentes de diseño en ambos documentos. Su definición no implica que los objetos ya estén desplegados.

### 4.2 Objetos de Desarrollo y operación

| Objeto | Nombre propuesto de Desarrollo |
|---|---|
| Vista Bronze de clientes Dynamics | `dev_dlh_cresa.bronze.mdm_clientes_productos_dynamics_cliente_bronze` |
| Vista Bronze de producto Dynamics | `dev_dlh_cresa.bronze.mdm_clientes_productos_dynamics_producto_bronze` |
| Vista Bronze de saldos exportados | `dev_dlh_cresa.bronze.mdm_clientes_productos_dwh_cresa_cartera_saldos_bronze` |
| Vista de cliente conformado | `dev_dlh_cresa.silver.dw_cresa_cliente_conformado` |
| Vista de producto conformado | `dev_dlh_cresa.silver.dw_cresa_producto_conformado` |
| Maestro Cliente | `dev_dlh_cresa.gold.dw_cresa_maestro_cliente` |
| Maestro Producto | `dev_dlh_cresa.gold.dw_cresa_maestro_producto` |
| Relación de unidades serializadas | `dev_dlh_cresa.gold.mdm_clientes_productos_producto_unidad_gold` |
| Equivalencias de identificadores de cliente | `dev_dlh_cresa.silver.mdm_clientes_productos_cliente_identificador_silver` |
| Histórico de cliente, si se aprueba | `dev_dlh_cresa.gold.dw_cresa_maestro_cliente_hist` |
| Control de ejecuciones (Delta) | `dev_dlh_cresa.audit01.mdm_clientes_productos_ejecuciones` |
| Control de calidad (Delta) | `dev_dlh_cresa.audit01.mdm_clientes_productos_resultados_calidad` |
| Linaje y publicación (Delta) | `dev_dlh_cresa.audit01.mdm_clientes_productos_linaje`, `dev_dlh_cresa.audit01.mdm_clientes_productos_publicaciones` |
| Job por fuente | `job_cresa_mdm_clientes_productos_<fuente>_ingesta_<ambiente>` |
| Orquestador de maestros | `job_cresa_mdm_clientes_productos_maestros_<ambiente>` |
| Notebook | `nb_cresa_mdm_clientes_productos_<accion>_<entidad>` |
| Grupos propuestos | `grp_cresa_mdm_clientes_productos_<lectura_o_escritura>_<ambiente>` |

En Producción se sustituye únicamente el catálogo por `dlh_cresa` y el ambiente de los objetos operativos por `prd`. Los nombres `dw_cresa_maestro_cliente`, `dw_cresa_maestro_producto`, `dw_cresa_cliente_conformado` y `dw_cresa_producto_conformado` se conservan entre ambientes. `dw_cresa_persona_dim` y `dw_cresa_producto_dim` continúan siendo insumos existentes, distintos de los maestros y conformados. No se ejecuta una migración ni un renombrado de objetos remotos.

CrediCresa mantiene `credicresa_<entidad>_<capa>` y su job consolidado vigente. No se crean 34 jobs ni un esquema por proyecto. La ingesta MDM recorre los contratos de cada fuente. La primera publicación usa snapshots completos; no se activa incrementalidad, CDC ni SCD2 sin watermark, estrategia de borrados y reglas aprobadas.

## 5. Código, secretos y operación

Raíz propuesta de Workspace: `<git_folder_autorizado>/cresa/mdm_clientes_productos/`. Separar código de archivos recibidos; estos últimos van a volúmenes.

```text
<git_folder_autorizado>/cresa/mdm_clientes_productos/
├── config/             # fuentes, contratos, calidad, homologaciones, jobs
├── notebooks/          # ingesta, conformación y publicación
├── lib/                # componentes compartidos
├── sql/                # objetos y control plane
├── docs/               # diseños y decisiones versionadas
└── tests/              # validación y evidencia sin datos sensibles
```

Esta propuesta no mueve el paquete activo ni instala procesos en las carpetas productivas existentes. No introduce JDBC/ODBC ni una conexión a SQL Server. Para futuros secretos autorizados: scope `cresa-mdm-clientes-productos-<ambiente>` y clave `<fuente>-<proposito>`; valores solo en Databricks Secret Scope/Azure Key Vault. Son nombres propuestos, no secretos creados.

## 6. Responsabilidad y criterios de publicación

| Función | Responsabilidad y evidencia |
|---|---|
| Data Owner de Cliente / Producto | Aprobar definición, fuente de autoridad y uso; Miguel Espinoza figura en el documento suministrado, pendiente ratificar designación por dominio |
| Data Steward por dominio | Resolver duplicados, equivalencias, faltantes y excepciones; mantener glosario y diccionario |
| Responsable Crédito | Aprobar cupo disponible, corte, agregación, escalera de mora y contactabilidad |
| Ingeniería / plataforma | Recepción, permisos, snapshots, reconciliación, ejecución, monitoreo y recuperación |
| Gobierno / seguridad | Clasificación, acceso, retención, consentimiento, alcance de Desarrollo y certificación |

Para publicar: cerrar grano y claves; recibir contratos y archivos completos; reconciliar corte, filas y tipos; demostrar reglas y linaje por atributo; resolver o registrar brechas; aplicar permisos; publicar versión y evidencia. El maestro de Producto requiere separar SKU de unidad serializada. El maestro de Cliente necesita equivalencias entre identificación, cuenta Dynamics y clave SIAC. No se sustituye consentimiento por teléfono disponible ni cupo por límite Dynamics.

## 7. Referencias y validación

Base documental: [contexto previo](CONTEXTO_03_MAESTROS.md), [mapa funcional](../../documentacion_insumo/analisis_caracterizacion/01_mapa_maestros.md), Excel `12_Procesos_Credito_Cartera.xlsx`, `13_Procesos_Producto_Cliente.xlsx`, `14_Maestro-Cliente.xlsx` y `17_CRESA_DATABRICK_DEFINICION_INICIAL-R1.xlsx`. Este último conserva ejemplos ajenos al dominio; no se tratan como fuentes CRESA.

Referencias técnicas para contraste de implementación: [Medallion en Azure Databricks](https://learn.microsoft.com/en-us/azure/databricks/lakehouse/medallion), [Unity Catalog Volumes](https://learn.microsoft.com/en-us/azure/databricks/volumes/) y [DAMA International](https://dama.org/). La consulta web falló durante esta revisión; estos enlaces se dejan como referencias, no como evidencia de una edición DAMA validada.

La entrega modifica documentación y guarda metadatos de lectura. No crea volúmenes, esquemas, jobs ni maestros, y no copia datos. Véase la validación local y remota diferenciada en el informe extendido.

## Consolidación documental y publicación Git

El [estado vigente](ESTADO_VIGENTE.md) registra la precedencia de esta definición, el inventario de documentos y las fuentes originales conservadas. La publicación Git incorpora los cambios locales y no despliega objetos en Databricks. Los nombres completos Silver/Gold indicados para ambos ambientes permanecen vigentes.
