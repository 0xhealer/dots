param (
    [string[]]$Modules
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# When this script relaunches itself elevated (below) the module list is
# passed through -File as ONE string ("starship,git"), which PowerShell does
# not split into an array. Normalise both forms: -Modules a,b  and  "a,b".
if ($Modules) {
    $Modules = @(
        $Modules |
        ForEach-Object { $_ -split ',' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
    )
}

function Test-IsAdmin {

    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = [Security.Principal.WindowsPrincipal]::new(
        $Identity
    )

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

# -----------------------------------------------------------------------------
# Elevation
# -----------------------------------------------------------------------------

if (-not (Test-IsAdmin)) {

    Write-Host "Requesting Administrator privileges..."

    $Shell = (Get-Process -Id $PID).Path

    $Arguments = @(
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        "`"$PSCommandPath`""
    )

    if ($Modules) {

        $Arguments += '-Modules'
        $Arguments += ($Modules -join ',')
    }

    Start-Process `
        -FilePath $Shell `
        -Verb RunAs `
        -WorkingDirectory (Get-Location) `
        -ArgumentList $Arguments

    exit
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

$CommonHelpers = Join-Path `
    $PSScriptRoot `
    "helpers\common.ps1"

if (-not (Test-Path $CommonHelpers)) {
    throw "helpers\common.ps1 not found."
}

. $CommonHelpers

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------

$Global:DotfilesRoot = $PSScriptRoot

$ModulePath = Join-Path `
    $DotfilesRoot `
    "modules"

# -----------------------------------------------------------------------------
# Header
# -----------------------------------------------------------------------------

Write-Host ""

Write-Host "========================================"

Write-Host `
    "Dotfiles Installer - PowerShell $($PSVersionTable.PSVersion)" `
    -ForegroundColor Cyan

Write-Host `
    "Running as Administrator" `
    -ForegroundColor Green

Write-Host "========================================"

Write-Host ""

# -----------------------------------------------------------------------------
# Discover Modules
# -----------------------------------------------------------------------------

$ModuleFiles = Get-ChildItem `
    -Path $ModulePath `
    -Filter "*.ps1" `
    -File |
Sort-Object Name

# -----------------------------------------------------------------------------
# Filter Requested Modules
# -----------------------------------------------------------------------------

if ($Modules) {

    $RequestedModules = $Modules |
    ForEach-Object {
        $_.ToLower().Trim()
    }

    $ModuleFiles = $ModuleFiles |
    Where-Object {

        $ModuleName = (
            $_.BaseName `
                -replace '^\d+[-_]?', ''
        ).ToLower()

        $ModuleName -in $RequestedModules
    }

    if (-not $ModuleFiles) {

        throw "No matching modules found."
    }
}

# -----------------------------------------------------------------------------
# Execute Modules
# -----------------------------------------------------------------------------

# If one of these fails nothing after it makes sense, so the run stops.
# Anything else is recorded and the remaining modules still run, so one
# broken optional step does not silently skip the rest of the setup.
$CriticalModules = @('prerequisites')

$FailedModules = @()

foreach ($Module in $ModuleFiles) {

    Write-ModuleHeader `
        "Running: $($Module.Name)"

    # winget / scoop write PATH to the registry only; pick up whatever the
    # previous modules installed (git, code-insiders, nvim, ...).
    Update-SessionPath

    try {

        & $Module.FullName

        Write-Host `
            "[SUCCESS] $($Module.Name)" `
            -ForegroundColor Green
    }
    catch {

        Write-Host `
            "[FAILED] $($Module.Name)" `
            -ForegroundColor Red

        Write-Host `
            $_.Exception.Message `
            -ForegroundColor Red

        $FailedModules += $Module.Name

        $ModuleName = ($Module.BaseName -replace '^\d+[-_]?', '').ToLower()

        if ($ModuleName -in $CriticalModules) {

            Write-Host `
                "Critical module failed - aborting." `
                -ForegroundColor Red

            break
        }
    }
}

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------

if ($FailedModules.Count -gt 0) {

    Write-ModuleHeader `
        "Installation finished WITH FAILURES"

    Write-Host `
        "Failed modules: $($FailedModules -join ', ')" `
        -ForegroundColor Red

    Write-Host `
        "Fix the cause, then re-run only those, e.g.: .\install.ps1 -Modules <name>" `
        -ForegroundColor Yellow

    # This window is a relaunched, elevated one - keep it open so the
    # errors above can actually be read.
    Read-Host "Press Enter to close" | Out-Null

    exit 1
}

Write-ModuleHeader `
    "Installation Complete"

if ($Modules) {

    # Partial run (-Modules ...): never reboot the machine for that.
    Read-Host "Press Enter to close" | Out-Null

    exit 0
}

Write-Host "Restarting in 15 seconds to finish setup - press Ctrl+C to cancel." `
    -ForegroundColor Yellow

Start-Sleep -Seconds 15

Restart-Computer -Force
