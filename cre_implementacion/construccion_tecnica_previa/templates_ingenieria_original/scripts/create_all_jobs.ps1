<#
.SYNOPSIS
  Crea/reset todos los jobs JSON y opcionalmente envía runs y alerta por SMTP.
#>
param(
  [switch] $SubmitRun
)

Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$jobsDir = Join-Path $scriptDir '..\config\jobs' | Resolve-Path
$logsDir = Join-Path $scriptDir '..\logs' | Resolve-Path
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

if (-not $env:DATABRICKS_HOST -or -not $env:DATABRICKS_TOKEN) {
  Write-Error "Debe exportar DATABRICKS_HOST y DATABRICKS_TOKEN"
  exit 2
}

$host = $env:DATABRICKS_HOST.TrimEnd('/')
$token = $env:DATABRICKS_TOKEN

# SMTP optional
$smtpHost = $env:SMTP_HOST
$smtpPort = [int]($env:SMTP_PORT -as [int] ?? 25)
$smtpUser = $env:SMTP_USER
$smtpPass = $env:SMTP_PASSWORD
$alertRecipients = $env:ALERT_RECIPIENTS
$alertFrom = $env:ALERT_FROM -or 'alerts@localhost'

function Invoke-DbcApi {
  param($Method, $Uri, $Body)
  $headers = @{ Authorization = "Bearer $token" }
  if ($null -ne $Body) {
    $resp = Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType 'application/json' -Body ($Body | ConvertTo-Json -Depth 10)
  } else {
    $resp = Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
  }
  return $resp
}

function Send-Alert-Email {
  param($Subject, $Body)
  if (-not $alertRecipients) { return }
  try {
    $mail = New-Object System.Net.Mail.MailMessage
    $mail.From = $alertFrom
    $alertRecipients.Split(',') | ForEach-Object { $mail.To.Add($_) }
    $mail.Subject = $Subject
    $mail.Body = $Body

    $smtp = New-Object System.Net.Mail.SmtpClient($smtpHost, $smtpPort)
    if ($smtpUser) {
      $smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPass)
    }
    $smtp.EnableSsl = [bool]($env:SMTP_ENABLE_SSL -eq 'true')
    $smtp.Send($mail)
  } catch {
    Write-Warning "No se pudo enviar email: $_"
  }
}

Write-Host "Scanning jobs in $jobsDir"
Get-ChildItem -Path $jobsDir -Filter '*_job.json' | ForEach-Object {
  $jobFile = $_.FullName
  $jobJson = Get-Content $jobFile -Raw | ConvertFrom-Json
  $name = $jobJson.name
  Write-Host "Processing $name"

  # Try to find existing job by name
  $list = Invoke-DbcApi -Method GET -Uri "$host/api/2.0/jobs/list"
  $found = $list.jobs | Where-Object { ($_.settings.name -or $_.settings.task.name) -eq $name }
  if ($found) {
    $jobId = $found[0].job_id
    Write-Host "Job exists (id=$jobId). Resetting"
    $body = @{ job_id = $jobId; new_settings = $jobJson }
    $resp = Invoke-DbcApi -Method POST -Uri "$host/api/2.0/jobs/reset" -Body $body
  } else {
    Write-Host "Creating job $name"
    $resp = Invoke-DbcApi -Method POST -Uri "$host/api/2.0/jobs/create" -Body $jobJson
    $jobId = $resp.job_id
  }

  if ($SubmitRun -and $jobId) {
    Write-Host "Submitting run for job_id=$jobId"
    $sub = Invoke-DbcApi -Method POST -Uri "$host/api/2.1/jobs/runs/submit" -Body @{ job_id = $jobId }
    $runId = $sub.run_id
    if (-not $runId) { Write-Warning "No run_id returned for job $name" ; return }
    # Poll
    $start = Get-Date
    while ($true) {
      Start-Sleep -Seconds 5
      $status = Invoke-DbcApi -Method GET -Uri "$host/api/2.0/jobs/runs/get?run_id=$runId"
      $life = $status.state.life_cycle_state
      $result = $status.state.result_state
      Write-Host "  run state: $life / result: $result"
      if ($life -in @('TERMINATED','INTERNAL_ERROR','SKIPPED')) {
        if ($result -ne 'SUCCESS') {
          $subj = "[ALERTA] Job $name run_id=$runId result=$result"
          $body = "Job: $name`nRun: $runId`nResult: $result`nLogs: $logsDir"
          Send-Alert-Email -Subject $subj -Body $body
        }
        break
      }
      if ((Get-Date) - $start -gt (New-TimeSpan -Minutes 15)) { Write-Warning "Timeout polling run $runId" ; break }
    }
  }
}

Write-Host "Completed. Logs in $logsDir"
param(
  [switch]$SubmitRun,
  [int]$PollIntervalSeconds = 5
)

$scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$templatesRoot = Split-Path -Parent $scriptFolder
$jobsBase = Join-Path $templatesRoot 'config\jobs'
$logDir = Join-Path $templatesRoot 'logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logFile = Join-Path $logDir "create_all_jobs_$timestamp.log"

function Write-Log {
  param($msg)
  $line = "$(Get-Date -Format o) - $msg"
  Add-Content -Path $logFile -Value $line
  Write-Host $line
}

function Invoke-DbcApi {
  param(
    [string]$Method = 'GET',
    [string]$Endpoint,
    $Body = $null
  )
  if (-not $env:DATABRICKS_HOST -or -not $env:DATABRICKS_TOKEN) {
    throw "DATABRICKS_HOST and DATABRICKS_TOKEN must be set as environment variables."
  }
  $host = $env:DATABRICKS_HOST.TrimEnd('/')
  $token = $env:DATABRICKS_TOKEN
  $uri = "$host/api/2.0/$Endpoint"
  $headers = @{ Authorization = "Bearer $token" }
  try {
    if ($Body -ne $null) {
      $bodyJson = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 20 }
      return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType 'application/json' -Body $bodyJson -ErrorAction Stop
    } else {
      return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ErrorAction Stop
    }
  } catch {
    Write-Log "API call failed: $($_.Exception.Message) for $uri"
    if ($_.Exception.Response) {
      try { $b = (New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd(); Write-Log $b } catch {}
    }
    return $null
  }
}

function Send-Alert-Email {
  param(
    [string]$subject,
    [string]$body
  )
  $smtpHost = $env:SMTP_HOST
  if (-not $smtpHost) { Write-Log "SMTP_HOST not set; cannot send alert email."; return }
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
    Write-Log "Alert email sent to: $($toList -join ',')"
  } catch {
    Write-Log "Failed to send alert email: $($_.Exception.Message)"
  }
}

Write-Log "Starting create_all_jobs.ps1"

Write-Log "Listing existing jobs"
$listResp = Invoke-DbcApi -Method Get -Endpoint 'jobs/list'
$existingJobs = @{}
if ($listResp -and $listResp.jobs) {
  foreach ($j in $listResp.jobs) {
    $name = $null
    if ($j.settings -and $j.settings.name) { $name = $j.settings.name }
    elseif ($j.settings -and $j.settings.task -and $j.settings.task.name) { $name = $j.settings.task.name }
    if ($name) { $existingJobs[$name] = $j.job_id }
  }
}

if (-not (Test-Path $jobsBase)) { Write-Log "Jobs directory not found: $jobsBase"; exit 1 }

Get-ChildItem -Path $jobsBase -Filter '*_job.json' -File | ForEach-Object {
  $jsonPath = $_.FullName
  Write-Log "Processing $jsonPath"
  try {
    $raw = Get-Content -Raw -Path $jsonPath -ErrorAction Stop
    $jobObj = $raw | ConvertFrom-Json -ErrorAction Stop
  } catch {
    Write-Log "Failed reading/parsing $jsonPath: $($_.Exception.Message)"
    return
  }
  $jobName = $jobObj.name
  if (-not $jobName) { Write-Log "No 'name' in $jsonPath; skipping"; return }

  $jobId = $null
  if ($existingJobs.ContainsKey($jobName)) { $jobId = $existingJobs[$jobName] }

  if ($jobId) {
    Write-Log "Job exists: $jobName (job_id=$jobId). Calling reset."
    $body = @{ job_id = $jobId; new_settings = $jobObj }
    $resp = Invoke-DbcApi -Method Post -Endpoint 'jobs/reset' -Body $body
    $respFile = Join-Path $logDir "reset_resp_${jobName}_$timestamp.json"
    $resp | ConvertTo-Json -Depth 5 | Out-File -FilePath $respFile -Encoding utf8
    Write-Log "Reset response saved to $respFile"
  } else {
    Write-Log "Creating job: $jobName"
    $resp = Invoke-DbcApi -Method Post -Endpoint 'jobs/create' -Body $jobObj
    $respFile = Join-Path $logDir "create_resp_${jobName}_$timestamp.json"
    if ($resp) { $resp | ConvertTo-Json -Depth 5 | Out-File -FilePath $respFile -Encoding utf8 }
    Write-Log "Create response saved to $respFile"
    if ($resp -and $resp.job_id) { $jobId = $resp.job_id }
  }

  if ($SubmitRun -and $jobId) {
    Write-Log "Submitting run for job_id=$jobId"
    $submitBody = @{ job_id = [int]$jobId }
    $submitResp = Invoke-DbcApi -Method Post -Endpoint 'jobs/runs/submit' -Body $submitBody
    $submitFile = Join-Path $logDir "submit_resp_${jobId}_$timestamp.json"
    if ($submitResp) { $submitResp | ConvertTo-Json -Depth 5 | Out-File -FilePath $submitFile -Encoding utf8 }
    $runId = $null
    if ($submitResp -and $submitResp.run_id) { $runId = $submitResp.run_id }
    if (-not $runId) { Write-Log "No run_id returned for job_id=$jobId"; return }
    Write-Log "Run submitted run_id=$runId; polling every $PollIntervalSeconds seconds"
    $start = Get-Date
    while ($true) {
      Start-Sleep -Seconds $PollIntervalSeconds
      $status = Invoke-DbcApi -Method Get -Endpoint "jobs/runs/get?run_id=$runId"
      $statusFile = Join-Path $logDir "run_status_${runId}_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
      if ($status) { $status | ConvertTo-Json -Depth 6 | Out-File -FilePath $statusFile -Encoding utf8 }
      if ($status -and $status.state) {
        $life = $status.state.life_cycle_state
        $resultState = $status.state.result_state
        Write-Log "Run $runId state: $life / result: $resultState"
        if ($life -eq 'TERMINATED' -or $life -eq 'INTERNAL_ERROR' -or $life -eq 'SKIPPED') {
          Write-Log "Run $runId finished with result: $resultState"
          if ($resultState -ne 'SUCCESS') {
            try {
              $subject = "[ALERTA] Run fallido: $jobName (job_id=$jobId)"
              $body = "El run $runId del job $jobName (job_id=$jobId) finalizó con estado: $resultState.`nRevisa los logs en: $logFile`nArchivo de estado: $statusFile"
              Send-Alert-Email -subject $subject -body $body
            } catch {
              Write-Log "Error enviando alerta: $($_.Exception.Message)"
            }
          }
          break
        }
      } else {
        Write-Log "Unable to retrieve status for run $runId"
        break
      }
      if ((Get-Date) - $start -gt [TimeSpan]::FromMinutes(15)) { Write-Log "Run $runId timeout"; break }
    }
  }
}

Write-Log "Completed. Log saved to $logFile"
