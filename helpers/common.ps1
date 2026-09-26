Set-StrictMode -Version Latest

function Write-ModuleHeader {
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host $Title -ForegroundColor Yellow
    Write-Host "========================================"
    Write-Host ""
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    return [bool](Get-Command `
        $Command `
        -ErrorAction SilentlyContinue)
}

# Re-reads Machine + User PATH into the current process. Installers (winget,
# scoop) update PATH in the registry only, so a later module in the SAME run
# would not find git / code-insiders / nvim until PATH is refreshed.
function Update-SessionPath {
    $Machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $User    = [System.Environment]::GetEnvironmentVariable('Path', 'User')

    $env:Path = (@($Machine, $User) | Where-Object { $_ }) -join ';'
}

function New-BackupDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$Category
    )

    $BackupRoot = Join-Path `
        $HOME `
        ".config\backups"

    $BackupDir = Join-Path `
        $BackupRoot `
        (Join-Path `
            (Get-Date -Format "yyyy-MM-dd") `
            $Category)

    New-Item `
        -ItemType Directory `
        -Path $BackupDir `
        -Force | Out-Null

    return $BackupDir
}

function Backup-Item {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        return
    }

    Copy-Item `
        -Path $Source `
        -Destination $Destination `
        -Recurse `
        -Force

    Write-Host "[SUCCESS] Backed up: $Source" `
        -ForegroundColor Green
}

function Copy-Dotfile {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        throw "Source does not exist: $Source"
    }

    $Parent = Split-Path `
        $Destination `
        -Parent

    New-Item `
        -ItemType Directory `
        -Path $Parent `
        -Force | Out-Null

    Copy-Item `
        -Path $Source `
        -Destination $Destination `
        -Recurse `
        -Force

    Write-Host "[SUCCESS] Deployed: $Destination" `
        -ForegroundColor Green
}

function Get-PackageList {
    param(
        [Parameter(Mandatory)]
        [string]$File
    )

    if (-not (Test-Path $File)) {
        throw "Package file not found: $File"
    }

    return Get-Content $File |
        Where-Object {
            $_.Trim() -and
            -not $_.Trim().StartsWith('#')
        }
}
function Remove-AppxPatterns {
    <#
      Removes installed + provisioned Appx packages matching wildcard names.
      Runs in Windows PowerShell 5.1: the Appx/DISM cmdlets are unreliable
      (often silently do nothing) when invoked from PowerShell 7.
    #>
    param(
        [Parameter(Mandatory)][string[]]$Patterns,
        [string[]]$Keep = @()
    )

    # Framework/runtime packages other things (winget, Store apps) depend on.
    $Protected = @(
        'Microsoft.DesktopAppInstaller', 'Microsoft.VCLibs*', 'Microsoft.UI.Xaml*',
        'Microsoft.NET.Native*', 'Microsoft.WindowsAppRuntime*', 'Microsoft.WinAppRuntime*',
        'Microsoft.SecHealthUI', 'Microsoft.StorePurchaseApp'
    )

    $Q = { param($a) ($a | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ',' }
    $Script = @"
`$ErrorActionPreference = 'SilentlyContinue'
`$Patterns  = @($(& $Q $Patterns))
`$Keep      = @($(& $Q ($Keep + $Protected)))
function Skip(`$n) { foreach (`$k in `$Keep) { if (`$n -like `$k) { return `$true } }; return `$false }
foreach (`$p in `$Patterns) {
    Get-AppxPackage -AllUsers | Where-Object { `$_.Name -like `$p -and -not (Skip `$_.Name) } | ForEach-Object {
        Write-Output ('[REMOVE] ' + `$_.Name)
        Remove-AppxPackage -Package `$_.PackageFullName -AllUsers
        if (Get-AppxPackage -Name `$_.Name) { Remove-AppxPackage -Package `$_.PackageFullName }
    }
    Get-AppxProvisionedPackage -Online | Where-Object { `$_.DisplayName -like `$p -and -not (Skip `$_.DisplayName) } | ForEach-Object {
        Remove-AppxProvisionedPackage -Online -AllUsers -PackageName `$_.PackageName | Out-Null
    }
}
foreach (`$p in `$Patterns) {
    Get-AppxPackage -AllUsers | Where-Object { `$_.Name -like `$p -and -not (Skip `$_.Name) } |
        ForEach-Object { Write-Output ('[LEFTOVER] ' + `$_.Name) }
}
"@

    $Tmp = Join-Path $env:TEMP ("appx-remove-{0}.ps1" -f [guid]::NewGuid())
    Set-Content -Path $Tmp -Value $Script -Encoding UTF8
    try {
        & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
            -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Tmp 2>&1 |
            ForEach-Object { Write-Host "$_" }
    }
    finally {
        Remove-Item $Tmp -Force -ErrorAction SilentlyContinue
    }
}
