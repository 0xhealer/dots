Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure VS Code Insiders"

# -----------------------------------------------------------------------------

# Paths

# -----------------------------------------------------------------------------

$VSCodeConfigDir = Join-Path $env:APPDATA "Code - Insiders\User"
$SourceConfigDir = Join-Path $Global:DotfilesRoot "configs\vscode"

$ConfigFiles = @(
"settings.json"
"keybindings.json"
)

# -----------------------------------------------------------------------------

# Validate VS Code Insiders Installation

# -----------------------------------------------------------------------------

$VSCodeCommand = Get-Command "code-insiders" -ErrorAction SilentlyContinue

if (-not $VSCodeCommand) {
throw "VS Code Insiders is not installed or code-insiders is not available in PATH."
}

# -----------------------------------------------------------------------------

# Validate Source Configuration

# -----------------------------------------------------------------------------

if (-not (Test-Path -LiteralPath $SourceConfigDir)) {
throw "VS Code Insiders configuration directory not found: $SourceConfigDir"
}

foreach ($ConfigFile in $ConfigFiles) {
$SourceFile = Join-Path $SourceConfigDir $ConfigFile


if (-not (Test-Path -LiteralPath $SourceFile)) {
    throw "VS Code Insiders configuration file not found: $SourceFile"
}


}

# -----------------------------------------------------------------------------

# Initialize VS Code Insiders

# -----------------------------------------------------------------------------

if (-not (Test-Path -LiteralPath $VSCodeConfigDir)) {
Write-Host "[INFO] Initializing VS Code Insiders..." -ForegroundColor Yellow


Start-Process -FilePath $VSCodeCommand.Source

$TimeoutSeconds = 30
$ElapsedSeconds = 0

while (
    -not (Test-Path -LiteralPath $VSCodeConfigDir) -and
    $ElapsedSeconds -lt $TimeoutSeconds
) {
    Start-Sleep -Seconds 1
    $ElapsedSeconds++
}

if (-not (Test-Path -LiteralPath $VSCodeConfigDir)) {
    throw "VS Code Insiders initialization timed out after $TimeoutSeconds seconds."
}

Start-Sleep -Seconds 2

Get-Process -Name "Code - Insiders" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "[SUCCESS] VS Code Insiders initialized" -ForegroundColor Green


}

# -----------------------------------------------------------------------------

# Backup Existing Configuration

# -----------------------------------------------------------------------------

$ExistingConfigFiles = @(
$ConfigFiles | Where-Object {
Test-Path -LiteralPath (Join-Path $VSCodeConfigDir $_)
}
)

if ($ExistingConfigFiles.Count -gt 0) {
$BackupDir = New-BackupDirectory "vscode-insiders"


foreach ($ConfigFile in $ExistingConfigFiles) {
    $CurrentConfigFile = Join-Path $VSCodeConfigDir $ConfigFile
    $BackupConfigFile = Join-Path $BackupDir $ConfigFile

    $BackupParams = @{
        Source      = $CurrentConfigFile
        Destination = $BackupConfigFile
    }

    Backup-Item @BackupParams
}


}

# -----------------------------------------------------------------------------

# Deploy Configuration

# -----------------------------------------------------------------------------

foreach ($ConfigFile in $ConfigFiles) {
$SourceFile = Join-Path $SourceConfigDir $ConfigFile
$DestinationFile = Join-Path $VSCodeConfigDir $ConfigFile


$CopyParams = @{
    Source      = $SourceFile
    Destination = $DestinationFile
}

Copy-Dotfile @CopyParams


}

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "[SUCCESS] VS Code Insiders configured" -ForegroundColor Green
