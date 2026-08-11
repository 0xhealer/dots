Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Fastfetch"

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

# We explicitly target the folder name 'fastfetch' at the destination
$FastfetchConfigDir = Join-Path $HOME ".config\fastfetch"

$SourceConfigDir = Join-Path $Global:DotfilesRoot "configs\fastfetch"

# -----------------------------------------------------------------------------
# Backup Existing Configuration
# -----------------------------------------------------------------------------

# Only attempt backup if the configuration directory actually exists
if (Test-Path $FastfetchConfigDir) {
    $BackupDir = New-BackupDirectory "fastfetch"
    
    Backup-Item `
        -Source $FastfetchConfigDir `
        -Destination (Join-Path $BackupDir "fastfetch")
}

# -----------------------------------------------------------------------------
# Deploy Configuration
# -----------------------------------------------------------------------------

# Clear out any existing directory to ensure a completely clean, non-nested copy
if (Test-Path $FastfetchConfigDir) {
    Remove-Item $FastfetchConfigDir -Recurse -Force | Out-Null
}

# Copy-Dotfile will now automatically handle creating the parent directory (~/.config/)
Copy-Dotfile `
    -Source $SourceConfigDir `
    -Destination $FastfetchConfigDir

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "[SUCCESS] Fastfetch configured" -ForegroundColor Green
