[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https://')]
    [string]$WorkspaceUrl,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+$')]
    [string]$RuntimeVersion,

    [string]$Profile = 'cresa-dev',
    [ValidateSet('3.10', '3.11', '3.12')]
    [string]$PythonVersion = '3.12',
    [string]$VenvPath = '.venv'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command py -ErrorAction SilentlyContinue)) {
    throw 'No se encontró Python Launcher (py). Instale una versión de Python compatible con el Databricks Runtime.'
}

if (-not (Get-Command databricks -ErrorAction SilentlyContinue)) {
    throw 'No se encontró Databricks CLI. Instale la CLI oficial y vuelva a ejecutar este script.'
}

& py "-$PythonVersion" -m venv $VenvPath
$VenvPython = Join-Path $VenvPath 'Scripts\python.exe'

& $VenvPython -m pip install --upgrade pip
& $VenvPython -m pip uninstall -y pyspark
& $VenvPython -m pip install "databricks-connect==$RuntimeVersion.*"

Write-Host "Iniciando autenticación OAuth para el perfil '$Profile'..."
& databricks auth login --host $WorkspaceUrl --profile $Profile --configure-cluster

Write-Host 'Validando Databricks Connect...'
$env:DATABRICKS_CONFIG_PROFILE = $Profile
& (Join-Path $VenvPath 'Scripts\databricks-connect.exe') test

Write-Host "Configuración terminada. Active el entorno con: $VenvPath\Scripts\Activate.ps1"
Write-Host "Antes de desarrollar, defina: `$env:DATABRICKS_CONFIG_PROFILE='$Profile'"

