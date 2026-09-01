$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$ingestion = Join-Path $root 'pre_productiva\config\ingestion'

Get-ChildItem -LiteralPath $ingestion -Filter '*.yml' -File | ForEach-Object {
    $lines = [System.IO.File]::ReadAllLines($_.FullName)
    $result = New-Object System.Collections.Generic.List[string]
    $insideQuery = $false
    $replaced = $false
    foreach ($line in $lines) {
        if ($line -eq 'query:') {
            $insideQuery = $true
            $replaced = $true
            $result.Add('read:')
            $result.Add('  mode: table')
            continue
        }
        if ($insideQuery) {
            if ($line -eq 'primary_key:') {
                $insideQuery = $false
                $result.Add('')
                $result.Add($line)
            }
            continue
        }
        $result.Add($line)
    }
    if (-not $replaced) {
        throw "No se encontró query: en $($_.FullName)"
    }
    [System.IO.File]::WriteAllLines($_.FullName, $result, [System.Text.UTF8Encoding]::new($false))
}

Write-Output 'Consultas SQL heredadas retiradas de los 34 YAML activos.'
