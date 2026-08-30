$ErrorActionPreference = "Stop"


Import-Module `
    "$PSScriptRoot\Theme.psm1" `
    -Force


# ============================================================
# UI state
# ============================================================

$script:VolScriptLogEntries = @()
$script:VolScriptLogStartLine = $null
$script:VolScriptStandbyStatusLine = $null
$script:VolScriptActiveVolumeLine = $null
$script:VolScriptStandbySpinnerFrame = 0


# ============================================================
# Banner
# ============================================================

function Show-VolScriptBanner
{
    param(
        [string]$Subtitle = "Audio Controller",

        [switch]$Dirty
    )

    if ($Dirty)
    {
        $Subtitle = "$Subtitle [*]"
    }

    Write-Host ""

    Write-Host "+------------------------------------------+" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Banner)

    Write-Host "|                 VolScript                |" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Banner)

    $PaddedSubtitle =
        $Subtitle.PadLeft(
            [int]((42 + $Subtitle.Length) / 2)
        ).PadRight(42)

    Write-Host "|$PaddedSubtitle|" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Banner)

    Write-Host "+------------------------------------------+" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Banner)

    Write-Host ""
}


# ============================================================
# Volume bar
# ============================================================

function Get-VolScriptVolumeBar
{
    param(
        [Parameter(Mandatory)]
        [int]$Percent,

        [int]$Width = 10
    )

    $Clamped =
        [Math]::Max(
            0,
            [Math]::Min(100, $Percent))

    $Filled =
        [int][Math]::Round(
            ($Clamped / 100.0) * $Width)

    $Empty = $Width - $Filled

    return (
        "[" +
        ("#" * $Filled) +
        ("." * $Empty) +
        "] $Clamped%"
    )
}


# ============================================================
# Shortcut rows
# ============================================================

function Write-VolScriptShortcutRows
{
    param(
        [Parameter(Mandatory)]
        [string[]]$Keys,

        [Parameter(Mandatory)]
        [string[]]$Values
    )

    $MaxKeyLength =
        ($Keys |
            ForEach-Object { $_.Length } |
            Measure-Object -Maximum).Maximum

    for ($Index = 0; $Index -lt $Keys.Count; $Index++)
    {
        $Key = $Keys[$Index]
        $Value = $Values[$Index]

        $Gap =
            2 + ($MaxKeyLength - $Key.Length)

        Write-Host "  $Key" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Accent) `
            -NoNewline

        Write-Host (
            (" " * $Gap) + "= $Value"
        )
    }
}


# ============================================================
# Log
# ============================================================

function Add-VolScriptLogEntry
{
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    if ($null -eq $script:VolScriptLogStartLine)
    {
        Write-Host ""

        Write-Host "  $Message"

        return
    }

    $Timestamp =
        Get-Date -Format "HH:mm:ss"

    $script:VolScriptLogEntries +=
        "$Timestamp  $Message"

    if ($script:VolScriptLogEntries.Count -gt 10)
    {
        $script:VolScriptLogEntries =
            $script:VolScriptLogEntries |
            Select-Object -Last 10
    }

    $Line = $script:VolScriptLogStartLine

    foreach ($Entry in $script:VolScriptLogEntries)
    {
        [Console]::SetCursorPosition(
            0,
            $Line)

        Write-Host (
            "  $Entry".PadRight(
                [Math]::Max(
                    [Console]::WindowWidth,
                    80))
        )

        $Line++
    }

    $ClearTo =
        $script:VolScriptLogStartLine +
        $script:VolScriptLogEntries.Count

    while ($Line -lt ($script:VolScriptLogStartLine + 10))
    {
        [Console]::SetCursorPosition(
            0,
            $Line)

        Write-Host (
            (" " * [Math]::Max(
                [Console]::WindowWidth,
                80))
        )

        $Line++
    }

    [Console]::SetCursorPosition(
        0,
        $ClearTo)
}


function Initialize-VolScriptLogSection
{
    Write-Host "  Log" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  " `
        -NoNewline

    Write-Host (
        ("-" * 38)
    ) -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    $script:VolScriptLogStartLine =
        [Console]::CursorTop
}


# ============================================================
# Standby dashboard
# ============================================================

function Initialize-VolScriptStandbyDashboard
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [string]$Volume50Key,

        [Parameter(Mandatory)]
        [string]$Volume100Key,

        [Parameter(Mandatory)]
        [string]$ExitKey,

        [Parameter(Mandatory)]
        [int]$Volume50Pct,

        [Parameter(Mandatory)]
        [int]$Volume100Pct
    )

    $script:VolScriptLogEntries = @()
    $script:VolScriptLogStartLine = $null
    $script:VolScriptActiveVolumeLine = $null
    $script:VolScriptStandbySpinnerFrame = 0

    Show-VolScriptBanner

    Write-Host "  Target" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  * " `
        -ForegroundColor (Get-VolScriptThemeColor -Role Warning) `
        -NoNewline

    Write-Host "$ProcessName.exe"

    Write-Host ""

    Write-Host "  Shortcuts" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-VolScriptShortcutRows `
        -Keys @(
            $Volume50Key
            $Volume100Key
            $ExitKey
        ) `
        -Values @(
            "$Volume50Pct%"
            "$Volume100Pct%"
            "Exit"
        )

    Write-Host ""

    Write-Host "  Status" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    $script:VolScriptStandbyStatusLine =
        [Console]::CursorTop

    Write-Host "  * " `
        -ForegroundColor (Get-VolScriptThemeColor -Role Warning) `
        -NoNewline

    Write-Host "Waiting for $ProcessName.exe"

    Write-Host ""
}


function Update-VolScriptStandbySpinner
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    if ($null -eq $script:VolScriptStandbyStatusLine)
    {
        return
    }

    $Frames = @(
        '|'
        '/'
        '-'
        '\'
    )

    $Frame =
        $Frames[
            $script:VolScriptStandbySpinnerFrame % 4
        ]

    $script:VolScriptStandbySpinnerFrame++

    [Console]::SetCursorPosition(
        0,
        $script:VolScriptStandbyStatusLine)

    Write-Host "  * " `
        -ForegroundColor (Get-VolScriptThemeColor -Role Warning) `
        -NoNewline

    Write-Host "Waiting for $ProcessName.exe $Frame" `
        -NoNewline

    $Remaining =
        [Math]::Max(
            [Console]::WindowWidth,
            80) - [Console]::CursorLeft

    if ($Remaining -gt 0)
    {
        Write-Host (
            (" " * $Remaining)
        ) -NoNewline
    }
}


# ============================================================
# Active dashboard
# ============================================================

function Initialize-VolScriptActiveDashboard
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [string]$Volume50Key,

        [Parameter(Mandatory)]
        [string]$Volume100Key,

        [Parameter(Mandatory)]
        [string]$ExitKey,

        [Parameter(Mandatory)]
        [int]$Volume50Pct,

        [Parameter(Mandatory)]
        [int]$Volume100Pct,

        [int]$CurrentVolumePct = -1
    )

    $script:VolScriptLogEntries = @()
    $script:VolScriptStandbyStatusLine = $null
    $script:VolScriptStandbySpinnerFrame = 0

    Show-VolScriptBanner

    Write-Host "  Target" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  * " `
        -ForegroundColor (Get-VolScriptThemeColor -Role Success) `
        -NoNewline

    Write-Host "$ProcessName.exe"

    Write-Host ""

    Write-Host "  Shortcuts" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-VolScriptShortcutRows `
        -Keys @(
            $Volume50Key
            $Volume100Key
            $ExitKey
        ) `
        -Values @(
            "$Volume50Pct%"
            "$Volume100Pct%"
            "Exit"
        )

    Write-Host ""

    Write-Host "  Status" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  * " `
        -ForegroundColor (Get-VolScriptThemeColor -Role Success) `
        -NoNewline

    Write-Host "Running"

    Write-Host ""

    Write-Host "  Current volume" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    $script:VolScriptActiveVolumeLine =
        [Console]::CursorTop

    if ($CurrentVolumePct -ge 0)
    {
        Write-Host "  $(
            Get-VolScriptVolumeBar `
                -Percent $CurrentVolumePct
        )"
    }
    else
    {
        Write-Host "  Unknown" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Muted)
    }

    Write-Host ""

    Initialize-VolScriptLogSection

    Add-VolScriptLogEntry `
        "Listener started. Hotkeys registered."
}


function Update-VolScriptActiveVolume
{
    param(
        [Parameter(Mandatory)]
        [int]$VolumePercent,

        [switch]$Highlight
    )

    if ($null -eq $script:VolScriptActiveVolumeLine)
    {
        return
    }

    [Console]::SetCursorPosition(
        0,
        $script:VolScriptActiveVolumeLine)

    $Bar =
        Get-VolScriptVolumeBar `
            -Percent $VolumePercent

    if ($Highlight)
    {
        Write-Host "  $Bar" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Highlight)
    }
    else
    {
        Write-Host "  $Bar"
    }
}


# ============================================================
# Volume change (log + bar)
# ============================================================

function Show-VolumeChange
{
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [int]$Volume
    )

    Update-VolScriptActiveVolume `
        -VolumePercent $Volume `
        -Highlight

    Add-VolScriptLogEntry `
        "$Key -> $ProcessName $Volume%"
}


# ============================================================
# Error
# ============================================================

function Get-VolScriptErrorSuggestion
{
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    if ($Message -match "No audio session")
    {
        return "Is the application producing audio?"
    }

    if ($Message -match "volume")
    {
        return "Check that the volume level is between 0 and 100%."
    }

    return $null
}


function Show-Error
{
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Suggestion
    )

    if ([string]::IsNullOrWhiteSpace($Suggestion))
    {
        $Suggestion =
            Get-VolScriptErrorSuggestion `
                -Message $Message
    }

    $Timestamp =
        Get-Date -Format "HH:mm:ss"

    Add-VolScriptLogEntry `
        "ERROR $Timestamp  $Message"

    Write-Host ""

    Write-Host "  ERROR $Timestamp" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Error)

    Write-Host "  $Message" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Error)

    if (-not [string]::IsNullOrWhiteSpace($Suggestion))
    {
        Write-Host "  -> $Suggestion" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Muted)
    }

    Write-Host ""
}


# ============================================================
# Exit
# ============================================================

function Show-Exit
{
    param(
        [Parameter(Mandatory)]
        [string]$ExitKey
    )

    Add-VolScriptLogEntry `
        "$ExitKey -> Exiting..."

    Write-Host ""

    Write-Host "  $ExitKey" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Accent) `
        -NoNewline

    Write-Host " -> Exiting..." `
        -ForegroundColor (Get-VolScriptThemeColor -Role Warning)

    Write-Host ""
}


# ============================================================
# Process terminated
# ============================================================

function Show-ProcessTerminated
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    Add-VolScriptLogEntry `
        "$ProcessName.exe terminated. Returning to standby..."
}


# ============================================================
# Legacy wrappers (backward compatibility)
# ============================================================

function Show-VolScriptHeader
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [string]$Volume50Key,

        [Parameter(Mandatory)]
        [string]$Volume100Key,

        [Parameter(Mandatory)]
        [string]$ExitKey,

        [int]$Volume50Pct = 15,

        [int]$Volume100Pct = 100,

        [int]$CurrentVolumePct = -1
    )

    Initialize-VolScriptActiveDashboard `
        -ProcessName $ProcessName `
        -Volume50Key $Volume50Key `
        -Volume100Key $Volume100Key `
        -ExitKey $ExitKey `
        -Volume50Pct $Volume50Pct `
        -Volume100Pct $Volume100Pct `
        -CurrentVolumePct $CurrentVolumePct
}


function Show-WaitingForProcess
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [string]$Volume50Key,

        [Parameter(Mandatory)]
        [string]$Volume100Key,

        [Parameter(Mandatory)]
        [string]$ExitKey,

        [int]$Volume50Pct = 15,

        [int]$Volume100Pct = 100
    )

    Initialize-VolScriptStandbyDashboard `
        -ProcessName $ProcessName `
        -Volume50Key $Volume50Key `
        -Volume100Key $Volume100Key `
        -ExitKey $ExitKey `
        -Volume50Pct $Volume50Pct `
        -Volume100Pct $Volume100Pct
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
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
    Show-ProcessTerminated
