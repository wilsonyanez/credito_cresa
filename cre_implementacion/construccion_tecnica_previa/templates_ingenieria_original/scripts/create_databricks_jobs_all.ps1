<#
create_databricks_jobs_all.ps1
Script para crear o actualizar jobs en Databricks a partir de JSON en
templates_ingenieria/config/jobs/. Lee `DATABRICKS_HOST` y `DATABRICKS_TOKEN`
desde variables de entorno o solicita las credenciales de forma segura.

Uso:
  # Exportar antes las vars (Linux/macOS Bash) o set en PowerShell:
  $env:DATABRICKS_HOST = 'https://adb-...azuredatabricks.net'
  $env:DATABRICKS_TOKEN = '...'
  .\create_databricks_jobs_all.ps1

Nota: No pegar tokens en el repositorio ni en esta conversación.
#>

param()

# Logging setup
$scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$templatesRoot = Split-Path -Parent $scriptFolder
$global:LogDirectory = Join-Path $templatesRoot 'logs'
if (-not (Test-Path $global:LogDirectory)) { New-Item -ItemType Directory -Path $global:LogDirectory | Out-Null }
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$global:LogFile = Join-Path $global:LogDirectory "create_jobs_$timestamp.log"

$host = $env:DATABRICKS_HOST
$token = $env:DATABRICKS_TOKEN

if (-not $host) {
  $host = Read-Host 'DATABRICKS_HOST (ej. https://adb-...azuredatabricks.net)'
}
if (-not $token) {
  $secure = Read-Host 'DATABRICKS_TOKEN (se ocultará al escribir)' -AsSecureString
  $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  )
}

function Invoke-DbcApi {
  param(
    [string]$Method,
    [string]$Endpoint,
    [object]$Body = $null
  )
  $uri = "$($host.TrimEnd('/'))/api/2.0/$Endpoint"
  $headers = @{ Authorization = "Bearer $token" }
  try {
    if ($Body -ne $null) {
      $bodyJson = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 10 }
      return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType 'application/json' -Body $bodyJson
    } else {
      return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
    }
  } catch {
    Write-Error "API call failed: $($_.Exception.Message)"
    if ($_.Exception.Response) {
      try { $b = (New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd(); Write-Host $b } catch {}
    }
    return $null
  }
}

function Find-JobByName {
  param([string]$name)
  $resp = Invoke-DbcApi -Method Get -Endpoint 'jobs/list'
  if (-not $resp) { return $null }
  if ($resp.jobs) {
    foreach ($j in $resp.jobs) {
      $jn = $null
      if ($j.settings -and $j.settings.name) { $jn = $j.settings.name }
      elseif ($j.settings -and $j.settings.task && $j.settings.task.name) { $jn = $j.settings.task.name }
      if ($jn -eq $name) { return $j }
    }
  }
  return $null
}

function Create-Or-Update-JobFromFile {
  param([string]$jsonPath)
  if (-not (Test-Path $jsonPath)) { Write-Warning "No se encontró: $jsonPath"; return }
  Write-Host "Procesando: $jsonPath"
  $raw = Get-Content -Raw -Path $jsonPath
  $jobObj = $raw | ConvertFrom-Json
  $jobName = $jobObj.name
  if (-not $jobName) { Write-Warning "El JSON no contiene 'name' en la raíz: $jsonPath"; return }

  $existing = Find-JobByName -name $jobName
  if ($existing) {
    Write-Host "Job ya existe (job_id=$($existing.job_id)). Actualizando automáticamente."
    $body = @{ job_id = $existing.job_id; new_settings = $jobObj }
    $resp = Invoke-DbcApi -Method Post -Endpoint 'jobs/reset' -Body $body
    if ($resp -ne $null) { Write-Host "Job actualizado: $jobName (job_id=$($existing.job_id))" }
    else { Write-Error "Fallo al actualizar job: $jobName (job_id=$($existing.job_id))" }
  } else {
    $resp = Invoke-DbcApi -Method Post -Endpoint 'jobs/create' -Body $jobObj
    if ($resp -and $resp.job_id) { Write-Host "Job creado: $jobName (job_id=$($resp.job_id))" }
  }

  # Logging and optional post-run validation
  if (-not (Test-Path $global:LogDirectory)) { New-Item -ItemType Directory -Path $global:LogDirectory | Out-Null }
  $logEntry = "$(Get-Date -Format o) - Processed $jsonPath - job: $jobName"
  Add-Content -Path $global:LogFile -Value $logEntry
  $jobId = $null
  if ($existing) { $jobId = $existing.job_id } elseif ($resp -and $resp.job_id) { $jobId = $resp.job_id }
  if ($jobId) {
    Add-Content -Path $global:LogFile -Value "Submitting test run for job_id=$jobId"
    Submit-Run-And-Validate -jobId $jobId -jobName $jobName -jsonPath $jsonPath
  } else {
    Add-Content -Path $global:LogFile -Value "No job_id available for $jobName; skip submit"
  }
}

function Submit-Run-And-Validate {
  param(
    [Parameter(Mandatory=$true)][string]$jobId,
    [Parameter(Mandatory=$true)][string]$jobName,
    [Parameter(Mandatory=$true)][string]$jsonPath
  )
  # Submit a run in test mode using jobs/runs/submit (v2.1) - use /api/2.1
  $body = @{ job_id = [int]$jobId; notebook_params = @{ run_mode = 'test' } }
  $submitResp = Invoke-DbcApi -Method Post -Endpoint 'jobs/runs/submit' -Body $body
  if (-not $submitResp -or -not $submitResp.run_id) {
    Add-Content -Path $global:LogFile -Value "Failed to submit run for job_id=$jobId. Response: $(ConvertTo-Json $submitResp -Depth 5)"
    return
  }
  $runId = $submitResp.run_id
  Add-Content -Path $global:LogFile -Value "Run submitted: run_id=$runId for job_id=$jobId"

  # Poll for completion
  $start = Get-Date
  while ($true) {
    Start-Sleep -Seconds 5
    $status = Invoke-DbcApi -Method Get -Endpoint "jobs/runs/get?run_id=$runId"
    if (-not $status) { Add-Content -Path $global:LogFile -Value "Failed to get run status for run_id=$runId"; break }
    $life = $status.state.life_cycle_state
    $resultState = $status.state.result_state
    Add-Content -Path $global:LogFile -Value "Run $runId state: $life / result: $resultState"
    if ($life -eq 'TERMINATED' -or $life -eq 'INTERNAL_ERROR' -or $life -eq 'SKIPPED') { break }
    # timeout after 15 minutes
    if ((Get-Date) - $start -gt [TimeSpan]::FromMinutes(15)) { Add-Content -Path $global:LogFile -Value "Run $runId timeout"; break }
  }

  # Get output
  $out = Invoke-DbcApi -Method Get -Endpoint "jobs/runs/get-output?run_id=$runId"
  Add-Content -Path $global:LogFile -Value "Run output for run_id=$runId: $(ConvertTo-Json $out -Depth 5)"

  # SQL validation: requires DATABRICKS_SQL_WAREHOUSE_ID env var
  $warehouseId = $env:DATABRICKS_SQL_WAREHOUSE_ID
  if (-not $warehouseId) {
    Add-Content -Path $global:LogFile -Value "DATABRICKS_SQL_WAREHOUSE_ID not set; skipping SQL validation."
  } else {
    try {
      $jobJson = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json
      $configYml = $null
      if ($jobJson.notebook_task -and $jobJson.notebook_task.base_parameters -and $jobJson.notebook_task.base_parameters.config_yml) {
        $configYml = $jobJson.notebook_task.base_parameters.config_yml
      } elseif ($jobJson.notebook_task -and $jobJson.notebook_task.base_parameters -and $jobJson.notebook_task.base_parameters.config) {
        $configYml = $jobJson.notebook_task.base_parameters.config
      }
      if (-not $configYml) { Add-Content -Path $global:LogFile -Value "No config_yml found in job JSON; skipping SQL validation."; return }
      $repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
      $ymlPath = Join-Path $repoRoot $configYml
      if (-not (Test-Path $ymlPath)) { $ymlPath = $configYml }
      if (-not (Test-Path $ymlPath)) { Add-Content -Path $global:LogFile -Value "YAML not found at $configYml or $ymlPath; skipping SQL validation."; return }

      $ymlText = Get-Content -Raw -Path $ymlPath
      $bronzeCatalog = $null; $bronzeSchema = $null; $bronzeTable = $null
      if ($ymlText -match 'bronze_catalog:\s*"?([A-Za-z0-9_]+)"?') { $bronzeCatalog = $Matches[1] }
      if ($ymlText -match 'bronze_schema:\s*"?([A-Za-z0-9_]+)"?') { $bronzeSchema = $Matches[1] }
      if ($ymlText -match 'bronze_table:\s*"?([A-Za-z0-9_]+)"?') { $bronzeTable = $Matches[1] }

      if (-not $bronzeCatalog -or -not $bronzeSchema -or -not $bronzeTable) { Add-Content -Path $global:LogFile -Value "No target table found in YAML ($ymlPath); skipping SQL validation."; return }

      $validationSql = "SELECT COUNT(*) AS cnt FROM $bronzeCatalog.$bronzeSchema.$bronzeTable"
      Add-Content -Path $global:LogFile -Value "Running validation SQL: $validationSql"
      $sqlResp = Execute-Sql-Statement -sql $validationSql -warehouseId $warehouseId
      Add-Content -Path $global:LogFile -Value "SQL validation response: $(ConvertTo-Json $sqlResp -Depth 5)"

      # Additional validations
      # 1) Duplicates by natural_key (nombre)
      $dupSql = "SELECT nombre, COUNT(*) AS cnt FROM $bronzeCatalog.$bronzeSchema.$bronzeTable GROUP BY nombre HAVING COUNT(*) > 1 LIMIT 50"
      Add-Content -Path $global:LogFile -Value "Running duplicates SQL: $dupSql"
      $dupResp = Execute-Sql-Statement -sql $dupSql -warehouseId $warehouseId
      Add-Content -Path $global:LogFile -Value "Duplicates response: $(ConvertTo-Json $dupResp -Depth 5)"

      # 2) Null primary keys
      $nullPkSql = "SELECT COUNT(*) AS null_pk FROM $bronzeCatalog.$bronzeSchema.$bronzeTable WHERE id IS NULL"
      Add-Content -Path $global:LogFile -Value "Running null-PK SQL: $nullPkSql"
      $nullPkResp = Execute-Sql-Statement -sql $nullPkSql -warehouseId $warehouseId
      Add-Content -Path $global:LogFile -Value "Null-PK response: $(ConvertTo-Json $nullPkResp -Depth 5)"

      # 3) Sample rows
      $sampleSql = "SELECT id,nombre FROM $bronzeCatalog.$bronzeSchema.$bronzeTable LIMIT 50"
      Add-Content -Path $global:LogFile -Value "Running sample SQL: $sampleSql"
      $sampleResp = Execute-Sql-Statement -sql $sampleSql -warehouseId $warehouseId
      Add-Content -Path $global:LogFile -Value "Sample response: $(ConvertTo-Json $sampleResp -Depth 5)"
      # Parse counts and send alerts if issues
      $dupCount = Parse-NumberFromResult -res $dupResp
      $nullPkCount = Parse-NumberFromResult -res $nullPkResp
      $issues = @()
      if ($dupCount -ne $null -and $dupCount -gt 0) { $issues += "Duplicates by nombre: $dupCount" }
      if ($nullPkCount -ne $null -and $nullPkCount -gt 0) { $issues += "Null PKs (id): $nullPkCount" }
      if ($issues.Count -gt 0) {
        $subject = "[ALERTA] Validaciones fallaron para $jobName"
        $body = "Se encontraron problemas en la ingesta del job $jobName.`n`nProblemas detectados:`n- $($issues -join "`n- ")`n`nRevisa el log: $global:LogFile"
        Send-Alert-Email -subject $subject -body $body
      }
    } catch {
      Add-Content -Path $global:LogFile -Value "Exception during SQL validation: $($_.Exception.Message)"
    }
  }
}

function Execute-Sql-Statement {
  param(
    [Parameter(Mandatory=$true)][string]$sql,
    [Parameter(Mandatory=$true)][string]$warehouseId
  )
  # POST /api/2.0/sql/statements
  $body = @{ statement = $sql; warehouse_id = $warehouseId }
  $submit = Invoke-DbcApi -Method Post -Endpoint 'sql/statements' -Body $body
  if (-not $submit -or -not $submit.statement_id) { return $submit }
  $stmtId = $submit.statement_id
  # Poll
  $start = Get-Date
  while ($true) {
    Start-Sleep -Seconds 2
    $status = Invoke-DbcApi -Method Get -Endpoint "sql/statements/$stmtId"
    if (-not $status) { return @{ error = 'no status' } }
    if ($status.status -and $status.status.state -eq 'SUCCEEDED') { break }
    if ($status.status -and $status.status.state -eq 'FAILED') { return $status }
    if ((Get-Date) - $start -gt [TimeSpan]::FromMinutes(5)) { return @{ error = 'timeout' } }
  }
  $result = Invoke-DbcApi -Method Get -Endpoint "sql/statements/$stmtId/result"
  return $result
}

function Parse-NumberFromResult {
  param([object]$res)
  try {
    $json = $res | ConvertTo-Json -Depth 10
    $m = [regex]::Match($json, '\d+')
    if ($m.Success) { return [int]$m.Value }
    return $null
  } catch {
    return $null
  }
}

function Send-Alert-Email {
  param(
    [string]$subject,
    [string]$body
  )
  $smtpHost = $env:SMTP_HOST
  if (-not $smtpHost) { Add-Content -Path $global:LogFile -Value "SMTP_HOST not set; cannot send alert email."; return }
  $smtpPort = if ($env:SMTP_PORT) { [int]$env:SMTP_PORT } else { 25 }
  $smtpUser = $env:SMTP_USER
  $smtpPass = $env:SMTP_PASSWORD
  $from = if ($env:ALERT_FROM) { $env:ALERT_FROM } else { 'noreply@empresa.local' }
  $toList = if ($env:ALERT_RECIPIENTS) { $env:ALERT_RECIPIENTS.Split(',') } else { @('data-team@empresa.local') }

  $msg = New-Object System.Net.Mail.MailMessage
  $msg.From = $from
  foreach ($t in $toList) { $msg.To.Add($t.Trim()) }
  $msg.Subject = $subject
  $msg.Body = $body

  $client = New-Object System.Net.Mail.SmtpClient($smtpHost, $smtpPort)
  if ($smtpUser -and $smtpPass) {
    $cred = New-Object System.Net.NetworkCredential($smtpUser, $smtpPass)
    $client.Credentials = $cred
  }
  $client.EnableSsl = if ($env:SMTP_ENABLE_SSL) { [bool]::Parse($env:SMTP_ENABLE_SSL) } else { $false }
  try {
    $client.Send($msg)
    Add-Content -Path $global:LogFile -Value "Alert email sent to: $($toList -join ',')"
  } catch {
    Add-Content -Path $global:LogFile -Value "Failed to send alert email: $($_.Exception.Message)"
  }
}

# Ruta a los job JSON
$jobsBase = 'c:\desa\cresa\cre_implementacion\Fase 3\templates_ingenieria\config\jobs'

$jobFiles = Get-ChildItem -Path $jobsBase -Filter '*_job.json' -File -ErrorAction SilentlyContinue
if (-not $jobFiles) { Write-Warning "No se encontraron job JSON en $jobsBase"; exit 0 }

foreach ($jf in $jobFiles) {
  Create-Or-Update-JobFromFile -jsonPath $jf.FullName
}

Write-Host "Proceso finalizado."
