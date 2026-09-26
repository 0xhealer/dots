Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Install Scoop Packages"

$PackageFile = Join-Path `
    $Global:DotfilesRoot `
    "packages\scoop.txt"

$Packages = Get-PackageList `
    -File $PackageFile

# `scoop list` emits objects (Name, Version, ...), not text, so the old
# Select-String "^name\s" check never matched and every package was
# reinstalled on every run.
$InstalledPackages = @(
    scoop list | ForEach-Object {
        if ($_.PSObject.Properties['Name']) { $_.Name }
    }
)

foreach ($Package in $Packages) {

    try {

        if ($Package -notin $InstalledPackages) {

            Write-Host "[INSTALL] $Package" `
                -ForegroundColor Yellow

            scoop install $Package
        }
    }
    catch {

        Write-Host "[FAILED] $Package" `
            -ForegroundColor Red
    }
}

Write-Host "[INFO] Updating installed Scoop packages..." `
    -ForegroundColor Cyan

scoop update *
