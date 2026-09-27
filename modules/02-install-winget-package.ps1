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

$Failed = @()

# Vendors whose manifest points at an unversioned "latest" download URL: the
# file changes without the manifest's hash being updated, so winget refuses it
# with 0x8A150011 (hash mismatch). For these only, retry once with the hash
# check overridden. (Everything else keeps full verification.)
$HashMismatch = -1978335215
$HashOverrideAllowed = @(
  'RazerInc.RazerInstaller.Synapse4'
  'Google.GoogleDrive'
  'Foxit.FoxitReader'
)

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

    if ($LASTEXITCODE -eq $HashMismatch -and $Package -in $HashOverrideAllowed) {
        Write-Host "[WARN] Installer hash mismatch for $Package (vendor updated the file) - retrying with the hash check overridden" -ForegroundColor Yellow
        winget settings --enable InstallerHashOverride | Out-Null
        & winget install `
            --id $Package `
            -e `
            --silent `
            --source winget `
            --accept-source-agreements `
            --accept-package-agreements `
            --ignore-security-hash
    }

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
        $Failed += $Package
    }
}

# -----------------------------------------------------------------------------
# Docker Desktop fallback
# -----------------------------------------------------------------------------
# winget's Docker.DockerDesktop often fails: the manifest's installer hash lags
# behind Docker's real download (hash mismatch), or the installer exits with a
# code winget treats as failure. When that happens, fetch Docker's own
# installer, check it is signed by Docker, and run it with the WSL 2 backend.
$DockerExe = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'

if (($Packages -contains 'Docker.DockerDesktop') -and -not (Test-Path $DockerExe)) {
    Write-Host "`n[DOCKER] winget did not install Docker Desktop - using Docker's official installer" -ForegroundColor Yellow

    $Installer = Join-Path $env:TEMP 'DockerDesktopInstaller.exe'
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $Url = 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe'
        if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
            $Url = 'https://desktop.docker.com/win/main/arm64/Docker%20Desktop%20Installer.exe'
        }
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Installer

        $Sig = Get-AuthenticodeSignature -FilePath $Installer
        if ($Sig.Status -ne 'Valid' -or $Sig.SignerCertificate.Subject -notmatch 'Docker') {
            throw "Docker installer signature check failed ($($Sig.Status): $($Sig.SignerCertificate.Subject))"
        }

        $Proc = Start-Process -FilePath $Installer `
            -ArgumentList 'install', '--quiet', '--accept-license', '--backend=wsl-2' `
            -Wait -PassThru
        # 0 = ok, 3010 = ok but reboot required
        if ($Proc.ExitCode -in @(0, 3010)) {
            Write-Host "[OK] Docker Desktop installed (exit $($Proc.ExitCode)) - reboot, then start Docker Desktop" -ForegroundColor Green
            $Failed = @($Failed | Where-Object { $_ -ne 'Docker.DockerDesktop' })
        }
        else {
            Write-Host "[WARN] Docker installer exited with $($Proc.ExitCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[WARN] Docker Desktop fallback failed - $($_.Exception.Message)" -ForegroundColor Yellow
    }
    finally {
        Remove-Item $Installer -Force -ErrorAction SilentlyContinue
    }
}

if ($Failed.Count -gt 0) {
    Write-Host "`n[SUMMARY] Not installed: $($Failed -join ', ')" -ForegroundColor Yellow
    Write-Host "Retry with: winget install --id <id> -e" -ForegroundColor DarkGray
}
