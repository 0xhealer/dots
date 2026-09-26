Invoke-Expression (&starship init powershell)

function Show-PromptHeader {
    if ($script:_PromptHeaderShown) { return }
    $script:_PromptHeaderShown = $true

    if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) { return }

    $json = fastfetch --logo none -s title:wm:shell --format json | ConvertFrom-Json

    $hostName  = ($json | Where-Object { $_.type -eq 'Title' }).result.hostName
    $wmResult  = ($json | Where-Object { $_.type -eq 'WM' }).result
    $wm        = if ($wmResult.prettyName) { $wmResult.prettyName } else { "unknown" }
    $shellName = ($json | Where-Object { $_.type -eq 'Shell' }).result.exeName
    $shellVer  = ($json | Where-Object { $_.type -eq 'Shell' }).result.version

    $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' } |
        Select-Object -First 1).IPAddress
    if (-not $ip) { $ip = "no ip" }

    Write-Host "`e[38;5;212m—`e[0m `e[38;5;212m🩸`e[0m `e[1;97m$hostName`e[0m `e[2m·`e[0m `e[97m$ip`e[0m `e[2m·`e[0m `e[38;5;114m$wm`e[0m `e[2m·`e[0m `e[38;5;213m$shellName $shellVer`e[0m `e[38;5;212m—`e[0m"
    Write-Host ""
}

Show-PromptHeader
