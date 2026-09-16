> **Revisión de consistencia — 2026-09-16.** Antecedente documental o evidencia fechada. Para nombres, capacidad, estado de acceso y operación actuales prevalecen el [estado vigente](ESTADO_VIGENTE.md), la [arquitectura MDM](17_CRESA_DATABRICK_DEFINICION_INICIAL.md) y el [informe extendido](20_CRESA_MDM_ANALISIS_EXTENDIDO.md). Los comandos, límites y resultados anteriores del contenido siguiente se conservan como antecedentes; no acreditan un despliegue MDM ni una ejecución actual.

# Resultado de despliegue — CRESA / credicresa

Fecha UTC: 2026-09-07.

- Cliente / catálogo: cresa.
- Proyecto / esquema fuente: cresa.credicresa.
- Job: job_credicresa_ingesta_periodo, ID 1008661299620101, PAUSED.
- Ejecución verificada: 1094185962105919.
- Estado: SUCCESS en fuente, Bronze y verificación.
- Objetos: 34 vistas fuente y 34 vistas Bronze sobre Parquet.
- Contratos: 34 YAML, 451 atributos; 902 comprobaciones de esquema entre ambas capas.
- Auditoría: run 8f11d9b93d3c46efa802cab8b16ffd8d, estado SUCCEEDED, 34 entidades cargadas, cero errores, 451 atributos registrados.
- Filas de negocio: 0. La ejecución fue bootstrap; no se recibieron planos.
- Pruebas locales: 20 satisfactorias.
- Verificación Spark: BIGINT sin pérdida de precisión y rechazo de texto inválido/desbordamiento decimal.
- Log: C:/desa/git/cresa/tests/cresa_desplegar.log.
- Manifiesto operativo: .deployment/credicresa.json.

[Ver ejecución en Databricks](https://dbc-d87ef1e3-6c95.cloud.databricks.com/?o=7474649840848388#job/1008661299620101/run/1094185962105919)

La ejecución previa que apuntaba a credito_cresa se canceló al recibir la corrección cliente/proyecto. El job activo ahora apunta exclusivamente a cresa.credicresa y a la carpeta /Workspace/Users/wilsonyanez@hotmail.com/cresa/credicresa. Los objetos preparatorios del destino anterior se conservan; no se ejecutó su reversa.

Pendiente: recibir la carpeta de planos y el período para validar una carga con datos reales. Los comandos de despliegue, carga y reversa están en [README](../README.md).

La vista previa de credicresa_reversar.ps1 -WhatIf terminó correctamente: identificó el job, 68 vistas y la carpeta del proyecto. No se ejecutó ninguna eliminación.

## Estado comprobado el 2026-09-07, 20:41 UTC

Revisión remota de solo lectura: el job 1008661299620101 ya no figura en el inventario
completo de jobs; tampoco están las 34 vistas Bronze. Permanecen las 34 vistas fuente,
cresa.credicresa, su volumen data y la carpeta del proyecto con marca de propiedad.
Este estado posterior no debe confundirse con el despliegue exitoso histórico.

La vista previa con DropProjectSchema terminó correctamente:
rastro 38c72b53b22a44c8a6495bc1d01286ab, registrado en
C:/desa/git/cresa/tests/cresa_desplegar.log. Incluye las 34 vistas restantes,
el volumen data, el esquema fuente y la carpeta del proyecto. La consulta inicial del
job del manifiesto falló; se corrigió la reversa para admitir ausencias comprobadas
mediante inventarios completos, sin ignorar errores de consulta.

Validación local: 34 YAML, 451 atributos, 29 pruebas satisfactorias.
No se ejecutó Execute ni un nuevo Deploy en esta revisión. La comprobación posterior
a la eliminación está implementada y probada localmente; la eliminación real no fue
ejecutada. El comando Deploy recrea los artefactos faltantes y ejecuta su verificación.
