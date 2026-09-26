Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Post Install Configuration"

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# WSL2
# -----------------------------------------------------------------------------

Write-Host "[INFO] Configuring WSL2..." -ForegroundColor Yellow

$Features = @(
    "Microsoft-Windows-Subsystem-Linux"
    "VirtualMachinePlatform"
)

$RestartRequired = $false

foreach ($Feature in $Features) {
    try {
        $State = (Get-WindowsOptionalFeature -Online -FeatureName $Feature -ErrorAction Stop).State
    }
    catch {
        Write-Warning "Could not query feature $Feature - $($_.Exception.Message)"
        continue
    }

    if ($State -eq "Enabled") {
        Write-Host "[SKIP] $Feature already enabled"
        continue
    }

    Write-Host "[ENABLE] $Feature"

    try {
        $Result = Enable-WindowsOptionalFeature `
            -Online `
            -FeatureName $Feature `
            -All `
            -NoRestart `
            -ErrorAction Stop
        if ($Result.RestartNeeded) { $RestartRequired = $true }
        $RestartRequired = $true
    }
    catch {
        Write-Warning "Failed to enable $Feature - $($_.Exception.Message)"
    }
}

# Docker Desktop refuses to start unless the WSL *package* is current
# ("WSL must be updated ... wsl.exe --update"). Enabling the Windows features
# alone is not enough. wsl.exe prints UTF-16, so its output is not captured.
function Update-Wsl {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        Write-Warning "wsl.exe is not available yet."
        return $false
    }
    Write-Host "[UPDATE] WSL (wsl --update)"
    & wsl.exe --update --web-download
    if ($LASTEXITCODE -ne 0) { & wsl.exe --update }
    $Ok = ($LASTEXITCODE -eq 0)
    & wsl.exe --set-default-version 2
    return $Ok
}

if (Update-Wsl) {
    Write-Host "[SUCCESS] WSL2 configured" -ForegroundColor Green
}
else {
    Write-Warning "WSL update did not complete."
}

if ($RestartRequired) {
    # Finish the WSL update automatically at next logon, after the reboot.
    try {
        $Cmd = '-NoProfile -WindowStyle Hidden -Command "wsl.exe --update --web-download; if ($LASTEXITCODE -ne 0) { wsl.exe --update }; wsl.exe --set-default-version 2; Unregister-ScheduledTask -TaskName DotsWslUpdate -Confirm:$false"'
        $Action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $Cmd
        $Trigger = New-ScheduledTaskTrigger -AtLogOn
        $Princ   = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest
        Register-ScheduledTask -TaskName "DotsWslUpdate" -Action $Action -Trigger $Trigger -Principal $Princ -Force | Out-Null
        Write-Host "[INFO] Windows features enabled. Reboot needed; WSL will finish updating at next logon." -ForegroundColor Yellow
    }
    catch {
        Write-Warning "Could not schedule post-reboot WSL update - run 'wsl --update' after restarting."
    }
}


# -----------------------------------------------------------------------------
# OneDrive
# -----------------------------------------------------------------------------

Write-Host "[REMOVE] OneDrive" -ForegroundColor Yellow

Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

foreach ($Installer in @(
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
    "$env:SystemRoot\System32\OneDriveSetup.exe"
)) {
    if (Test-Path $Installer) {
        try {
            Start-Process `
                -FilePath $Installer `
                -ArgumentList "/uninstall" `
                -Wait `
                -NoNewWindow `
                -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to run OneDrive uninstaller $Installer - $($_.Exception.Message)"
        }
    }
}

# Remove leftover OneDrive scheduled tasks
Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -match "OneDrive" } |
    ForEach-Object {
        try {
            Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to remove scheduled task $($_.TaskName) - $($_.Exception.Message)"
        }
    }

# Move any files out of the OneDrive folder before it is deleted below
if (Test-Path "$env:USERPROFILE\OneDrive") {
    Write-Host "[INFO] Moving OneDrive files to the user profile"
    robocopy "$env:USERPROFILE\OneDrive" "$env:USERPROFILE" /mov /e /xj /ndl /nfl /njh /njs /nc /ns /np | Out-Null
}

@(
    "$env:USERPROFILE\OneDrive",
    "$env:LOCALAPPDATA\Microsoft\OneDrive",
    "$env:PROGRAMDATA\Microsoft OneDrive",
    "$env:SystemDrive\OneDriveTemp",
    "$env:ALLUSERSPROFILE\Microsoft OneDrive"
) | ForEach-Object {
    if (Test-Path $_) {
        Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$RegistryKeys = @(
    "Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    "Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    "Registry::HKEY_CURRENT_USER\Software\Microsoft\OneDrive"
    "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\OneDrive"
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\OneDrive"
)

foreach ($Key in $RegistryKeys) {
    if (Test-Path $Key) {
        try {
            Remove-Item -Path $Key -Recurse -Force -ErrorAction Stop
            Write-Host "[REMOVE] $Key"
        }
        catch {
            Write-Warning "Failed to remove $Key - $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "[SKIP] $Key not found"
    }
}

# Prevent OneDrive from being reinstalled/relaunched on next login
try {
    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force | Out-Null
    }
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name DisableFileSyncNGSC -PropertyType DWord -Value 1 -Force | Out-Null
}
catch {
    Write-Warning "Failed to set OneDrive policy - $($_.Exception.Message)"
}

if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run") {
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
}

Write-Host "[SUCCESS] OneDrive removed" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Consumer Apps
# -----------------------------------------------------------------------------

Write-Host "[REMOVE] Consumer apps" -ForegroundColor Yellow

# Package-name wildcards to KEEP even if a pattern below matches them.
$KeepApps = @()

$Packages = @(
    "*Xbox*","*Gaming*","*Clipchamp*","*MicrosoftTeams*","*MSTeams*","*Skype*","*Solitaire*",
    "*WindowsMaps*","*GetHelp*","*GetStarted*","*OfficeHub*","*DevHome*",
    "*BingNews*","*WindowsFeedbackHub*","*Microsoft.Todos*","*People*",
    "*MixedReality*","*MicrosoftStickyNotes*","*Microsoft.BingWeather*",
    "*Microsoft.WindowsAlarms*","*Microsoft.WindowsSoundRecorder*",
    "*Microsoft.PowerAutomateDesktop*","*Microsoft.OutlookForWindows*",
    "*MicrosoftCorporationII.MicrosoftFamily*","*Microsoft.549981C3F5F10*",
    "*Microsoft.MicrosoftOfficeHub*","*Microsoft.Windows.Photos*","*Microsoft.WindowsCalculator*",
    "*Microsoft.WindowsNotepad*","*Microsoft.ScreenSketch*","*Microsoft.Paint*","*Microsoft.MSPaint*",
    "*WhatsAppDesktop*","*5319275A.WhatsApp*","*LinkedInforWindows*","*7EE7776C.LinkedIn*",
    "*Microsoft.ZuneVideo*","*Microsoft.WindowsCamera*","*Microsoft.MicrosoftJournal*",
    "*Microsoft.Windows.DevHome*","*MicrosoftWindows.CrossDevice*","*Microsoft.Copilot*",
    "*Microsoft.Windows.Copilot*","*Microsoft.BingSearch*","*Microsoft.Getstarted*",
    "*Microsoft.WidgetsPlatformRuntime*","*MicrosoftWindows.Client.WebExperience*",
    "*Microsoft.StartExperiencesApp*","*MicrosoftCorporationII.QuickAssist*",
    "*Microsoft.MicrosoftEdge.Stable*","*Microsoft.Edge.GameAssist*",
    "*Microsoft.M365Companions*","*Microsoft.ApplicationCompatibilityEnhancements*",
    "*Microsoft.Windows.ParentalControls*","*Microsoft.OneDriveSync*"
)

Remove-AppxPatterns -Patterns $Packages -Keep $KeepApps


# -----------------------------------------------------------------------------
# Copilot - disable AND remove completely
# -----------------------------------------------------------------------------

Write-Host "[REMOVE] Windows Copilot completely" -ForegroundColor Yellow

# 1. System-wide Policy Blocks
try {
    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Force | Out-Null
    }
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name TurnOffWindowsCopilot -PropertyType DWord -Value 1 -Force | Out-Null
}
catch {
    Write-Warning "Failed to disable Windows Copilot policy - $($_.Exception.Message)"
}

# 2. User-specific Policy Blocks
try {
    $PolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    if (-not (Test-Path $PolicyPath)) {
        New-Item -Path $PolicyPath -Force | Out-Null
    }
    New-ItemProperty -Path $PolicyPath -Name TurnOffWindowsCopilot -PropertyType DWord -Value 1 -Force | Out-Null
}
catch {
    Write-Warning "Failed to set user-level Copilot policy - $($_.Exception.Message)"
}

# 3. Uninstall the Copilot app packages (Windows PowerShell 5.1 subprocess)
Remove-AppxPatterns -Patterns @("*Copilot*") -Keep $KeepApps


Write-Host "[SUCCESS] Windows Copilot has been completely removed and disabled" -ForegroundColor Green

# =============================================================================
# WinScript: extra debloat, privacy/telemetry, tweaks
# (OneDrive, Copilot and overlapping consumer-app removal are handled above)
# =============================================================================

$RemoveXbox   = $true
$RemoveStore  = $true
$RemoveEdge   = $true
$SetGoogleDns = $true

Write-Host "[INFO] Applying WinScript tweaks..." -ForegroundColor Yellow

function Set-Reg {
    param([string]$Path, [string]$Name, $Value)
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        $Type = if ($Value -is [int]) { 'DWord' } else { 'String' }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Warning "Failed to set $Path\$Name - $($_.Exception.Message)"
    }
}

# --- Extra AppX removal ---
Write-Host "[REMOVE] Extra AppX packages" -ForegroundColor Yellow

$ExtraPackages = @(
    "*Microsoft.3DBuilder*","*Microsoft.Microsoft3DViewer*","*Microsoft.AppConnector*",
    "*Microsoft.BingFoodAndDrink*","*Microsoft.BingHealthAndFitness*","*BingSearch*",
    "*Microsoft.BingTranslator*","*Microsoft.BingTravel*","*Microsoft.ZuneMusic*",
    "*Microsoft.GroupMe10*","*microsoft.windowscommunicationsapps*","*Microsoft.Office.Lens*",
    "*Microsoft.News*","*Microsoft.MicrosoftSolitaireCollection*","*Microsoft.Wallet*",
    "*Microsoft.Whiteboard*","*Microsoft.MinecraftUWP*","*Microsoft.BingFinance*",
    "*Microsoft.BingSports*","*Microsoft.Office.OneNote*","*Microsoft.OneConnect*",
    "*Microsoft.MSPaint*","*Microsoft.CommsPhone*","*Microsoft.YourPhone*","*Microsoft.Print3D*",
    "*QuickAssist*","*Microsoft.SkypeApp*","*Microsoft.Office.Sway*",
    "*UserExperienceImprovementProgram*","*Microsoft.WindowsPhone*","*ACGMediaPlayer*",
    "*ActiproSoftwareLLC*","*AdobePhotoshopExpress*","*BubbleWitch3Saga*","*CandyCrush*",
    "*DropboxOEM*","*Duolingo-LearnLanguagesforFree*","*EclipseManager*","*Facebook*",
    "*Flipboard*","*HiddenCity*","*Hulu*","*ClearChannelRadioDigital.iHeartRadio*",
    "*LinkedInForWindows*","*McAfee*","*Netflix*","*OneCalendar*","*PandoraMediaInc*",
    "*RandomSaladGamesLLC*","*Royal Revolt*","*ShazamEntertainmentLtd.Shazam*","*Speed Test*",
    "*SpotifyAB.SpotifyMusic*","*Sway*","*Twitter*","*Viber*","*Wunderlist*",
    "*Microsoft.Windows.Ai.Copilot.Provider*","*Microsoft.WindowsAiFoundation*","*Microsoft.Windows.Recall*"
)

if ($RemoveXbox)  { $ExtraPackages += "*Xbox*","*Microsoft.GamingApp*" }
if ($RemoveStore) { $ExtraPackages += "*Microsoft.WindowsStore*" }

Remove-AppxPatterns -Patterns $ExtraPackages -Keep $KeepApps

# --- Optional: Edge ---
if ($RemoveEdge) {
    Write-Host "[REMOVE] Microsoft Edge" -ForegroundColor Yellow
    Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    $EdgeSetup = Resolve-Path "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue | Select-Object -Last 1
    if ($EdgeSetup) {
        $Stub = "$env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe"
        New-Item -Path $Stub -Force -ErrorAction SilentlyContinue | Out-Null
        Start-Process -FilePath $EdgeSetup.Path -ArgumentList '--uninstall --system-level --force-uninstall --delete-profile' -Wait
        Remove-Item "$env:SystemDrive\Users\Public\Desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" "DoNotUpdateToEdgeWithChromium" 1
    }
    else {
        Write-Warning "Edge installer not found (already removed?)"
    }
}

# --- Legacy Windows features ---
Write-Host "[REMOVE] Legacy Windows features" -ForegroundColor Yellow
foreach ($Feature in @("Internet-Explorer-Optional-amd64","FaxServicesClientPackage","WindowsMediaPlayer","Recall")) {
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName $Feature -NoRestart -ErrorAction Stop | Out-Null
        Write-Host "[REMOVE] Feature $Feature"
    }
    catch {
        Write-Host "[SKIP] Feature $Feature not present"
    }
}

# --- Recall / AI scheduled tasks ---
foreach ($TaskPath in @('\Microsoft\Windows\WindowsAI\', '\Microsoft\Windows\Recall\')) {
    try {
        $AiTasks = Get-ScheduledTask -TaskPath $TaskPath -ErrorAction SilentlyContinue
        if ($AiTasks) { $AiTasks | Unregister-ScheduledTask -Confirm:$false -ErrorAction Stop }
    }
    catch {
        Write-Warning "Could not remove tasks under $TaskPath"
    }
}

# --- Registry tweaks: Path, Name, Value (int = DWord, string = String) ---
Write-Host "[CONFIG] Registry policies (privacy, telemetry, UI)" -ForegroundColor Yellow

$W  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows"
$CV = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion"
$Ex = "$CV\Explorer\Advanced"
$CD = "$CV\ContentDeliveryManager"
$WS = "$W\Windows Search"

$RegTweaks = @(
    # Consumer features / Copilot UI / AI
    @("$W\CloudContent", "DisableWindowsConsumerFeatures", 1),
    @("$W\CloudContent", "DisableCloudOptimizedContent", 1),
    @("$W\CloudContent", "DisableSoftLanding", 1),
    @("$W\CloudContent", "DisableWindowsSpotlightFeatures", 1),
    @("$W\CloudContent", "DisableTailoredExperiencesWithDiagnosticData", 1),
    @("HKCU:\Software\Policies\Microsoft\Windows\CloudContent", "DisableTailoredExperiencesWithDiagnosticData", 1),
    @("HKCU:\Software\Policies\Microsoft\Windows\CloudContent", "TailoredExperiencesWithDiagnosticDataEnabled", 0),
    @($Ex, "ShowCopilotButton", 0),
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings", "AutoOpenCopilotLargeScreens", 0),
    @("$CV\WindowsCopilot", "AllowCopilotRuntime", 0),
    @("HKLM:\SOFTWARE\Microsoft\Windows\Shell\Copilot", "CopilotDisabledReason", "IsEnabledForGeographicRegionFailed"),
    @("HKLM:\SOFTWARE\Microsoft\Windows\Shell\Copilot", "IsCopilotAvailable", 0),
    @("HKCU:\Software\Microsoft\Windows\Shell\Copilot\BingChat", "IsUserEligible", 0),
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked", "{CB3B0003-8088-4EDE-8769-8B354AB2FF8C}", " "),
    @("$W\WindowsAI", "DisableAIDataAnalysis", 1),
    @("HKLM:\Software\Policies\WindowsNotepad", "DisableAIFeatures", 1),
    @("HKCU:\Software\Microsoft\Notepad", "ShowRewriteButton", 0),

    # Brave debloat
    @("HKLM:\SOFTWARE\Policies\BraveSoftware\Brave", "BraveRewardsDisabled", 1),
    @("HKLM:\SOFTWARE\Policies\BraveSoftware\Brave", "BraveWalletDisabled", 1),
    @("HKLM:\SOFTWARE\Policies\BraveSoftware\Brave", "BraveAIChatEnabled", 0),
    @("HKLM:\SOFTWARE\Policies\BraveSoftware\Brave", "BraveStatsPingEnabled", 0),

    # Taskbar / widgets
    @($Ex, "ShowTaskViewButton", 0),
    @("HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests", "value", 0),
    @("$W\Windows Feeds", "EnableFeeds", 0),

    # Telemetry
    @("$W\DataCollection", "AllowTelemetry", 0),
    @("$W\DataCollection", "AllowDesktopAnalyticsProcessing", 0),
    @("$W\DataCollection", "AllowDeviceNameInTelemetry", 0),
    @("$W\DataCollection", "MicrosoftEdgeDataOptIn", 0),
    @("$W\DataCollection", "AllowWUfBCloudProcessing", 0),
    @("$W\DataCollection", "AllowUpdateComplianceProcessing", 0),
    @("$W\DataCollection", "AllowCommercialDataPipeline", 0),
    @("$W\DataCollection", "DisableOneSettingsDownloads", 1),
    @("$W\DataCollection", "DoNotShowFeedbackNotifications", 1),
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection", "AllowTelemetry", 0),
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection", "DoNotShowFeedbackNotifications", 1),
    @("HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows", "CEIPEnable", 0),
    @("HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform", "NoGenTicket", 1),
    @("$W\Windows Error Reporting", "Disabled", 1),
    @("HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting", "Disabled", 1),
    @("HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Consent", "DefaultConsent", 0),
    @("HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Consent", "DefaultOverrideBehavior", 1),
    @("HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting", "DontSendAdditionalData", 1),
    @("HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting", "LoggingDisabled", 1),
    @("$W\System", "PublishUserActivities", 0),
    @("$W\System", "UploadUserActivities", 0),
    @($Ex, "Start_TrackProgs", 0),
    @("HKCU:\SOFTWARE\Microsoft\Personalization\Settings", "AcceptedPrivacyPolicy", 0),
    @("HKCU:\Software\Policies\Microsoft\Windows\EdgeUI", "DisableMFUTracking", 1),
    @("HKCU:\Control Panel\International\User Profile", "HttpAcceptLanguageOptOut", 1),
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications", "EnableAccountNotifications", 0),
    @("$CV\SystemSettings\AccountNotifications", "EnableAccountNotifications", 0),

    # Content delivery / suggestions
    @($CD, "ContentDeliveryAllowed", 0),
    @($CD, "SubscribedContentEnabled", 0),
    @($CD, "OemPreInstalledAppsEnabled", 0),
    @($CD, "PreInstalledAppsEnabled", 0),
    @($CD, "PreInstalledAppsEverEnabled", 0),
    @($CD, "SilentInstalledAppsEnabled", 0),
    @($CD, "SystemPaneSuggestionsEnabled", 0),
    @($CD, "FeatureManagementEnabled", 0),
    @($CD, "SubscribedContent-338393Enabled", 0),
    @($CD, "SubscribedContent-353694Enabled", 0),
    @($CD, "SubscribedContent-353696Enabled", 0),
    @($CD, "SubscribedContent-338387Enabled", 0),
    @($CD, "SubscribedContent-338388Enabled", 0),
    @($CD, "SubscribedContent-338389Enabled", 0),
    @($CD, "SubscribedContent-353698Enabled", 0),

    # Update / delivery optimization
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching", "SearchOrderConfig", 0),
    @("$W\DeliveryOptimization", "DODownloadMode", 99),

    # Search
    @($WS, "ConnectedSearchPrivacy", 3),
    @($WS, "AllowSearchToUseLocation", 0),
    @($WS, "EnableDynamicContentInWSB", 0),
    @($WS, "ConnectedSearchUseWeb", 0),
    @($WS, "DisableWebSearch", 1),
    @($WS, "PreventUnwantedAddIns", " "),
    @($WS, "PreventRemoteQueries", 1),
    @($WS, "AlwaysUseAutoLangDetection", 0),
    @($WS, "AllowIndexingEncryptedStoresOrItems", 0),
    @($WS, "ConnectedSearchUseWebOverMeteredConnections", 0),
    @($WS, "AllowCloudSearch", 0),
    @($WS, "AllowCortana", 0),
    @("$W\Explorer", "DisableSearchBoxSuggestions", 1),
    @("$W\Explorer", "DisableSearchHistory", 1),
    @($Ex, "Start_IrisRecommendations", 0),
    @("$CV\SearchSettings", "IsDynamicSearchBoxEnabled", 0),
    @("$CV\SearchSettings", "IsMSACloudSearchEnabled", 0),
    @("$CV\SearchSettings", "IsAADCloudSearchEnabled", 0),
    @("$CV\SearchSettings", "IsDeviceSearchHistoryEnabled", 0),
    @("$CV\Search", "BingSearchEnabled", 0),
    @("$CV\Search", "VoiceShortcut", 0),
    @("$CV\Search", "DeviceHistoryEnabled", 0),
    @("$CV\Search", "HistoryViewEnabled", 0),
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search", "CortanaEnabled", 0),

    # Feedback / handwriting / speech / DRM / ads
    @("HKCU:\SOFTWARE\Microsoft\Siuf\Rules", "NumberOfSIUFInPeriod", 0),
    @("HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization", "RestrictImplicitInkCollection", 1),
    @("HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization", "RestrictImplicitTextCollection", 1),
    @("HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization", "AllowInputPersonalization", 0),
    @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports", "PreventHandwritingErrorReports", 1),
    @("$W\TabletPC", "PreventHandwritingDataSharing", 1),
    @("HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore", "HarvestContacts", 0),
    @("HKLM:\SOFTWARE\Policies\Microsoft\WMDRM", "DisableOnline", 1),
    @("HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy", "HasAccepted", 0),
    @("$CV\AdvertisingInfo", "Enabled", 0),
    @("$W\AdvertisingInfo", "DisabledByGroupPolicy", 1),
    @("HKCU:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo", "DisabledByGroupPolicy", 1),

    # Office telemetry
    @("HKCU:\SOFTWARE\Microsoft\Office\Common\ClientTelemetry", "DisableTelemetry", 1),
    @("HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry", "DisableTelemetry", 1),
    @("HKCU:\SOFTWARE\Microsoft\Office\Common\ClientTelemetry", "VerboseLogging", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry", "VerboseLogging", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\15.0\Common", "QMEnable", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\16.0\Common", "QMEnable", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\15.0\Common\Feedback", "Enabled", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Feedback", "Enabled", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Mail", "EnableLogging", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Mail", "EnableLogging", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Calendar", "EnableCalendarLogging", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Calendar", "EnableCalendarLogging", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\15.0\Word\Options", "EnableLogging", 0),
    @("HKCU:\SOFTWARE\Microsoft\Office\16.0\Word\Options", "EnableLogging", 0),
    @("HKCU:\SOFTWARE\Policies\Microsoft\Office\15.0\OSM", "EnableLogging", 0),
    @("HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\OSM", "EnableLogging", 0),
    @("HKCU:\SOFTWARE\Policies\Microsoft\Office\15.0\OSM", "EnableUpload", 0),
    @("HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\OSM", "EnableUpload", 0),

    # NVIDIA / Visual Studio / Media Player / CCleaner telemetry
    @("HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client", "OptInOrOutPreference", 0),
    @("HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS", "EnableRID44231", 0),
    @("HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS", "EnableRID64640", 0),
    @("HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS", "EnableRID66610", 0),
    @("HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup", "SendTelemetryData", 0),
    @("HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\14.0\SQM", "OptIn", 0),
    @("HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\15.0\SQM", "OptIn", 0),
    @("HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\16.0\SQM", "OptIn", 0),
    @("HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\17.0\SQM", "OptIn", 0),
    @("HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\SQM", "OptIn", 0),
    @("HKCU:\SOFTWARE\Microsoft\VisualStudio\Telemetry", "TurnOffSwitch", 1),
    @("HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback", "DisableFeedbackDialog", 1),
    @("HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback", "DisableEmailInput", 1),
    @("HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback", "DisableScreenshotCapture", 1),
    @("HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\IntelliCode", "DisableRemoteAnalysis", 1),
    @("HKCU:\SOFTWARE\Microsoft\VSCommon\16.0\IntelliCode", "DisableRemoteAnalysis", 1),
    @("HKCU:\SOFTWARE\Microsoft\VSCommon\17.0\IntelliCode", "DisableRemoteAnalysis", 1),
    @("HKCU:\SOFTWARE\Microsoft\MediaPlayer\Preferences", "UsageTracking", 0),
    @("HKCU:\Software\Policies\Microsoft\WindowsMediaPlayer", "PreventCDDVDMetadataRetrieval", 1),
    @("HKCU:\Software\Policies\Microsoft\WindowsMediaPlayer", "PreventMusicFileMetadataRetrieval", 1),
    @("HKCU:\Software\Policies\Microsoft\WindowsMediaPlayer", "PreventRadioPresetsRetrieval", 1),
    @("HKCU:\Software\Piriform\CCleaner", "Monitoring", 0),
    @("HKCU:\Software\Piriform\CCleaner", "HelpImproveCCleaner", 0),
    @("HKCU:\Software\Piriform\CCleaner", "SystemMonitoring", 0),
    @("HKCU:\Software\Piriform\CCleaner", "UpdateAuto", 0),
    @("HKCU:\Software\Piriform\CCleaner", "UpdateCheck", 0),
    @("HKCU:\Software\Piriform\CCleaner", "CheckTrialOffer", 0),

    # Game DVR / Game Bar
    @("HKCU:\System\GameConfigStore", "GameDVR_Enabled", 0),
    @("$W\GameDVR", "AllowGameDVR", 0),
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR", "AppCaptureEnabled", 0),
    @("HKCU:\SOFTWARE\Microsoft\GameBar", "UseNexusForGameBarEnabled", 0),
    @("HKCU:\SOFTWARE\Microsoft\GameBar", "ShowStartupPanel", 0),

    # Mouse acceleration off
    @("HKCU:\Control Panel\Mouse", "MouseSpeed", "0"),
    @("HKCU:\Control Panel\Mouse", "MouseThreshold1", "0"),
    @("HKCU:\Control Panel\Mouse", "MouseThreshold2", "0"),

    # IPv4 preferred over IPv6
    @("HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters", "DisabledComponents", 32),

    # Explorer: no Home/Gallery, open to This PC, dark mode, extensions, hidden files
    @("HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}", "System.IsPinnedToNameSpaceTree", 0),
    @("HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}", "System.IsPinnedToNameSpaceTree", 0),
    @($Ex, "LaunchTo", 1),
    @($Ex, "HideFileExt", 0),
    @($Ex, "Hidden", 1),
    @("$CV\Themes\Personalize", "AppsUseLightTheme", 0),
    @("$CV\Themes\Personalize", "SystemUsesLightTheme", 0)
)

foreach ($Tweak in $RegTweaks) {
    Set-Reg -Path $Tweak[0] -Name $Tweak[1] -Value $Tweak[2]
}

# --- Scheduled tasks: telemetry ---
Write-Host "[CONFIG] Disabling telemetry scheduled tasks" -ForegroundColor Yellow

$TelemetryTasks = @(
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Feedback\Siuf\DmClient",
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "\Microsoft\Windows\Maps\MapsUpdateTask",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp",
    "\Microsoft\Windows\Application Experience\StartupAppTask",
    "\Microsoft\Windows\Application Experience\PcaPatchDbTask",
    "\Microsoft\Windows\Application Experience\MareBackup",
    "\Microsoft\Office\OfficeTelemetryAgentFallBack",
    "\Microsoft\Office\OfficeTelemetryAgentLogOn",
    "\Microsoft\Office\OfficeTelemetryAgentFallBack2016",
    "\Microsoft\Office\OfficeTelemetryAgentLogOn2016",
    "\Microsoft\Office\Office 15 Subscription Heartbeat",
    "\Microsoft\Office\Office 16 Subscription Heartbeat",
    "\Adobe Acrobat Update Task"
)

foreach ($TaskFull in $TelemetryTasks) {
    try {
        Disable-ScheduledTask -TaskName $TaskFull -ErrorAction Stop | Out-Null
    }
    catch {
        # Task not present on this machine
    }
}

foreach ($Task in @("NvTmMon_*","NvTmRep_*","NvTmRepOnLogon_*")) {
    Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue |
        Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
}

# --- Services ---
Write-Host "[CONFIG] Adjusting services" -ForegroundColor Yellow

$ManualServices   = @("DiagTrack","diagsvc","WerSvc","wercplsupport")
$DisabledServices = @("NvTelemetryContainer","gupdate","gupdatem","AdobeARMservice","adobeupdateservice")

foreach ($Svc in $ManualServices) {
    if (Get-Service -Name $Svc -ErrorAction SilentlyContinue) {
        Set-Service -Name $Svc -StartupType Manual -ErrorAction SilentlyContinue
    }
}
foreach ($Svc in $DisabledServices) {
    if (Get-Service -Name $Svc -ErrorAction SilentlyContinue) {
        Set-Service -Name $Svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# --- PowerShell telemetry opt-out ---
[Environment]::SetEnvironmentVariable("POWERSHELL_TELEMETRY_OPTOUT", "1", "Machine")

# --- DNS (all connected physical adapters, not a hardcoded "Ethernet") ---
if ($SetGoogleDns) {
    Write-Host "[CONFIG] Setting Google DNS on connected adapters" -ForegroundColor Yellow
    Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
        Where-Object Status -eq 'Up' |
        ForEach-Object {
            $AdapterName  = $_.Name
            $AdapterIndex = $_.ifIndex
            try {
                Set-DnsClientServerAddress -InterfaceIndex $AdapterIndex -ServerAddresses ("8.8.8.8","8.8.4.4") -ErrorAction Stop
                Write-Host "[CONFIG] DNS set on $AdapterName"
            }
            catch {
                Write-Warning "Failed to set DNS on $AdapterName - $($_.Exception.Message)"
            }
        }
}

# --- Ultimate Performance power plan ---
Write-Host "[CONFIG] Ultimate Performance power plan" -ForegroundColor Yellow
$UltimateGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
try {
    if (-not ((powercfg -list) -match $UltimateGuid)) {
        powercfg -duplicatescheme $UltimateGuid | Out-Null
    }
    powercfg -setactive $UltimateGuid | Out-Null
}
catch {
    Write-Warning "Failed to enable Ultimate Performance plan - $($_.Exception.Message)"
}

# --- Clean Start menu: no pinned stubs (WhatsApp/LinkedIn...), no Recent/recommended ---
Write-Host "[CONFIG] Clean Start menu" -ForegroundColor Yellow
foreach ($R in @(
    @($Ex, "Start_TrackDocs", 0),
    @($Ex, "Start_TrackProgs", 0),
    @($Ex, "Start_IrisRecommendations", 0),
    @($Ex, "Start_AccountNotifications", 0),
    @("$W\Explorer", "HideRecentlyAddedApps", 1),
    @("$W\Explorer", "ShowOrHideMostUsedApps", 2),
    @("HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start", "HideRecentlyAddedApps", 1),
    @("HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start", "HideRecommendedSection", 1)
)) { Set-Reg $R[0] $R[1] $R[2] }

# WhatsApp/LinkedIn etc. are Store *stubs* pinned by Start's cached layout,
# not installed packages, so removing Appx packages never touches them.
# Deleting the pin cache resets Start to an empty pinned list.
Stop-Process -Name StartMenuExperienceHost -Force -ErrorAction SilentlyContinue
foreach ($F in @('start.bin', 'start2.bin')) {
    Remove-Item "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\$F" -Force -ErrorAction SilentlyContinue
}

# --- Restart Explorer to apply UI changes (no pause/exit: this is a module) ---
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

Write-Host "[SUCCESS] WinScript tweaks applied" -ForegroundColor Green
