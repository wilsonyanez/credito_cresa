$ErrorActionPreference = 'Stop'

$packageRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$expectedFiles = @(
    'config\sources\credito_cresa.yml',
    'config\jobs\ingest_credito_cresa_source.json',
    'notebooks\00_deploy_bronze.py',
    'notebooks\01_create_source_database.py',
    'notebooks\ingest_databricks_source_to_parquet.py',
    'sql\00_create_test_environment.sql',
    'sql\01_create_control_plane.sql'
)

foreach ($relative in $expectedFiles) {
    $path = Join-Path $packageRoot $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Falta archivo obligatorio: $relative"
    }
}

$yamlFiles = @(Get-ChildItem -LiteralPath (Join-Path $packageRoot 'config\ingestion') -Filter '*.yml' -File)
if ($yamlFiles.Count -ne 34) {
    throw "Se esperaban 34 YAML de ingesta y se encontraron $($yamlFiles.Count)"
}

foreach ($yaml in $yamlFiles) {
    $content = Get-Content -LiteralPath $yaml.FullName -Raw
    foreach ($requiredKey in @('source_name:', 'source_table:', 'columns:', 'bronze_table:')) {
        if (-not $content.Contains($requiredKey)) {
            throw "$($yaml.Name) no contiene $requiredKey"
        }
    }
}

$jobPath = Join-Path $packageRoot 'config\jobs\ingest_credito_cresa_source.json'
$null = Get-Content -LiteralPath $jobPath -Raw | ConvertFrom-Json

$activeFiles = Get-ChildItem -LiteralPath $packageRoot -Recurse -File |
    Where-Object {
        $_.Extension -in @('.md', '.yml', '.yaml', '.json', '.py', '.sql', '.ps1') -and
        -not $_.FullName.Equals($PSCommandPath, [System.StringComparison]::OrdinalIgnoreCase)
    }
$stalePatterns = @(
    'analisis_caracterizacion/templates_ingenieria',
    'databricks/sql',
    'databricks/notebooks',
    'jdbc:sqlserver',
    'cresa-sqlserver-dev'
)
foreach ($file in $activeFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($pattern in $stalePatterns) {
        if ($content.Contains($pattern)) {
            throw "Referencia obsoleta '$pattern' en $($file.FullName)"
        }
    }
}

Write-Output "OK: paquete pre-productivo válido; $($yamlFiles.Count) YAML y job JSON correcto."
