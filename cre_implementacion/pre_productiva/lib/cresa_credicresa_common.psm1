# Parametros mediante arrays: no se evalua texto como comandos.
function Connect-CresaOAuth {
 param([string]$AuthName, [string]$WorkspaceUrl)
 if ([string]::IsNullOrWhiteSpace($AuthName) -or [string]::IsNullOrWhiteSpace($WorkspaceUrl)) {
  throw 'Authenticate requiere AuthName y WorkspaceUrl.'
 }
 $null = Get-Command databricks -ErrorAction Stop
 # Variables locales: Windows PowerShell 5.1 convierte stderr en NativeCommandError.
 # La comprobacion debe resolver por codigo de salida y permitir renovar OAuth.
 $ErrorActionPreference = 'Continue'
 $PSNativeCommandUseErrorActionPreference = $false
 $null = & databricks current-user me --profile $AuthName --output json 2>$null
 if ($LASTEXITCODE -eq 0) { return }
 Write-Host 'CRESA: la sesion no es valida; iniciando autenticacion OAuth.'
 & databricks auth login --host $WorkspaceUrl --profile $AuthName
 if ($LASTEXITCODE -ne 0) { throw 'OAuth fallo. No se ejecuto el proceso solicitado.' }
 $null = & databricks current-user me --profile $AuthName --output json 2>$null
 if ($LASTEXITCODE -ne 0) { throw 'OAuth no produjo una sesion valida. No se ejecuto el proceso solicitado.' }
}

function Invoke-CresaCredito {
 param([string]$Mode, [hashtable]$Parameters)
 $ErrorActionPreference = 'Stop'
 $log = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/cresa_credicresa_desplegar.log'
 if (-not [string]::IsNullOrWhiteSpace($Parameters.OutputRoot)) {
  $log = Join-Path ([IO.Path]::GetFullPath($Parameters.OutputRoot)) 'cresa_credicresa_desplegar.log'
 }
 if ($Parameters.ContainsKey('LogPath')) { $log = $Parameters.LogPath }
 $Parameters['LogPath'] = $log
 $logDirectory = Split-Path $log -Parent
 [IO.Directory]::CreateDirectory($logDirectory) | Out-Null
 try {
  $base = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
  if ($Parameters.ContainsKey('BasePath') -and
      [IO.Path]::GetFullPath($Parameters.BasePath).TrimEnd('\','/') -ne $base) {
   throw 'BasePath no corresponde al paquete ejecutado.'
  }
  $python = Join-Path $base 'pre_productiva\.venv\Scripts\python.exe'
  if ($Parameters.ContainsKey('PythonPath')) { $python = $Parameters.PythonPath }
  if (-not (Test-Path -LiteralPath $python -PathType Leaf)) { throw 'PythonPath no existe.' }
  if ($Parameters.Authenticate) {
   Connect-CresaOAuth -AuthName $Parameters.AuthName -WorkspaceUrl $Parameters.WorkspaceUrl
  }
  $arguments = @((Join-Path $PSScriptRoot 'cresa_credicresa_pilot.py'), $Mode)
  $mapping = @{
   CatalogName='catalog-name'; LogPath='log-path'; AuthName='auth-name'; WorkspaceUrl='workspace-url'; WorkspacePath='workspace-path'
   SqlWarehouseId='sql-warehouse-id'; ClusterId='cluster-id'; TimeoutSeconds='timeout-seconds'
  }
  foreach ($key in $mapping.Keys) {
   if ($Parameters.ContainsKey($key)) { $arguments += @(( '--' + $mapping[$key]), [string]$Parameters[$key]) }
  }
  if ($Parameters.ContainsKey('Entities')) { $arguments += @('--entities', ($Parameters.Entities -join ',')) }
  $pythonDiagnostic = $null
  & $python @arguments | ForEach-Object {
   # Mantener salida visible y conservar el diagnostico seguro de esta ejecucion.
   if ($_ -is [string] -and $_.StartsWith('CRESA: ')) { $pythonDiagnostic = $_ }
   Write-Output $_
  }
  if ($LASTEXITCODE -ne 0) {
   if ($pythonDiagnostic) { throw "$pythonDiagnostic (codigo $LASTEXITCODE)" }
   throw "Operacion Python fallida (codigo $LASTEXITCODE). Revisar el diagnostico anterior y el LOG: $log"
  }
 } catch {
  @{ utc=[DateTime]::UtcNow.ToString('o'); mode=$Mode; phase=7; status='ERROR'
     code='POWERSHELL_FAILED'; error_type=$_.Exception.GetType().Name } |
      ConvertTo-Json -Compress | Add-Content -LiteralPath $log -Encoding utf8
  # Conserva la excepcion original para que el envoltorio no oculte la causa.
  throw
 }
}

Export-ModuleMember -Function Invoke-CresaCredito
