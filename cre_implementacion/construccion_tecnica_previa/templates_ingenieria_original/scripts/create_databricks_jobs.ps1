<#
create_databricks_jobs.ps1
Wrapper sencillo para ejecutar el script que crea/actualiza todos los jobs.
Uso:
  En PowerShell:
    $env:DATABRICKS_HOST = 'https://adb-...'
    $env:DATABRICKS_TOKEN = '...'
    .\create_databricks_jobs.ps1

Este script llama a `create_databricks_jobs_all.ps1` y pasa control para creación/actualización.
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$allScript = Join-Path $scriptDir 'create_databricks_jobs_all.ps1'
$resetScript = Join-Path $scriptDir 'create_or_update_jobs_with_reset.ps1'

param(
  [switch]$SubmitRun
)

if (Test-Path $resetScript) {
  Write-Host "Ejecutando: $resetScript"
  if ($SubmitRun) { & $resetScript -SubmitRun }
  else { & $resetScript }
  Write-Host "Finalizado $resetScript."
  exit 0
}

if (Test-Path $allScript) {
  Write-Host "Ejecutando: $allScript"
  & $allScript
  Write-Host "Finalizado $allScript."
  exit 0
}

Write-Error "No se encontró ningún script de creación de jobs (buscado: $allScript y $resetScript)." 
