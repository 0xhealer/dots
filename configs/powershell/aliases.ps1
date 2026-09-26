Remove-Item Alias:gc, Alias:gcm, Alias:gp, Alias:gl, Alias:h -Force -ErrorAction SilentlyContinue

function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ~ { Set-Location $HOME }
function - { Set-Location - }

# ============================================================================
# LS VARIANTS
# ============================================================================
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function l   { eza -l --group --color=always --group-directories-first @args }
    function ls  { eza -al --group --header --icons --group-directories-first @args }
    function ll  { eza -la --group --icons --group-directories-first @args }
    function la  { eza -la --group --icons --group-directories-first @args }
    function lt  { eza --tree --level=2 --icons @args }
    function lh  { eza -la --group --sort=modified --reverse @args }
}
else {
    function l   { Get-ChildItem @args }
    function ll  { Get-ChildItem -Force @args }
    function la  { Get-ChildItem -Force @args }
    function lt  { Get-ChildItem -Recurse -Depth 2 @args }
    function lh  { Get-ChildItem -Force | Sort-Object LastWriteTime -Descending }
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================
function cp { Copy-Item -Confirm @args }
function mv { Move-Item -Confirm @args }
function rm { Remove-Item -Confirm @args }
function mkdir { New-Item -ItemType Directory -Force -Verbose @args }

# ============================================================================
# SYSTEM INFO
# ============================================================================
function df { Get-Volume }
function du { param($Path = ".") Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum | ForEach-Object { "{0:N2} MB" -f ($_.Sum / 1MB) } }
function free { Get-CimInstance Win32_OperatingSystem | Select-Object @{n = 'TotalGB'; e = { [math]::Round($_.TotalVisibleMemorySize / 1MB, 2) } }, @{n = 'FreeGB'; e = { [math]::Round($_.FreePhysicalMemory / 1MB, 2) } } }
function ps { Get-Process @args }
function top { Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 }
function mem { Get-Process | Sort-Object WS -Descending | Select-Object -First 5 Name, @{n = 'MB'; e = { [math]::Round($_.WS / 1MB, 1) } } }
function cpu { Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU }

# ============================================================================
# NETWORK
# ============================================================================
function myip {
    (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^127\.' } | Select-Object -First 1).IPAddress
    Write-Host -NoNewline "External: "
    Invoke-RestMethod -Uri "https://ifconfig.me"
}
function ports { Get-NetTCPConnection }
function listening { Get-NetTCPConnection -State Listen }

# ============================================================================
# PACKAGE MANAGEMENT (winget - not a literal apt port, different tool shape)
# ============================================================================
function winstall { winget install -e --id $args --accept-package-agreements --accept-source-agreements --force --silent }
function search { winget search @args }
function update { winget source update }
function upgrade { winget upgrade --all }
function remove { winget uninstall @args }
function uplist { winget upgrade }

# ============================================================================
# GIT
# ============================================================================
function g { git @args }
function gs { git status @args }
function ga { git add @args }
function gaa { git add -A }
function gc { git commit @args }
function gcm { git commit -m @args }
function gp { git push @args }
function gpu { git push -u origin HEAD }
function gpl { git pull @args }
function gco { git checkout @args }
function gb { git branch @args }
function gd { git diff @args }
function gl { git log --oneline --graph --decorate }
function gclone { git clone @args }

# ============================================================================
# EDITORS AND CONFIG
# ============================================================================
function v { nvim @args }
function vv { nvim . }
function e { micro @args }
function n { nano @args }

function Edit-Profile { & (Get-Command $env:EDITOR -ErrorAction SilentlyContinue).Source $PROFILE }
function reload { . $PROFILE; Write-Host "Reloaded profile" }
function nvimrc { & $env:EDITOR "$HOME/AppData/Local/nvim/init.lua" }


# ============================================================================
# DIRECTORY SHORTCUTS
# ============================================================================
function g. { Set-Location "$HOME/.config" }
function dl { Set-Location "$HOME/Downloads" }
function doc { Set-Location "$HOME/Documents" }
function vid { Set-Location "$HOME/Videos" }

# ============================================================================
# UTILITIES
# ============================================================================
function c { Clear-Host }
function h { Get-History }
function j { Get-Job }
function which { Get-Command @args }
function now { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
function week { Get-Date -UFormat %V }

function grep { Select-String @args }

function biggest { Get-ChildItem -Directory | ForEach-Object { [PSCustomObject]@{ Name = $_.Name; SizeMB = [math]::Round((Get-ChildItem $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB, 1) } } | Sort-Object SizeMB }

function k9 { Stop-Process -Id $args[0] -Force }
function killall { param($Name) Stop-Process -Name $Name -Force -Verbose }

# tar ships natively on Windows 10 1803+ (bsdtar) - these work as-is,
# unlike most of the rest of this section.
function untar { tar -xvf @args }
function ungz { tar -xzvf @args }

function weather { Invoke-RestMethod "wttr.in/orlando?u" }
function ff { fastfetch }
