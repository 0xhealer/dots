# Port of bash/functions/utils.bash

function mkcd {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location $Path
}

function extract {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path -PathType Leaf)) {
        Write-Host "'$Path' is not a valid file"
        return
    }


    switch -Regex ($Path) {
        '\.zip$'                    { Expand-Archive -Path $Path -DestinationPath . }
        '\.(tar\.gz|tgz)$'          { tar xzf $Path }
        '\.(tar\.bz2|tbz2)$'        { tar xjf $Path }
        '\.tar\.xz$'                { tar xJf $Path }
        '\.tar\.zst$'               { tar --zstd -xf $Path }
        '\.tar$'                    { tar xf $Path }
        '\.7z$'                     { 7z x $Path }
        '\.gz$'                     { tar xzf $Path }
        default                     { Write-Host "'$Path' cannot be extracted" }
    }
}

function hgrep {
    param([string]$Pattern)
    Get-History | Where-Object { $_.CommandLine -match $Pattern }
}

function dirsize {
    param([string]$Path = ".")
    $bytes = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    "{0:N2} MB" -f ($bytes / 1MB)
}

function path {

    $env:PATH -split ';' | ForEach-Object -Begin { $i = 1 } -Process { "$i`t$_"; $i++ }
}
