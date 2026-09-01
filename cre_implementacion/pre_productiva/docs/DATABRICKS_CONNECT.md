# Databricks Connect para desarrollo local

Databricks Connect permite ejecutar desde el IDE usando cómputo remoto. En esta solución no se utiliza para conectar una base Microsoft SQL; la fuente de prueba vive dentro de Databricks.

## Datos requeridos

- URL del workspace.
- Databricks Runtime.
- ID del clúster o serverless.
- Ruta del Git folder.

La versión local de Python y `databricks-connect` debe corresponder al Runtime.

```powershell
.\pre_productiva\scripts\setup_databricks_connect.ps1 `
  -WorkspaceUrl 'https://adb-<workspace>.azuredatabricks.net' `
  -RuntimeVersion '16.4' `
  -PythonVersion '3.12' `
  -Profile 'cresa-dev'
```

Prueba posterior:

```powershell
.\.venv\Scripts\Activate.ps1
$env:DATABRICKS_CONFIG_PROFILE = 'cresa-dev'
python .\pre_productiva\tests\smoke_databricks_connect.py
```

Databricks Connect no sustituye el Git folder: el repositorio debe vincularse por separado al workspace.

