$ErrorActionPreference = "Stop"


Import-Module `
    "$PSScriptRoot\Theme.psm1"

Import-Module `
    "$PSScriptRoot\Display.psm1"

Import-Module `
    "$PSScriptRoot\Tray.psm1"


Export-ModuleMember -Function `
    Get-VolScriptThemeColor, `
    Get-VolScriptThemeName, `
    Initialize-VolScriptTheme, `
    Test-VolScriptLightBackground, `
    Initialize-VolScriptOutputMode, `
    Test-VolScriptQuiet, `
    Show-VolScriptBanner, `
    Show-VolScriptHeader, `
    Show-WaitingForProcess, `
    Initialize-VolScriptStandbyDashboard, `
    Update-VolScriptStandbySpinner, `
    Initialize-VolScriptActiveDashboard, `
    Update-VolScriptActiveVolume, `
    Add-VolScriptLogEntry, `
    Show-VolumeChange, `
    Show-Error, `
    Show-Exit, `
    Show-ProcessTerminated, `
    Start-VolScriptTray, `
    Stop-VolScriptTray, `
    Test-VolScriptTrayActive, `
    Test-VolScriptTrayExitRequested, `
    Update-VolScriptTray, `
    Show-VolScriptTrayBalloon, `
    Invoke-VolScriptTrayPump, `
    Show-VolScriptHelp
