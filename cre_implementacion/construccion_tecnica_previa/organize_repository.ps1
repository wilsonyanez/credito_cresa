$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$expected = 'C:\desa\git\credito_cresa\cre_implementacion'
if (-not $root.Equals($expected, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Raíz inesperada: $root"
}

function Assert-InWorkspace([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not ($full.Equals($root, [System.StringComparison]::OrdinalIgnoreCase) -or
              $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
        throw "Ruta fuera del workspace: $full"
    }
    return $full
}

function Ensure-Directory([string]$RelativePath) {
    $path = Assert-InWorkspace (Join-Path $root $RelativePath)
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
    return $path
}

function Move-Exact([string]$SourceRelative, [string]$DestinationRelative) {
    $source = Assert-InWorkspace (Join-Path $root $SourceRelative)
    $destination = Assert-InWorkspace (Join-Path $root $DestinationRelative)
    if (-not (Test-Path -LiteralPath $source)) {
        if (Test-Path -LiteralPath $destination) {
            return
        }
        throw "No existe el origen ni el destino esperado: $source"
    }
    $destinationParent = Split-Path -Parent $destination
    Ensure-Directory ($destinationParent.Substring($root.Length).TrimStart('\')) | Out-Null
    if (Test-Path -LiteralPath $destination) {
        throw "Ya existe el destino: $destination"
    }
    Move-Item -LiteralPath $source -Destination $destination
}

function Move-DirectoryContents([string]$SourceRelative, [string]$DestinationRelative) {
    $source = Assert-InWorkspace (Join-Path $root $SourceRelative)
    $destination = Assert-InWorkspace (Join-Path $root $DestinationRelative)
    if (-not (Test-Path -LiteralPath $source)) {
        return
    }
    Ensure-Directory $DestinationRelative | Out-Null
    Get-ChildItem -LiteralPath $source -Force | ForEach-Object {
        $target = Join-Path $destination $_.Name
        if (Test-Path -LiteralPath $target) {
            throw "Colisión al archivar: $target"
        }
        Move-Item -LiteralPath $_.FullName -Destination $destination
    }
    Remove-Item -LiteralPath $source
}

$directories = @(
    'documentacion_insumo\analisis_caracterizacion',
    'documentacion_insumo\imagenes',
    'construccion_tecnica_previa',
    'construccion_tecnica_previa\implementacion_por_entidad',
    'construccion_tecnica_previa\prototipos_databricks',
    'pre_productiva\config\sources',
    'pre_productiva\config\jobs',
    'pre_productiva\notebooks',
    'pre_productiva\sql',
    'pre_productiva\docs',
    'pre_productiva\scripts',
    'pre_productiva\tests'
)
$directories | ForEach-Object { Ensure-Directory $_ | Out-Null }

$analysisRoot = Assert-InWorkspace (Join-Path $root 'analisis_caracterizacion')
$analysisDestination = Assert-InWorkspace (Join-Path $root 'documentacion_insumo\analisis_caracterizacion')
Get-ChildItem -LiteralPath $analysisRoot -File | ForEach-Object {
    Move-Item -LiteralPath $_.FullName -Destination $analysisDestination
}

Move-Exact 'analisis_caracterizacion\templates_ingenieria\config\ingestion' 'pre_productiva\config\ingestion'
Move-Exact 'analisis_caracterizacion\templates_ingenieria\config\sources\credito_cresa.yml' 'pre_productiva\config\sources\credito_cresa.yml'
Move-Exact 'analisis_caracterizacion\templates_ingenieria\config\jobs\ingest_credito_cresa_source.json' 'pre_productiva\config\jobs\ingest_credito_cresa_source.json'
Move-Exact 'analisis_caracterizacion\templates_ingenieria\notebooks\ingest_source_to_parquet.py' 'pre_productiva\notebooks\ingest_source_to_parquet.py'
Move-Exact 'analisis_caracterizacion\templates_ingenieria\docs\PIPELINE_POR_FUENTE.md' 'pre_productiva\docs\PIPELINE_POR_FUENTE.md'
Move-DirectoryContents 'analisis_caracterizacion\templates_ingenieria' 'construccion_tecnica_previa\implementacion_por_entidad'

Move-Exact 'templates_ingenieria' 'construccion_tecnica_previa\templates_ingenieria_original'
Move-Exact 'databricks\notebooks' 'construccion_tecnica_previa\prototipos_databricks\notebooks'
Move-Exact 'databricks\README.md' 'construccion_tecnica_previa\prototipos_databricks\README.md'
Move-Exact 'databricks\sql\00_create_test_environment.sql' 'pre_productiva\sql\00_create_test_environment.sql'
Move-Exact 'databricks\sql\01_create_control_plane.sql' 'pre_productiva\sql\01_create_control_plane.sql'
Move-Exact 'docs\DATABRICKS_CONNECT.md' 'pre_productiva\docs\DATABRICKS_CONNECT.md'
Move-Exact 'scripts\setup_databricks_connect.ps1' 'pre_productiva\scripts\setup_databricks_connect.ps1'
Move-Exact 'tests\smoke_databricks_connect.py' 'pre_productiva\tests\smoke_databricks_connect.py'
Move-Exact '.env.example' 'pre_productiva\.env.example'
Move-Exact 'imagenes' 'documentacion_insumo\imagenes\diagramas'

$emptyCandidates = @('analisis_caracterizacion', 'databricks\sql', 'databricks', 'docs', 'scripts', 'tests')
foreach ($relative in $emptyCandidates) {
    $path = Assert-InWorkspace (Join-Path $root $relative)
    if ((Test-Path -LiteralPath $path) -and -not (Get-ChildItem -LiteralPath $path -Force)) {
        Remove-Item -LiteralPath $path
    }
}

Write-Output 'Repositorio reorganizado correctamente.'
