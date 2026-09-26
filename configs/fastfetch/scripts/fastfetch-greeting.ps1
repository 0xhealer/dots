function ff-greeting {
    $nickname = "mango"

    $json = fastfetch --logo none -s title:kernel:shell --format json | ConvertFrom-Json

    $hostName  = ($json | Where-Object { $_.type -eq 'Title' }).result.hostName
    $kernel    = ($json | Where-Object { $_.type -eq 'Kernel' }).result.release
    $shellName = ($json | Where-Object { $_.type -eq 'Shell' }).result.exeName
    $shellVer  = ($json | Where-Object { $_.type -eq 'Shell' }).result.version

    Write-Host "`e[38;5;212m—`e[0m `e[38;5;212m🩸`e[0m `e[1;97m$hostName`e[0m `e[2m·`e[0m `e[97m$kernel`e[0m `e[2m·`e[0m `e[38;5;114m$nickname`e[0m `e[2m·`e[0m `e[38;5;213m$shellName $shellVer`e[0m `e[38;5;212m—`e[0m"
}
