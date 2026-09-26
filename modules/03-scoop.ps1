Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Scoop"

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  Write-Host "[INFO] Installing Scoop..."
  iex "& {$(irm get.scoop.sh)} -RunAsAdmin"

} 

Update-SessionPath

Write-Host "Updating Scoop: $(scoop update)"
$Buckets = @(
  'main'
  'sysinternals'  
  'extras'
  'versions'
  'nerd-fonts'
)

# `scoop bucket list` emits objects, not text. Piping them through
# Select-String matched against "@{Name=main; ...}" so "^main\s" never
# matched and every run tried (and noisily failed) to re-add every bucket.
$ExistingBuckets = @(
  scoop bucket list | ForEach-Object {
    if ($_.PSObject.Properties['Name']) { $_.Name }
  }
)

foreach ($Bucket in $Buckets) {
  if ($Bucket -notin $ExistingBuckets) {
    Write-Host "[INFO] Adding Buckets: $Bucket"
    scoop bucket add $Bucket
  }
}

Write-Host "[SUCCESS] Scoop configured" -ForegroundColor Green
