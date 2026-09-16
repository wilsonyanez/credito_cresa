[CmdletBinding()]
# Contexto 03: OutputRoot dirige el LOG; reversa limitada al manifiesto del piloto.
# Analisis de maestros y comandos: ../docs/CONTEXTO_03_MAESTROS.md.
param(
 [Alias('SourceRoot')][string]$BasePath = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
 [string]$CatalogName = 'cresa', [string]$LogPath,
 [string]$OutputRoot, [string]$DatabricksUser, [string]$WorkspaceId,
 [string]$ResourceId, [string]$GitHubRepository, [switch]$Authenticate,
 [string]$PythonPath, [string]$AuthName, [string]$WorkspaceUrl,
 [Alias('GitWorkspacePath')][string]$WorkspacePath, [string]$SqlWarehouseId,
 [ValidateRange(60,86400)][int]$TimeoutSeconds = 7200,
 [switch]$Execute, [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib/cresa_credicresa_common.psm1') -Force
if ($Execute -and $WhatIf) { throw 'Execute y WhatIf son excluyentes.' }
$mode = if ($Execute) { 'reverse' } elseif ($WhatIf) { 'inspect' } else { 'reverse-plan' }
Invoke-CresaCredito -Mode $mode -Parameters $PSBoundParameters
