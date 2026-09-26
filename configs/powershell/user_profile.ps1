# user_profile.ps1 -- the single entry point for this PowerShell setup.
#
# modules/05-powershell.ps1 copies this whole configs/powershell tree to
# ~/.config/powershell and writes tiny bootstrap profiles (for PowerShell 7
# and Windows PowerShell 5.1) that dot-source THIS file. It in turn loads
# the individual pieces below, in dependency order. Each piece is loaded
# on its own, so one broken file only prints a warning instead of taking
# down the rest of the profile.

if (-not $env:EDITOR) {
    $env:EDITOR = 'nvim'
}

$Parts = @(
    'functions\system.ps1'
    'functions\utils.ps1'
    'aliases.ps1'
    'fzf.ps1'
    'zoxide.ps1'
    'keybinds.ps1'
    'prompt.ps1'      # last: initialises starship and prints the header
)

foreach ($Part in $Parts) {
    $PartPath = Join-Path $PSScriptRoot $Part

    if (-not (Test-Path $PartPath)) {
        Write-Host "[WARN] profile: missing $Part" -ForegroundColor Yellow
        continue
    }

    try {
        . $PartPath
    }
    catch {
        Write-Host "[WARN] profile: failed to load $Part - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Remove-Variable Parts, Part, PartPath -ErrorAction SilentlyContinue
