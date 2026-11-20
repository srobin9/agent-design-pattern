# Installs or updates 'lean-agent-architect' on Windows PowerShell
$ErrorActionPreference = "Stop"
$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcSkill = Join-Path $RepoDir ".agents\skills\lean-agent-architect"
$DestDir = Join-Path $HOME ".gemini\config\skills\lean-agent-architect"

New-Item -ItemType Directory -Force -Path (Join-Path $HOME ".gemini\config\skills") | Out-Null
if (Test-Path $DestDir) { Remove-Item -Recurse -Force $DestDir }
Copy-Item -Recurse -Force $SrcSkill $DestDir

Write-Host "Installed 'lean-agent-architect' globally to: $DestDir"
