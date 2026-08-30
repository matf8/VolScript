$ErrorActionPreference = "Stop"


Import-Module `
    "$PSScriptRoot\UICore.psm1" `
    -Force


# ============================================================
# Tray state
# ============================================================

$script:VolScriptTrayIcon = $null

$global:VolScriptTrayExitRequested = $false


# ============================================================
# Tray icon
# ============================================================

function Get-VolScriptTrayIcon
{
    $ProjectRoot =
        (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

    $IconPath =
        Join-Path $ProjectRoot "assets\VolScript.ico"

    if (Test-Path $IconPath)
    {
        return New-Object System.Drawing.Icon($IconPath)
    }

    $FallbackPath =
        Join-Path $env:SystemRoot "System32\SndVol.exe"

    return [System.Drawing.Icon]::ExtractAssociatedIcon($FallbackPath)
}


# ============================================================
# Tray
# ============================================================

function Start-VolScriptTray
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [string]$ExitKey,

        [switch]$HideConsole
    )

    Add-Type `
        -AssemblyName System.Windows.Forms `
        -ErrorAction Stop

    Add-Type `
        -AssemblyName System.Drawing `
        -ErrorAction Stop

    $global:VolScriptTrayExitRequested = $false

    $TrayIcon =
        New-Object System.Windows.Forms.NotifyIcon

    $TrayIcon.Icon = Get-VolScriptTrayIcon

    $TrayIcon.Visible = $true
    $TrayIcon.Text =
        Get-VolScriptTrayTooltip `
            -ProcessName $ProcessName `
            -Status "waiting"

    $Menu =
        New-Object System.Windows.Forms.ContextMenuStrip

    $ShowConsoleItem =
        $Menu.Items.Add("Show console")

    $ShowConsoleItem.Add_Click({
        [VolScript.UI.ConsoleWindow]::Show()
    })

    $ExitItem =
        $Menu.Items.Add("Exit")

    $ExitItem.Add_Click({
        $global:VolScriptTrayExitRequested = $true
    })

    $TrayIcon.ContextMenuStrip = $Menu

    $TrayIcon.Add_DoubleClick({
        [VolScript.UI.ConsoleWindow]::Show()
    })

    $script:VolScriptTrayIcon = $TrayIcon

    if ($HideConsole)
    {
        [VolScript.UI.ConsoleWindow]::Hide()
    }

    Invoke-VolScriptTrayPump
}


function Stop-VolScriptTray
{
    if ($null -eq $script:VolScriptTrayIcon)
    {
        return
    }

    $script:VolScriptTrayIcon.Visible = $false
    $script:VolScriptTrayIcon.Dispose()
    $script:VolScriptTrayIcon = $null
    $global:VolScriptTrayExitRequested = $false

    Invoke-VolScriptTrayPump
}


function Test-VolScriptTrayActive
{
    return (
        $null -ne $script:VolScriptTrayIcon -and
        $script:VolScriptTrayIcon.Visible
    )
}


function Test-VolScriptTrayExitRequested
{
    return [bool]$global:VolScriptTrayExitRequested
}


function Get-VolScriptTrayTooltip
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [ValidateSet("waiting", "active")]
        [string]$Status,

        [int]$VolumePercent = -1
    )

    $Text =
        switch ($Status)
        {
            "waiting"
            {
                "VolScript: waiting for $ProcessName"
            }

            "active"
            {
                if ($VolumePercent -ge 0)
                {
                    "VolScript: $ProcessName @ ${VolumePercent}%"
                }
                else
                {
                    "VolScript: $ProcessName (active)"
                }
            }
        }

    if ($Text.Length -gt 63)
    {
        return $Text.Substring(0, 63)
    }

    return $Text
}


function Update-VolScriptTray
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [ValidateSet("waiting", "active")]
        [string]$Status,

        [int]$VolumePercent = -1
    )

    if (-not (Test-VolScriptTrayActive))
    {
        return
    }

    $script:VolScriptTrayIcon.Text =
        Get-VolScriptTrayTooltip `
            -ProcessName $ProcessName `
            -Status $Status `
            -VolumePercent $VolumePercent
}


function Show-VolScriptTrayBalloon
{
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Title = "VolScript"
    )

    if (-not (Test-VolScriptTrayActive))
    {
        return
    }

    $script:VolScriptTrayIcon.BalloonTipTitle = $Title
    $script:VolScriptTrayIcon.BalloonTipText = $Message

    $script:VolScriptTrayIcon.BalloonTipIcon =
        [System.Windows.Forms.ToolTipIcon]::Warning

    $script:VolScriptTrayIcon.ShowBalloonTip(4000)

    Invoke-VolScriptTrayPump
}


function Invoke-VolScriptTrayPump
{
    if (-not (Test-VolScriptTrayActive))
    {
        return
    }

    [System.Windows.Forms.Application]::DoEvents()
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    Start-VolScriptTray, `
    Stop-VolScriptTray, `
    Test-VolScriptTrayActive, `
    Test-VolScriptTrayExitRequested, `
    Update-VolScriptTray, `
    Show-VolScriptTrayBalloon, `
    Invoke-VolScriptTrayPump
