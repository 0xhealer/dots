Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Install Winget Packages"

$PackageFile = Join-Path `
  $Global:DotfilesRoot `
  'packages\winget.txt'

$Packages = Get-Content $PackageFile | Where-Object {
  $_.Trim() -and -not $_.StartsWith('#')
}

# Ensure Winget sources are fresh
winget source update --disable-interactivity

foreach ($Package in $Packages) {

    Write-Host "`n[PROCESS] $Package" -ForegroundColor Cyan

    # -----------------------------
    # Install (idempotent approach)
    # -----------------------------

    & winget install `
        --id $Package `
        -e `
        --silent `
        --source winget `
        --accept-source-agreements `
        --accept-package-agreements

    # -1978335189 (0x8A15002B) = "no applicable update": already installed.
    # -1978335135 (0x8A150061) = "package already installed".
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Installed: $Package" -ForegroundColor Green
    }
    elseif ($LASTEXITCODE -in @(-1978335189, -1978335135)) {
        Write-Host "[SKIP] Already installed: $Package" -ForegroundColor Cyan
    }
    else {
        Write-Host "[WARN] Install may have failed: $Package (exit $LASTEXITCODE)" -ForegroundColor Yellow
    }
}
