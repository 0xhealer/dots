# run.ps1 -- what `Remove-Bloatware` runs (elevated). Loads the helper library
# and the post-install module that sit next to it (both copied here by
# modules/05-powershell.ps1) and runs the module as-is.
$ErrorActionPreference = 'Stop'
$Here = $PSScriptRoot
. (Join-Path $Here 'common.ps1')
. (Join-Path $Here 'post-install.ps1')
Write-Host ""
Write-Host "[DONE] Bloatware, telemetry, Edge and OneDrive removal finished. Reboot recommended." -ForegroundColor Green
Read-Host "Press Enter to close"
