[CmdletBinding()]
# Contexto 03: OutputRoot dirige el LOG; este lanzador despliega el piloto.
# Analisis de maestros y comandos: ../docs/CONTEXTO_03_MAESTROS.md.
param(
 [Alias('SourceRoot')][string]$BasePath = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
 [string]$CatalogName = 'cresa', [string]$LogPath,
 [string]$OutputRoot, [string]$DatabricksUser, [string]$WorkspaceId,
 [string]$ResourceId, [string]$GitHubRepository, [switch]$Authenticate,
 [string]$PythonPath, [string]$AuthName, [string]$WorkspaceUrl,
 [Alias('GitWorkspacePath')][string]$WorkspacePath, [string]$SqlWarehouseId, [string]$ClusterId,
 [string[]]$Entities, [ValidateRange(60,86400)][int]$TimeoutSeconds = 7200,
 [switch]$Deploy, [switch]$Resume
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib/cresa_credicresa_common.psm1') -Force
if ($Deploy -and $Resume) { throw 'Deploy y Resume son excluyentes.' }
$mode = if ($Resume) { 'resume' } elseif ($Deploy) { 'deploy' } else { 'plan' }
Invoke-CresaCredito -Mode $mode -Parameters $PSBoundParameters
