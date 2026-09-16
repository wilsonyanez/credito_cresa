# Prueba local sin CLI real, navegador ni solicitudes remotas.
$ErrorActionPreference = 'Stop'
$module = Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib/cresa_credicresa_common.psm1') -Force -PassThru
& $module {
 function databricks {
  $script:commands += ($args -join ' ')
  $code = $script:codes[$script:commands.Count - 1]
  if ($code -ne 0) { Write-Error 'Simulated invalid refresh token' }
  $global:LASTEXITCODE = $code
 }
 foreach ($case in @(
  @{ Codes=@(0); Count=1; Failure=$false },
  @{ Codes=@(1,0,0); Count=3; Failure=$false },
  @{ Codes=@(1,1); Count=2; Failure=$true },
  @{ Codes=@(1,0,1); Count=3; Failure=$true }
 )) {
  $script:codes = $case.Codes
  $script:commands = @()
  $failed = $false
  try { Connect-CresaOAuth -AuthName 'test-profile' -WorkspaceUrl 'https://example.invalid' 2>$null }
  catch { $failed = $true }
  if ($failed -ne $case.Failure -or $script:commands.Count -ne $case.Count) { throw 'Flujo OAuth incorrecto' }
  if ($case.Count -gt 1 -and $script:commands[1] -ne 'auth login --host https://example.invalid --profile test-profile') {
   throw 'No se invoco login con el destino esperado'
  }
  if ($ErrorActionPreference -ne 'Stop') { throw 'Se altero la preferencia del llamador' }
 }
}
Write-Output 'OK: sesion valida, renovacion OAuth, login fallido y verificacion fallida.'
