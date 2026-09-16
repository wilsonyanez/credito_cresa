> **Actualización de contexto — 2026-09-16.** El [estado vigente](pre_productiva/docs/ESTADO_VIGENTE.md) y el [README operativo](pre_productiva/README.md) sustituyen las rutas, comandos y destinos anteriores como instrucciones de operación. Desarrollo del cliente: `dev_dlh_cresa` / `devstgdlh02`, 1,2 TB disponibles declarados; Producción: `dlh_cresa`; piloto: `cresa`. Los maestros Gold son `dw_cresa_maestro_cliente` y `dw_cresa_maestro_producto`; sus conformados Silver son `dw_cresa_cliente_conformado` y `dw_cresa_producto_conformado`. El contenido siguiente es historial fechado, no estado remoto actual.

# Contexto consolidado CRESA

Fecha de actualización: 2026-09-03

## 1. Identificación del proyecto

- Proyecto: CRESA Fase 3, Gobierno e ingesta de datos.
- Plataforma: Databricks en AWS, workspace Personal.
- Ruta local: `C:\desa\git\cresa\cre_implementacion`.
- Paquete desplegable: `pre_productiva/`.
- Paquete preparado para pruebas: `C:\desa\git\test\pre_productiva`.
- Repositorio GitHub: `https://github.com/wilsonyanez/credito_cresa/tree/main/cre_implementacion`.

## 2. Datos de Databricks

- Usuario: `wilsonyanez@hotmail.com`.
- Workspace ID: `7474649840848388`.
- URL: `https://dbc-d87ef1e3-6c95.cloud.databricks.com`.
- Recurso informado: `aws:us-east-2:3ead0e85-1c45-485a-81c7-e6d4710c9d0d`.
- Perfil CLI: `cresa-dev`.
- Git folder: `/Workspace/Users/wilsonyanez@hotmail.com/credito_cresa`.
- Ruta protegida: `/Workspace/Users/wilsonyanez@hotmail.com/credito_cresa/.git`.
- Cómputo indicado: Serverless; la URL recibida no es un `existing_cluster_id`.

La CLI Databricks 1.14.1 está instalada y el perfil `cresa-dev` fue autenticado mediante OAuth. La contraseña se introduce en el flujo oficial de autenticación y no se guarda en el repositorio, logs ni argumentos.

## 3. Arquitectura Medallion vigente

- Fuente de prueba: `cresa_dev.credito_cresa_source`.
- Landing y semillas: volumen `cresa_dev.landing.source_seed`.
- Bronze: `cresa_dev.bronze` y volumen `cresa_dev.bronze.data`.
- Control plane: `cresa_dev.audit01` en Delta.
- Datos de ingesta y caracterización: Parquet.
- Tablas de control: `ingestion_runs`, `ingestion_table_runs`, `ingestion_columns` e `ingestion_watermarks`.
- Vistas operativas: `v_latest_ingestion_run` y `v_ingestion_errors`.
- Entidades activas: 34 YAML.
- Orquestación: un job por fuente, ejecución secuencial y `max_concurrent_runs=1`.
- Estado inicial del schedule: `PAUSED`.

No existe conexión activa a SQL Server. Los tipos se conservan desde semillas Parquet; cuando no hay semilla ni diccionario, se usa `STRING` explícito.

## 4. Estructura del repositorio

- `documentacion_insumo/`: análisis, caracterización, matrices y diagramas; no desplegable.
- `construccion_tecnica_previa/`: artefactos históricos reemplazados; solo referencia.
- `pre_productiva/`: única fuente autorizada para pruebas y despliegue.
- `C:\desa\git\test\`: área local para paquetes preparados, logs y reverso.

## 5. Scripts operativos

### Despliegue

Archivo fuente: `C:\desa\git\cresa\scripts\cresa_desplegar.ps1`.

Funciones:

- Valida el paquete y los 34 YAML.
- Copia `pre_productiva` a `C:\desa\git\test\pre_productiva`.
- Puede validar acceso al Workspace.
- Puede importar el paquete al Git folder.
- Genera temporalmente una definición de job compatible con Serverless.
- Crea o actualiza el job `ingest_credito_cresa_source`.
- Puede ejecutar el smoke remoto de solo lectura.
- Registra acciones en `C:\desa\git\test\cresa_desplegar.log`.

Validación local:

```powershell
.\scripts\cresa_desplegar.ps1
```

Despliegue evaluativo con OAuth:

```powershell
.\scripts\cresa_desplegar.ps1 -Deploy -Authenticate -AuthName 'cresa-dev'
```

### Reverso

Archivo fuente: `pre_productiva/scripts/cresa_reversar.ps1`.

Funciones:

- Modo simulación por defecto.
- Localiza el job por nombre exacto.
- Elimina únicamente el job CRESA identificado.
- Elimina únicamente la subcarpeta `pre_productiva` del Git folder.
- Protege explícitamente la carpeta `.git`.
- Puede eliminar `cresa_dev` mediante SQL Statements API si se proporciona un `SqlWarehouseId` autorizado.
- Registra acciones en `cresa_reversar.log`.

Simulación:

```powershell
.\pre_productiva\scripts\cresa_reversar.ps1 -WhatIf
```

Reverso real:

```powershell
.\pre_productiva\scripts\cresa_reversar.ps1 -Execute -Authenticate
```

## 6. Logs

- Despliegue: `C:\desa\git\test\cresa_desplegar.log`.
- Reverso: `C:\desa\git\test\reverso\cresa_reversar.log`.
- El log de reverso conserva las simulaciones anteriores.
- Los logs no deben contener contraseñas, tokens, cadenas de conexión ni valores `dapi-...`.

## 7. Resultados de validación

Última simulación de despliegue:

- Terminó con código de salida 0.
- Paquete válido.
- 34 YAML encontrados.
- Job JSON válido.
- Paquete preparado en `C:\desa\git\test\pre_productiva`.
- No se modificó Databricks porque se ejecutó sin `-Deploy`.

Última simulación de reverso:

- Terminó correctamente en modo `WHATIF`.
- Acceso al Workspace confirmado.
- Jobs CRESA encontrados: 0.
- Carpeta `pre_productiva` remota: no encontrada.
- `.git` protegido.
- Catálogo no eliminado porque no se proporcionó `SqlWarehouseId`.

Evaluación remota previa:

- `workspace list /` respondió correctamente.
- El directorio del usuario es accesible.
- No había clústeres visibles.
- No había jobs desplegados.
- La CLI y el perfil OAuth funcionan.

## 8. Inconsistencias y decisiones pendientes

1. El JSON fuente contiene `REEMPLAZAR_RUTA_GIT_FOLDER` y `REEMPLAZAR_CLUSTER_ID` como placeholders documentales; el script de despliegue los reemplaza en una definición temporal y usa Serverless.
2. Para eliminar el catálogo `cresa_dev` se requiere un SQL Warehouse ID autorizado. La URL de cómputo Serverless no debe usarse como ese ID.
3. El smoke remoto requiere un entorno `.venv` compatible con el Databricks Runtime y `databricks-connect` instalado.
4. El job debe permanecer pausado hasta aprobación funcional.
5. La búsqueda de `jdbc:sqlserver` en el validador es una regla para detectar conexiones prohibidas, no una conexión activa.
6. No afirmar despliegue remoto exitoso si solo se ejecutó la validación local.

## 9. Reglas de operación

- Modificar cambios desplegables únicamente en `pre_productiva/`.
- No desplegar `construccion_tecnica_previa/`.
- No volver a crear jobs individuales por tabla.
- No guardar credenciales en archivos.
- No usar datos personales reales sin aprobación de privacidad y gobierno.
- No ejecutar reverso real sin revisar primero `-WhatIf` y el log.
- No borrar `.git`, el repositorio ni objetos fuera del alcance CRESA explícito.
