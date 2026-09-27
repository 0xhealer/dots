# Port of bash/functions/system.bash

function Test-CommandExists {
    param([Parameter(Mandatory)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function psg {
    param([string]$Name)
    if (-not $Name) {
        Write-Host "Usage: psg <process_name>"
        return
    }
    Get-Process | Where-Object { $_.ProcessName -match $Name } |
        Format-Table Id, ProcessName, CPU, WS -AutoSize
}

function sysinfo {
    Write-Host "=== System Information ==="
    Write-Host "Hostname: $env:COMPUTERNAME"
    Write-Host "Kernel:   $([System.Environment]::OSVersion.VersionString)"

    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    Write-Host "Uptime:   $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"

    $memUsedGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
    $memTotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    Write-Host "Memory:   ${memUsedGB}GB / ${memTotalGB}GB"


    $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    Write-Host "CPU load: ${cpuLoad}%"

    $disk = Get-PSDrive -Name ($env:SystemDrive -replace ':', '')
    $diskUsedGB = [math]::Round(($disk.Used) / 1GB, 1)
    $diskTotalGB = [math]::Round(($disk.Used + $disk.Free) / 1GB, 1)
    Write-Host "Disk:     ${diskUsedGB}GB / ${diskTotalGB}GB"
}

function install_tools {
    Write-Host "Installing fzf and ripgrep..."

    if (-not (Test-CommandExists fzf)) {
        Write-Host "Installing fzf..."
        winget install --id junegunn.fzf -e
    } else {
        Write-Host "fzf already installed"
    }

    if (-not (Test-CommandExists rg)) {
        Write-Host "Installing ripgrep..."
        winget install --id BurntSushi.ripgrep.MSVC -e
    } else {
        Write-Host "ripgrep already installed"
    }

    Write-Host "Tools installation complete!"
    Write-Host "Reload your profile with: reload"
}

# ----------------------------------------------------------------------------
# Remove-Bloatware (alias: debloat)
# Runs the same post-install module the installer uses: removes consumer/
# preinstalled apps, Copilot/Recall/AI, Edge, OneDrive, telemetry, and applies
# the privacy/UI tweaks. Elevates itself (UAC prompt) and runs in a new window.
# ----------------------------------------------------------------------------
function Remove-Bloatware {
    $Dir = Join-Path $HOME '.config\powershell\bloatware'
    $Files = @{
        'run.ps1'          = 'configs/powershell/bloatware/run.ps1'
        'common.ps1'       = 'helpers/common.ps1'
        'post-install.ps1' = 'modules/13-post-install.ps1'
    }

    # Self-heal: fetch anything missing from the repo.
    foreach ($Name in $Files.Keys) {
        $Path = Join-Path $Dir $Name
        if (-not (Test-Path $Path)) {
            try {
                New-Item -ItemType Directory -Path $Dir -Force | Out-Null
                $Url = "https://raw.githubusercontent.com/0xhealer/dots/main/$($Files[$Name])"
                Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Path
            }
            catch {
                Write-Host "[ERROR] Could not get $Name - $($_.Exception.Message)" -ForegroundColor Red
                return
            }
        }
    }

    $Run = Join-Path $Dir 'run.ps1'
    $Shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
    $ShellArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$Run`"")

    $Principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        & $Shell @ShellArgs
    }
    else {
        Start-Process -FilePath $Shell -ArgumentList $ShellArgs -Verb RunAs
    }
}
Set-Alias -Name debloat -Value Remove-Bloatware
