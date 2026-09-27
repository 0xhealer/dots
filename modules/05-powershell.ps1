Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure PowerShell"

# -------------------------------------------------
# Paths
# -------------------------------------------------

$Documents = [Environment]::GetFolderPath("MyDocuments")

# Bootstrap locations (Documents)
$PwshDir   = Join-Path $Documents "PowerShell"
$LegacyDir = Join-Path $Documents "WindowsPowerShell"

$PwshProfile   = Join-Path $PwshDir "Microsoft.PowerShell_profile.ps1"
$LegacyProfile = Join-Path $LegacyDir "profile.ps1"

# Source of truth (user config)
$ConfigRoot  = Join-Path $HOME ".config\powershell"
$UserProfile = Join-Path $ConfigRoot "user_profile.ps1"

# -------------------------------------------------
# Ensure directories exist
# -------------------------------------------------

foreach ($Dir in @($PwshDir, $LegacyDir, $ConfigRoot)) {
    if (-not (Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    }
}

# -------------------------------------------------
# Ensure user profile exists
# -------------------------------------------------

if (-not (Test-Path $UserProfile)) {
    New-Item -ItemType File -Path $UserProfile -Force | Out-Null
}

# -------------------------------------------------
# Backup existing profiles
# -------------------------------------------------

$BackupDir = New-BackupDirectory "powershell"

if (Test-Path $PwshProfile) {
    Backup-Item `
        -Source $PwshProfile `
        -Destination (Join-Path $BackupDir "Microsoft.PowerShell_profile.ps1")
}

if (Test-Path $LegacyProfile) {
    Backup-Item `
        -Source $LegacyProfile `
        -Destination (Join-Path $BackupDir "WindowsPowerShell_profile.ps1")
}

# -------------------------------------------------
# Bootstrap loader
# -------------------------------------------------

$Bootstrap = @'
$ConfigRoot = Join-Path $HOME ".config\powershell"
$UserProfile = Join-Path $ConfigRoot "user_profile.ps1"

if (Test-Path $UserProfile) {
    try {
        . $UserProfile
    }
    catch {
        Write-Host "[WARN] Failed to load user_profile.ps1" -ForegroundColor Yellow
        Write-Host $_ -ForegroundColor DarkYellow
    }
}
'@

Set-Content -Path $PwshProfile -Value $Bootstrap -Encoding UTF8 -Force
Set-Content -Path $LegacyProfile -Value $Bootstrap -Encoding UTF8 -Force

# -------------------------------------------------
# Deploy user profile
# -------------------------------------------------

# The whole configs\powershell tree is deployed (user_profile.ps1 plus the
# aliases / fzf / zoxide / keybinds / prompt files and functions\ it loads).
# Previously only a single user_profile.ps1 was copied -- and that file did
# not exist in the repo, so this module threw and stopped the installer.

$SourceDir     = Join-Path $Global:DotfilesRoot "configs\powershell"
$SourceProfile = Join-Path $SourceDir "user_profile.ps1"

if (-not (Test-Path $SourceProfile)) {
    throw "PowerShell profile not found: $SourceProfile"
}

if (Test-Path $UserProfile) {
    Backup-Item `
        -Source $UserProfile `
        -Destination (Join-Path $BackupDir "user_profile.ps1")
}

Copy-Item `
    -Path (Join-Path $SourceDir "*") `
    -Destination $ConfigRoot `
    -Recurse `
    -Force

# Remove-Bloatware (configs\powershell\functions\system.ps1) runs the
# post-install module on demand, so keep a copy of it and its helper next to
# run.ps1 (which was copied with the tree above).
$BloatDir = Join-Path $ConfigRoot "bloatware"
New-Item -ItemType Directory -Path $BloatDir -Force | Out-Null
Copy-Item (Join-Path $Global:DotfilesRoot "helpers\common.ps1") (Join-Path $BloatDir "common.ps1") -Force
Copy-Item (Join-Path $Global:DotfilesRoot "modules\13-post-install.ps1") (Join-Path $BloatDir "post-install.ps1") -Force

Write-Host "[SUCCESS] PowerShell configured successfully." -ForegroundColor Green
Write-Host "Bootstrap profiles created:" -ForegroundColor DarkGray
Write-Host "  - $PwshProfile" -ForegroundColor DarkGray
Write-Host "  - $LegacyProfile" -ForegroundColor DarkGray
Write-Host "Profile files deployed to:" -ForegroundColor DarkGray
Write-Host "  - $ConfigRoot" -ForegroundColor DarkGray
