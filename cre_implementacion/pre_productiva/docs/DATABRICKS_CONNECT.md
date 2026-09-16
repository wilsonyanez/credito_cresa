# Desarrollo local y Databricks Connect

Revisión: 2026-09-16. El paquete operativo usa la CLI Databricks y OAuth mediante los lanzadores descritos en [README](../README.md). No necesita Databricks Connect para validar contratos ni generar el plan local.

Los archivos históricos `scripts/setup_databricks_connect.ps1` y `tests/smoke_databricks_connect.py` no están disponibles como flujo vigente; sus comandos se retiran de esta guía. Si se adopta Connect, definir y validar previamente Runtime, Python, cómputo y permisos del ambiente objetivo. No se declara instalado ni probado como parte de esta entrega.

El MDM se diseña para `dev_dlh_cresa` / `dlh_cresa`; `cresa` sigue siendo el piloto. Connect no crea una conexión a SQL Server ni sustituye el versionado del código. Credenciales y autorización se administran fuera del repositorio.
