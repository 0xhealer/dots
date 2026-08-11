Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Windows Terminal"

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

$TerminalConfigDir = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

$TerminalSettingsFile = Join-Path $TerminalConfigDir "settings.json"

$SourceSettingsFile = Join-Path $Global:DotfilesRoot "configs\windows-terminal\settings.json"

# -----------------------------------------------------------------------------
# Validate Source Configuration
# -----------------------------------------------------------------------------

if (-not (Test-Path -LiteralPath $SourceSettingsFile)) {
throw "Windows Terminal configuration not found: $SourceSettingsFile"
}

# -----------------------------------------------------------------------------
# Backup Existing Configuration
# -----------------------------------------------------------------------------

if (Test-Path -LiteralPath $TerminalSettingsFile) {
$BackupDir = New-BackupDirectory "windows-terminal"
$BackupSettingsFile = Join-Path $BackupDir "settings.json"

Backup-Item `
    -Source $TerminalSettingsFile `
    -Destination $BackupSettingsFile

}

# -----------------------------------------------------------------------------
# Ensure Configuration Directory Exists
# -----------------------------------------------------------------------------

if (-not (Test-Path -LiteralPath $TerminalConfigDir)) {
New-Item `
-ItemType Directory `
-Path $TerminalConfigDir `
-Force |
Out-Null
}

# -----------------------------------------------------------------------------
# Deploy Configuration
# -----------------------------------------------------------------------------

Copy-Dotfile `
-Source $SourceSettingsFile `
-Destination $TerminalSettingsFile

Write-Host ""
Write-Host "[SUCCESS] Windows Terminal configured" -ForegroundColor Green
