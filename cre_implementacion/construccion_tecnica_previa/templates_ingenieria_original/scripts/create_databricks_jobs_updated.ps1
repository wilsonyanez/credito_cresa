# Script: create_databricks_jobs_updated.ps1
# Propósito: Crear jobs en Databricks desde JSON (versión mejorada)
# Autor: Equipo de Datos - Maestro
# Fecha: 2026-08-27
# Versión: 2.0 (ACTUALIZADO con cat_tipoverificacion + validaciones + alertas)
# Uso: .\create_databricks_jobs_updated.ps1 -Token "dapi-..." -Host "https://adb..." -Mode "create|test"

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
    "credito_cresa_cat_estadocivil_job.json",
    "credito_cresa_cat_sexo_job.json",
    "credito_cresa_cat_nivelinstruccion_job.json",
    "credito_cresa_cat_provincia_job.json",
    "credito_cresa_cat_canton_job.json",
    "credito_cresa_cat_parroquia_job.json",
    "credito_cresa_cat_origen_job.json",
    "credito_cresa_cat_modelo_aprobador_job.json",
    "credito_cresa_cat_modelo_calificacion_job.json",
    "credito_cresa_cat_solicitud_estados_job.json",
    "credito_cresa_cat_tipovinculo_job.json",
    "credito_cresa_cat_tipoverificacion_job.json"  # ← NUEVO (PRIORIDAD ALTA)
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

function Write-Error-Log {
    param([string]$Message, [object]$ErrorDetails)
    
    $errorMsg = "$Message`n$ErrorDetails`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Add-Content -Path $ErrorFile -Value $errorMsg -Force
    Write-Log $Message "ERROR"
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
    elseif ($Token.Length -lt 20) {
        $issues += "Token parece inválido (demasiado corto)"
    }
    
    # Validar Host
    if (-not ($Host -match 'https://')) {
        $issues += "Host debe ser HTTPS"
    }
    
    # Validar directorio de configs
    if (-not (Test-Path $JobsConfigDir)) {
        $issues += "Directorio de jobs no encontrado: $JobsConfigDir"
    }
    
    # Validar acceso a internet/Databricks
    try {
        $response = Invoke-WebRequest -Uri "$Host/api/2.1/workspace/get-status" `
            -Headers @{"Authorization" = "Bearer $Token"} `
            -TimeoutSec 10 -ErrorAction Stop
        Write-Log "✓ Conexión a Databricks validada" "SUCCESS"
    }
    catch {
        $issues += "No se puede conectar a Databricks: $($_.Exception.Message)"
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
        Write-Error-Log "Error en $JobFile" $_.Exception
        
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
# VALIDACIONES POST-CREACIÓN
# ============================================

function Get-ValidationSQL {
    return @"
-- ========================================
-- SQL DE VALIDACIÓN: cat_tipoverificacion
-- ========================================

-- 1. Conteo total
SELECT 
  COUNT(*) AS total_registros,
  COUNT(DISTINCT id) AS ids_unicos,
  COUNT(DISTINCT nombre) AS nombres_unicos
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;

-- 2. Duplicados (PRIMARY KEY)
SELECT id, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion
GROUP BY id
HAVING COUNT(*) > 1;

-- 3. Validar estado (0 o 1)
SELECT DISTINCT estado, COUNT(*) AS cnt
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion
GROUP BY estado;

-- 4. Nulos en críticos
SELECT 
  COUNTIF(id IS NULL) AS nulls_id,
  COUNTIF(nombre IS NULL) AS nulls_nombre,
  COUNTIF(jerarquia IS NULL) AS nulls_jerarquia
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;

-- 5. Rango temporal
SELECT 
  MIN(creado) AS fecha_min,
  MAX(creado) AS fecha_max,
  DATEDIFF(DAY, MIN(creado), MAX(creado)) AS dias_span
FROM dlh_cresa.bronze.credito_cresa_cat_tipoverificacion;

"@
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
    Write-Log "SQL DE VALIDACIÓN PARA cat_tipoverificacion:" "INFO"
    Write-Log (Get-ValidationSQL) "DEBUG"
    
    Write-Log ""
    Write-Log "Logs: $LogFile" "INFO"
    Write-Log "Errores: $ErrorFile" "INFO"
    
    # Retornar código de salida
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
        Write-Error-Log "ERROR FATAL" $_
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
}

Main
