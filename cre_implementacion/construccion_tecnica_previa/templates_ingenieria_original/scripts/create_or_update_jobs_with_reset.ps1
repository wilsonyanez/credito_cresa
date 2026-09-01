param(
  [string]$JobsDir = "templates_ingenieria\config\jobs",
  [switch]$SubmitRun,
  [int]$PollIntervalSeconds = 10
)

function Write-Log {
  param($Message)
  $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  $line = "$ts`t$Message"
  Add-Content -Path $Global:LogFile -Value $line
  Write-Output $line
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
  $uri = "$($env:DATABRICKS_HOST.TrimEnd('/'))/$Endpoint"
  $headers = @{ Authorization = "Bearer $($env:DATABRICKS_TOKEN)" }
  try {
    if ($Body) {
      $json = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 20 }
      return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType 'application/json' -Body $json -ErrorAction Stop
    } else {
      return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ErrorAction Stop
    }
  } catch {
    Write-Log "ERROR calling $uri : $($_.Exception.Message)"
    return $null
  }
}

if (-not (Test-Path $JobsDir)) { throw "Jobs directory not found: $JobsDir" }

$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$Global:LogFile = "templates_ingenieria\logs\create_jobs_$timestamp.log"
New-Item -ItemType File -Force -Path $Global:LogFile | Out-Null
Write-Log "Starting create_or_update_jobs_with_reset.ps1"

# Retrieve current jobs list once to minimize calls
$listResp = Invoke-DbcApi -Method GET -Endpoint 'api/2.0/jobs/list'
$existingJobs = @{}
if ($listResp -and $listResp.jobs) {
  foreach ($j in $listResp.jobs) { $existingJobs[$j.name] = $j.job_id }
}

Get-ChildItem -Path $JobsDir -Filter '*_job.json' | ForEach-Object {
  $jsonPath = $_.FullName
  Write-Log "Processing $jsonPath"
  try {
    $raw = Get-Content -Raw -Path $jsonPath -ErrorAction Stop
    $settings = $raw | ConvertFrom-Json -ErrorAction Stop
  } catch {
    Write-Log "Failed reading or parsing $jsonPath: $($_.Exception.Message)"
    return
  }

  $jobName = $settings.name
  if (-not $jobName) { Write-Log "No 'name' in $jsonPath; skipping"; return }

  if ($existingJobs.ContainsKey($jobName)) {
    $jobId = $existingJobs[$jobName]
    Write-Log "Found existing job '$jobName' (job_id=$jobId) — calling reset"
    $body = @{ job_id = $jobId; new_settings = $settings }
    $resp = Invoke-DbcApi -Method Post -Endpoint 'api/2.0/jobs/reset' -Body $body
    if ($resp -ne $null) { Write-Log "Reset OK for job_id=$jobId" } else { Write-Log "Reset failed for job_id=$jobId" }
  } else {
    Write-Log "Creating job '$jobName'"
    $resp = Invoke-DbcApi -Method Post -Endpoint 'api/2.0/jobs/create' -Body $settings
    if ($resp -and $resp.job_id) {
      Write-Log "Created job '$jobName' job_id=$($resp.job_id)"
      $jobId = $resp.job_id
    } else {
      Write-Log "Create failed for $jobName - response: $($resp | ConvertTo-Json -Depth 3)"
    }
  }

  if ($SubmitRun -and $jobId) {
    Write-Log "Submitting run for job_id=$jobId"
    $submitBody = @{ job_id = $jobId }
    $submitResp = Invoke-DbcApi -Method Post -Endpoint 'api/2.1/jobs/runs/submit' -Body $submitBody
    if ($submitResp -and $submitResp.run_id) {
      $runId = $submitResp.run_id
      Write-Log "Submitted run_id=$runId; polling status every $PollIntervalSeconds seconds"
      while ($true) {
        Start-Sleep -Seconds $PollIntervalSeconds
        $status = Invoke-DbcApi -Method GET -Endpoint "api/2.0/jobs/runs/get?run_id=$runId"
        if ($status -and $status.state) {
          $life = $status.state.life_cycle_state
          $resultState = $status.state.result_state
          Write-Log "Run $runId state: $life / result: $resultState"
          if ($life -eq 'TERMINATED' -or $life -eq 'INTERNAL_ERROR' -or $life -eq 'SKIPPED') {
            Write-Log "Run $runId finished with result: $resultState"
            $output = Invoke-DbcApi -Method GET -Endpoint "api/2.0/jobs/runs/get-output?run_id=$runId"
            Write-Log "Run output: $($output | ConvertTo-Json -Depth 6)"
            if ($resultState -ne 'SUCCESS') {
              Write-Log "Run failed or partially failed: $resultState"
            }
            break
          }
        } else {
          Write-Log "Unable to retrieve status for run $runId"
          break
        }
      }
    } else {
      Write-Log "Failed to submit run for job_id=$jobId"
    }
  }
}

Write-Log "Completed processing all job files. Log saved to $Global:LogFile"
