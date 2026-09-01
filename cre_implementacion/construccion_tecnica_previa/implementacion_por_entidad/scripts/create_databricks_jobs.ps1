# Script: create_databricks_jobs.ps1
# Propósito: Crear jobs en Databricks desde JSON (versión mejorada con cat_estadoverificacion)
# Autor: Equipo de Datos - Maestro
# Fecha: 2026-08-27
# Versión: 2.1 (ACTUALIZADO con cat_estadoverificacion)
# Uso: .\create_databricks_jobs.ps1 -Token "dapi-..." -Host "https://adb..." -Mode "create|test"

param(
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [Parameter(Mandatory=$false)]
    [string]$Host = "https://adbdlh01.cloud.databricks.com",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("create", "test", "dry-run")]
    [string]$Mode = "test",
    
    [Parameter(Mandatory=$false)]
    [string]$JobsConfigDir = ".\templates_ingenieria\config\jobs",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation
)

# ============================================
# CONFIGURACIÓN
# ============================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$LogDir = ".\logs"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogDir "jobs_$Mode`_$Timestamp.log"
$ErrorFile = Join-Path $LogDir "jobs_errors_$Timestamp.log"

# Array de jobs (ORDEN IMPORTANTE - precedencias)
$Jobs = @(
    "credito_cresa_cat_nacionalidad_job.json",
    "credito_cresa_cat_sexo_job.json",
    "credito_cresa_cat_estadocivil_job.json",
    "credito_cresa_cat_estadoverificacion_job.json",
    "credito_cresa_cat_nivelinstruccion_job.json",
    "credito_cresa_cat_provincia_job.json",
    "credito_cresa_cat_canton_job.json",
    "credito_cresa_cat_parroquia_job.json",
    "credito_cresa_cat_profesion_job.json",
    "credito_cresa_cat_solicitud_estados_job.json",
    "credito_cresa_cat_almacen_job.json"
    "credito_cresa_cat_modelo_aprobador_job.json",
    "credito_cresa_cat_origen_job.json",
    "credito_cresa_cat_modelo_calificacion_job.json",
    "credito_cresa_cat_tipovinculo_job.json",
    "credito_cresa_cat_tipoverificacion_job.json",
    "credito_cresa_cat_sector_job.json",
    "credito_cresa_cat_sector_riesgo_geocerca_job.json",
    "credito_cresa_cobro_tipo_credito_tb_job.json",
    "credito_cresa_com_cub_cobros_cuotas_cresa_tb_job.json",
    "credito_cresa_cre_solicitante_job.json",
    "credito_cresa_cre_solicitante_mina_job.json",
    "credito_cresa_cre_solicitud_job.json",
    "credito_cresa_cre_solicitud_bitacora_job.json",
    "credito_cresa_cre_solicituddomicilio_job.json",
    "credito_cresa_cre_solicitudlaboral_job.json",
    "credito_cresa_cub_cobro_cuotas_job.json",
    "credito_cresa_lcr_cuentas_job.json",
    "credito_cresa_lcr_graduacion_job.json",
    "credito_cresa_lcr_reserva_cuotas_job.json",
    "credito_cresa_sec_usuario_job.json",
    "credito_cresa_sis_peticiones_job.json",
    "credito_cresa_ver_respuesta_proveedor_job.json"

)

# ============================================
# FUNCIONES DE LOGGING
# ============================================

function Initialize-Logging {
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    
    $msg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Iniciando sesión de logs - Modo: $Mode"
    Add-Content -Path $LogFile -Value $msg -Force
    Write-Host $msg -ForegroundColor Cyan
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMsg = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMsg -Force
    
    $color = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "DEBUG" = "Gray"
    }
    
    Write-Host $logMsg -ForegroundColor $color[$Level]
}

# ============================================
# VALIDACIONES
# ============================================

function Test-Prerequisites {
    Write-Log "Validando pre-requisitos..." "INFO"
    
    $issues = @()
    
    # Validar Token
    if ([string]::IsNullOrEmpty($Token)) {
        $issues += "Token de Databricks no proporcionado"
    }
    
    # Validar Host
    if (-not ($Host -match 'https://')) {
        $issues += "Host debe ser HTTPS"
    }
    
    # Validar directorio de configs
    if (-not (Test-Path $JobsConfigDir)) {
        $issues += "Directorio de jobs no encontrado: $JobsConfigDir"
    }
    
    if ($issues.Count -gt 0) {
        Write-Log "Problemas encontrados:" "ERROR"
        $issues | ForEach-Object { Write-Log "  - $_" "ERROR" }
        throw "Pre-requisitos no cumplidos"
    }
    
    Write-Log "✓ Todos los pre-requisitos validados" "SUCCESS"
}

# ============================================
# CREACIÓN DE JOBS
# ============================================

function Create-Job {
    param(
        [string]$JobFile,
        [int]$Index,
        [int]$Total
    )
    
    $configPath = Join-Path $JobsConfigDir $JobFile
    
    Write-Log "[$Index/$Total] Procesando: $JobFile" "DEBUG"
    
    if (-not (Test-Path $configPath)) {
        Write-Log "Saltando: $JobFile (no encontrado)" "WARN"
        return @{ Status = "SKIPPED"; JobName = $JobFile; Message = "Archivo no encontrado" }
    }
    
    try {
        $jobConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json -ErrorAction Stop
        $jobName = $jobConfig.name
        
        Write-Log "  Job: $jobName" "DEBUG"
        
        # Modo DRY-RUN: solo simular
        if ($Mode -eq "dry-run") {
            Write-Log "  [DRY-RUN] Job '$jobName' sería creado" "INFO"
            return @{ Status = "DRY_RUN"; JobName = $jobName; JobId = "N/A" }
        }
        
        # Modo TEST: crear pero con parámetro run_mode=test
        if ($Mode -eq "test") {
            $jobConfig.notebook_task.base_parameters.run_mode = "test"
            $jobConfig.notebook_task.base_parameters.enable_quality_checks = "false"
            Write-Log "  [TEST] Modo test habilitado" "DEBUG"
        }
        
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type" = "application/json"
        }
        
        $body = $jobConfig | ConvertTo-Json -Depth 20
        
        Write-Log "  Enviando solicitud a Databricks API..." "DEBUG"
        
        $response = Invoke-RestMethod `
            -Uri "$Host/api/2.1/jobs/create" `
            -Method POST `
            -Headers $headers `
            -Body $body `
            -TimeoutSec 120 `
            -ErrorAction Stop
        
        $jobId = $response.job_id
        Write-Log "  ✓ Creado: $jobName (ID: $jobId)" "SUCCESS"
        
        return @{
            Status = "SUCCESS"
            JobName = $jobName
            JobId = $jobId
            ConfigPath = $configPath
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Add-Content -Path $ErrorFile -Value "$JobFile - Error: $errorMsg - $(Get-Date)" -Force
        
        return @{
            Status = "FAILED"
            JobName = $JobFile
            Error = $errorMsg
        }
    }
}

function Create-All-Jobs {
    Write-Log "======================================" "INFO"
    Write-Log "Iniciando creación de $($Jobs.Count) jobs" "INFO"
    Write-Log "Modo: $Mode" "INFO"
    Write-Log "======================================" "INFO"
    
    $results = @()
    
    for ($i = 0; $i -lt $Jobs.Count; $i++) {
        $result = Create-Job -JobFile $Jobs[$i] -Index ($i + 1) -Total $Jobs.Count
        $results += $result
        
        # Pequeña pausa entre requests
        Start-Sleep -Milliseconds 500
    }
    
    return $results
}

# ============================================
# GENERACIÓN DE REPORTES
# ============================================

function Generate-Report {
    param([array]$Results)
    
    $successful = $Results | Where-Object { $_.Status -eq "SUCCESS" }
    $failed = $Results | Where-Object { $_.Status -eq "FAILED" }
    $skipped = $Results | Where-Object { $_.Status -eq "SKIPPED" }
    $dryrun = $Results | Where-Object { $_.Status -eq "DRY_RUN" }
    
    Write-Log ""
    Write-Log "======================================" "INFO"
    Write-Log "RESUMEN DE EJECUCIÓN" "INFO"
    Write-Log "======================================" "INFO"
    Write-Log "Total procesados: $($Results.Count)" "INFO"
    Write-Log "Exitosos: $($successful.Count)" "SUCCESS"
    Write-Log "Fallidos: $($failed.Count)" "ERROR"
    Write-Log "Saltados: $($skipped.Count)" "WARN"
    Write-Log "Dry-run: $($dryrun.Count)" "DEBUG"
    
    if ($failed.Count -gt 0) {
        Write-Log ""
        Write-Log "JOBS FALLIDOS:" "ERROR"
        $failed | ForEach-Object {
            Write-Log "  - $($_.JobName): $($_.Error)" "ERROR"
        }
    }
    
    Write-Log ""
    Write-Log "JOBS EXITOSOS:" "SUCCESS"
    $successful | ForEach-Object {
        Write-Log "  ✓ $($_.JobName) (ID: $($_.JobId))" "SUCCESS"
    }
    
    Write-Log ""
    Write-Log "Logs: $LogFile" "INFO"
    Write-Log "Errores: $ErrorFile" "INFO"
    
    if ($failed.Count -gt 0) {
        return 1
    }
    return 0
}

# ============================================
# EJECUCIÓN PRINCIPAL
# ============================================

function Main {
    try {
        Initialize-Logging
        
        if (-not $SkipValidation) {
            Test-Prerequisites
        }
        
        $results = Create-All-Jobs
        $exitCode = Generate-Report $results
        
        Write-Log "======================================" "INFO"
        Write-Log "FINALIZADO" "INFO"
        Write-Log "======================================" "INFO"
        
        exit $exitCode
    }
    catch {
        Write-Log "ERROR FATAL: $_" "ERROR"
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
}

Main
