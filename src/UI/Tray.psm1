$ErrorActionPreference = "Stop"


Import-Module `
    "$PSScriptRoot\UICore.psm1"


# ============================================================
# Tray state
# ============================================================

$script:VolScriptTrayIcon = $null
$script:VolScriptTrayBaseIcon = $null
$script:VolScriptTrayCompositeIcon = $null
$script:VolScriptTrayBadgeProcessName = $null

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


function Clear-VolScriptTrayCompositeIcon
{
    if ($null -eq $script:VolScriptTrayCompositeIcon)
    {
        return
    }

    if (
        $null -ne $script:VolScriptTrayIcon -and
        [object]::ReferenceEquals(
            $script:VolScriptTrayIcon.Icon,
            $script:VolScriptTrayCompositeIcon
        )
    )
    {
        $script:VolScriptTrayIcon.Icon =
            $script:VolScriptTrayBaseIcon
    }

    $script:VolScriptTrayCompositeIcon.Dispose()
    $script:VolScriptTrayCompositeIcon = $null
}


function Reset-VolScriptTrayIconState
{
    Clear-VolScriptTrayCompositeIcon

    $script:VolScriptTrayBadgeProcessName = $null

    if ($null -ne $script:VolScriptTrayBaseIcon)
    {
        $script:VolScriptTrayBaseIcon.Dispose()
        $script:VolScriptTrayBaseIcon = $null
    }
}


function New-VolScriptBadgedTrayIcon
{
    param(
        [Parameter(Mandatory)]
        [System.Drawing.Icon]$BaseIcon,

        [Parameter(Mandatory)]
        [string]$ImagePath
    )

    $Size = 32
    $BadgeSize = 16

    $Canvas =
        New-Object System.Drawing.Bitmap(
            $Size,
            $Size,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )

    $Graphics =
        [System.Drawing.Graphics]::FromImage($Canvas)

    $ProcessIcon = $null
    $BaseBitmap = $null
    $ProcessBitmap = $null
    $BorderBrush = $null
    $OwnedIcon = $null
    $IconHandle = [IntPtr]::Zero

    try
    {
        $Graphics.Clear([System.Drawing.Color]::Transparent)
        $Graphics.InterpolationMode =
            [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $Graphics.SmoothingMode =
            [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $Graphics.PixelOffsetMode =
            [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $Graphics.CompositingQuality =
            [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

        $BaseBitmap = $BaseIcon.ToBitmap()
        $Graphics.DrawImage($BaseBitmap, 0, 0, $Size, $Size)

        $ProcessIcon =
            [System.Drawing.Icon]::ExtractAssociatedIcon($ImagePath)

        if ($null -eq $ProcessIcon)
        {
            return $null
        }

        $ProcessBitmap = $ProcessIcon.ToBitmap()

        $BadgeX = $Size - $BadgeSize - 1
        $BadgeY = $Size - $BadgeSize - 1

        $BorderBrush =
            New-Object System.Drawing.SolidBrush(
                [System.Drawing.Color]::FromArgb(180, 0, 0, 0)
            )

        $Graphics.FillRectangle(
            $BorderBrush,
            ($BadgeX - 1),
            ($BadgeY - 1),
            ($BadgeSize + 2),
            ($BadgeSize + 2)
        )

        $Graphics.DrawImage(
            $ProcessBitmap,
            $BadgeX,
            $BadgeY,
            $BadgeSize,
            $BadgeSize
        )

        $IconHandle = $Canvas.GetHicon()
        $OwnedIcon = [System.Drawing.Icon]::FromHandle($IconHandle)

        return [System.Drawing.Icon]$OwnedIcon.Clone()
    }
    finally
    {
        if ($null -ne $OwnedIcon)
        {
            $OwnedIcon.Dispose()
        }

        if ($IconHandle -ne [IntPtr]::Zero)
        {
            [VolScript.UI.NativeIcons]::DestroyIcon($IconHandle)
        }

        if ($null -ne $BorderBrush)
        {
            $BorderBrush.Dispose()
        }

        if ($null -ne $ProcessBitmap)
        {
            $ProcessBitmap.Dispose()
        }

        if ($null -ne $ProcessIcon)
        {
            $ProcessIcon.Dispose()
        }

        if ($null -ne $BaseBitmap)
        {
            $BaseBitmap.Dispose()
        }

        $Graphics.Dispose()
        $Canvas.Dispose()
    }
}


function Update-VolScriptTrayBadge
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [string]$ImagePath
    )

    if (
        $null -ne $script:VolScriptTrayBadgeProcessName -and
        $script:VolScriptTrayBadgeProcessName -ne $ProcessName
    )
    {
        Clear-VolScriptTrayCompositeIcon
        $script:VolScriptTrayBadgeProcessName = $null
    }

    if (
        $script:VolScriptTrayBadgeProcessName -eq $ProcessName -and
        $null -ne $script:VolScriptTrayCompositeIcon
    )
    {
        return
    }

    if (
        [string]::IsNullOrWhiteSpace($ImagePath) -or
        -not (Test-Path -LiteralPath $ImagePath)
    )
    {
        return
    }

    $Badged = $null

    try
    {
        $Badged =
            New-VolScriptBadgedTrayIcon `
                -BaseIcon $script:VolScriptTrayBaseIcon `
                -ImagePath $ImagePath
    }
    catch
    {
        return
    }

    if ($null -eq $Badged)
    {
        return
    }

    $PreviousComposite = $script:VolScriptTrayCompositeIcon
    $script:VolScriptTrayIcon.Icon = $Badged
    $script:VolScriptTrayCompositeIcon = $Badged
    $script:VolScriptTrayBadgeProcessName = $ProcessName

    if ($null -ne $PreviousComposite)
    {
        $PreviousComposite.Dispose()
    }
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

    Reset-VolScriptTrayIconState

    $script:VolScriptTrayBaseIcon = Get-VolScriptTrayIcon

    $TrayIcon =
        New-Object System.Windows.Forms.NotifyIcon

    $TrayIcon.Icon = $script:VolScriptTrayBaseIcon

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
        Reset-VolScriptTrayIconState
        return
    }

    $script:VolScriptTrayIcon.Visible = $false
    $script:VolScriptTrayIcon.Icon = $null
    $script:VolScriptTrayIcon.Dispose()
    $script:VolScriptTrayIcon = $null
    $global:VolScriptTrayExitRequested = $false

    Reset-VolScriptTrayIconState

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

        [int]$VolumePercent = -1,

        [string]$ImagePath
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

    Update-VolScriptTrayBadge `
        -ProcessName $ProcessName `
        -ImagePath $ImagePath
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
