$ErrorActionPreference = "Stop"


Import-Module `
    "$PSScriptRoot\Theme.psm1" `
    -Force


# ============================================================
# UI state
# ============================================================

$script:VolScriptActiveDashboardState = $null
$script:VolScriptStandbyStatusLine = $null
$script:VolScriptStandbySpinnerFrame = 0
$script:VolScriptQuiet = $false
$script:VolScriptMaxLogEntries = 10


function Initialize-VolScriptOutputMode
{
    param(
        [switch]$Quiet
    )

    $script:VolScriptQuiet = [bool]$Quiet
}


function Test-VolScriptQuiet
{
    return $script:VolScriptQuiet
}


function Set-VolScriptCursorPosition
{
    param(
        [int]$Left = 0,

        [Parameter(Mandatory)]
        [int]$Top
    )

    if (-not (Test-VolScriptCursorLineAvailable -Line $Top))
    {
        return $false
    }

    try
    {
        [Console]::SetCursorPosition(
            [Math]::Max(0, $Left),
            $Top)

        return $true
    }
    catch
    {
        return $false
    }
}


function Test-VolScriptCursorLineAvailable
{
    param(
        [Parameter(Mandatory)]
        [int]$Line
    )

    return (
        $Line -ge 0 -and
        $Line -lt [Console]::BufferHeight
    )
}


# ============================================================
# Banner
# ============================================================

function Show-VolScriptBanner
{
    param(
        [string]$Subtitle = "Audio Controller",

        [switch]$Dirty
    )

    if (Test-VolScriptQuiet)
    {
        return
    }

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

function Get-VolScriptDashboardLineWidth
{
    $Width = [Console]::BufferWidth

    if ($Width -lt 1)
    {
        return 80
    }

    return $Width
}


function Write-VolScriptDashboardLine
{
    param(
        [AllowEmptyString()]
        [string]$Text = " ",

        [switch]$Highlight,

        [ConsoleColor]$ForegroundColor
    )

    if ([string]::IsNullOrWhiteSpace($Text))
    {
        $Text = " "
    }

    $Line =
        $Text.PadRight(
            (Get-VolScriptDashboardLineWidth))

    if ($Highlight)
    {
        Write-Host $Line `
            -ForegroundColor (Get-VolScriptThemeColor -Role Highlight) `
            -NoNewline

        return
    }

    if ($PSBoundParameters.ContainsKey("ForegroundColor"))
    {
        Write-Host $Line `
            -ForegroundColor $ForegroundColor `
            -NoNewline

        return
    }

    Write-Host $Line -NoNewline
}


function Update-VolScriptActiveDashboardLayout
{
    param(
        [Parameter(Mandatory)]
        [object]$State
    )

    $AvailableLines =
        [Console]::BufferHeight -
        $State.LogStartLine -
        1

    $State.MaxLogLines =
        [Math]::Min(
            $script:VolScriptMaxLogEntries,
            [Math]::Max(0, $AvailableLines))

    $State.LiveUpdates =
        ($State.MaxLogLines -gt 0) -and
        (Test-VolScriptCursorLineAvailable `
            -Line $State.VolumeLine) -and
        (Test-VolScriptCursorLineAvailable `
            -Line $State.LogStartLine) -and
        ($State.VolumeLine -lt $State.LogStartLine)
}


function Write-VolScriptActiveDashboardLog
{
    param(
        [Parameter(Mandatory)]
        [object]$State
    )

    for ($Index = 0; $Index -lt $State.MaxLogLines; $Index++)
    {
        $Row = $State.LogStartLine + $Index

        if (-not (Set-VolScriptCursorPosition -Top $Row))
        {
            $State.LiveUpdates = $false

            return
        }

        if ($Index -lt $State.LogEntries.Count)
        {
            Write-VolScriptDashboardLine `
                -Text "  $($State.LogEntries[$Index])"
        }
        else
        {
            Write-VolScriptDashboardLine
        }
    }
}


function Update-VolScriptActiveDashboard
{
    if ($null -eq $script:VolScriptActiveDashboardState)
    {
        return
    }

    $State = $script:VolScriptActiveDashboardState

    if (-not $State.LiveUpdates)
    {
        Write-VolScriptActiveDashboard

        return
    }

    if ($State.CurrentVolumePct -ge 0)
    {
        if (Set-VolScriptCursorPosition -Top $State.VolumeLine)
        {
            $Bar =
                Get-VolScriptVolumeBar `
                    -Percent $State.CurrentVolumePct

            Write-VolScriptDashboardLine `
                -Text "  $Bar" `
                -Highlight:$State.VolumeHighlight
        }
        else
        {
            $State.LiveUpdates = $false

            Write-VolScriptActiveDashboard

            return
        }
    }

    Write-VolScriptActiveDashboardLog `
        -State $State
}


function Write-VolScriptActiveDashboard
{
    if ($null -eq $script:VolScriptActiveDashboardState)
    {
        return
    }

    $State = $script:VolScriptActiveDashboardState

    Clear-Host

    Show-VolScriptBanner

    Write-Host "  Target" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  * " `
        -ForegroundColor (Get-VolScriptThemeColor -Role Success) `
        -NoNewline

    Write-Host "$($State.ProcessName).exe"

    Write-Host ""

    Write-Host "  Shortcuts" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-VolScriptShortcutRows `
        -Keys @(
            $State.Volume50Key
            $State.Volume100Key
            $State.ExitKey
        ) `
        -Values @(
            "$($State.Volume50Pct)%"
            "$($State.Volume100Pct)%"
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

    $State.VolumeLine =
        [Console]::CursorTop

    if ($State.CurrentVolumePct -ge 0)
    {
        $Bar =
            Get-VolScriptVolumeBar `
                -Percent $State.CurrentVolumePct

        if ($State.VolumeHighlight)
        {
            Write-Host "  $Bar" `
                -ForegroundColor (Get-VolScriptThemeColor -Role Highlight)
        }
        else
        {
            Write-Host "  $Bar"
        }
    }
    else
    {
        Write-Host "  Unknown" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Muted)
    }

    Write-Host ""

    Write-Host "  Log" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  " `
        -NoNewline

    Write-Host (
        ("-" * 38)
    ) -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    $State.LogStartLine =
        [Console]::CursorTop

    Update-VolScriptActiveDashboardLayout `
        -State $State

    foreach ($Entry in $State.LogEntries)
    {
        Write-Host "  $Entry"
    }
}


function Add-VolScriptLogEntry
{
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    if (Test-VolScriptQuiet)
    {
        return
    }

    $Timestamp =
        Get-Date -Format "HH:mm:ss"

    $Entry = "$Timestamp  $Message"

    if ($null -ne $script:VolScriptActiveDashboardState)
    {
        $script:VolScriptActiveDashboardState.LogEntries +=
            $Entry

        if ($script:VolScriptActiveDashboardState.LogEntries.Count `
            -gt $script:VolScriptMaxLogEntries)
        {
            $script:VolScriptActiveDashboardState.LogEntries =
                $script:VolScriptActiveDashboardState.LogEntries |
                Select-Object -Last $script:VolScriptMaxLogEntries
        }

        Update-VolScriptActiveDashboard

        return
    }

    Write-Host "  $Entry"
}


function Initialize-VolScriptLogSection
{
    if (Test-VolScriptQuiet)
    {
        return
    }

    Write-Host "  Log" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  " `
        -NoNewline

    Write-Host (
        ("-" * 38)
    ) -ForegroundColor (Get-VolScriptThemeColor -Role Label)
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

    if (Test-VolScriptQuiet)
    {
        return
    }

    Clear-Host

    $script:VolScriptActiveDashboardState = $null
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

    if (Test-VolScriptQuiet)
    {
        return
    }

    if ($null -eq $script:VolScriptStandbyStatusLine)
    {
        return
    }

    if (-not (Test-VolScriptCursorLineAvailable `
        -Line $script:VolScriptStandbyStatusLine))
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

    if (-not (Set-VolScriptCursorPosition `
        -Top $script:VolScriptStandbyStatusLine))
    {
        return
    }

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

    if (Test-VolScriptQuiet)
    {
        return
    }

    $script:VolScriptActiveDashboardState =
        [PSCustomObject]@{
            ProcessName      = $ProcessName
            Volume50Key      = $Volume50Key
            Volume100Key     = $Volume100Key
            ExitKey          = $ExitKey
            Volume50Pct      = $Volume50Pct
            Volume100Pct     = $Volume100Pct
            CurrentVolumePct = $CurrentVolumePct
            VolumeHighlight  = $false
            VolumeLine       = $null
            LogStartLine     = $null
            MaxLogLines      = $script:VolScriptMaxLogEntries
            LiveUpdates      = $false
            LogEntries       = @(
                "$(Get-Date -Format 'HH:mm:ss')  Listener started. Hotkeys registered."
            )
        }

    Write-VolScriptActiveDashboard
}


function Update-VolScriptActiveVolume
{
    param(
        [Parameter(Mandatory)]
        [int]$VolumePercent,

        [switch]$Highlight
    )

    if (Test-VolScriptQuiet)
    {
        return
    }

    if ($null -eq $script:VolScriptActiveDashboardState)
    {
        return
    }

    $script:VolScriptActiveDashboardState.CurrentVolumePct =
        $VolumePercent

    $script:VolScriptActiveDashboardState.VolumeHighlight =
        [bool]$Highlight

    Update-VolScriptActiveDashboard

    if ($Highlight)
    {
        $script:VolScriptActiveDashboardState.VolumeHighlight = $false
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

    if (Test-VolScriptQuiet)
    {
        return
    }

    if ($null -ne $script:VolScriptActiveDashboardState)
    {
        $script:VolScriptActiveDashboardState.CurrentVolumePct =
            $Volume

        $script:VolScriptActiveDashboardState.VolumeHighlight = $true

        $Timestamp =
            Get-Date -Format "HH:mm:ss"

        $script:VolScriptActiveDashboardState.LogEntries +=
            "$Timestamp  $Key -> $ProcessName $Volume%"

        if ($script:VolScriptActiveDashboardState.LogEntries.Count `
            -gt $script:VolScriptMaxLogEntries)
        {
            $script:VolScriptActiveDashboardState.LogEntries =
                $script:VolScriptActiveDashboardState.LogEntries |
                Select-Object -Last $script:VolScriptMaxLogEntries
        }

        Update-VolScriptActiveDashboard

        $script:VolScriptActiveDashboardState.VolumeHighlight = $false

        return
    }

    Write-Host ""

    Write-Host "  $Key -> $ProcessName $Volume%" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Highlight)
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

    if (Test-VolScriptQuiet)
    {
        if ([string]::IsNullOrWhiteSpace($Suggestion))
        {
            $Suggestion =
                Get-VolScriptErrorSuggestion `
                    -Message $Message
        }

        Write-Host ""

        Write-Host "  ERROR: $Message" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Error)

        if (-not [string]::IsNullOrWhiteSpace($Suggestion))
        {
            Write-Host "  -> $Suggestion" `
                -ForegroundColor (Get-VolScriptThemeColor -Role Muted)
        }

        Write-Host ""

        if (Get-Command Show-VolScriptTrayBalloon -ErrorAction SilentlyContinue)
        {
            Show-VolScriptTrayBalloon `
                -Message $Message
        }

        return
    }

    if ([string]::IsNullOrWhiteSpace($Suggestion))
    {
        $Suggestion =
            Get-VolScriptErrorSuggestion `
                -Message $Message
    }

    $Timestamp =
        Get-Date -Format "HH:mm:ss"

    Add-VolScriptLogEntry `
        "ERROR $Message"

    if ($null -ne $script:VolScriptActiveDashboardState)
    {
        return
    }

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

    if (Test-VolScriptQuiet)
    {
        return
    }

    Add-VolScriptLogEntry `
        "$ExitKey -> Exiting..."

    if ($null -ne $script:VolScriptActiveDashboardState)
    {
        return
    }

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

    if (Test-VolScriptQuiet)
    {
        return
    }

    Add-VolScriptLogEntry `
        "$ProcessName.exe terminated. Returning to standby..."
}


# ============================================================
# Help
# ============================================================

function Show-VolScriptHelp
{
    Show-VolScriptBanner

    Write-Host "Usage" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  .\VolScript.ps1 <process>"

    Write-Host ""

    Write-Host "Example" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  .\VolScript.ps1 spotify"

    Write-Host ""

    Write-Host "Options" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  -h, --help      Show this help message"

    Write-Host "  -c, --config    Edit shortcuts and volumes"

    Write-Host "                  Use -c <process> for a profile config"

    Write-Host "  -q, --quiet     Tray icon, hidden console, errors only"

    Write-Host ""
    Write-Host "  Profiles are stored in config\config.<process>.json"

    Write-Host ""
    Write-Host "  Config examples:" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  .\VolScript.ps1 -c"

    Write-Host "  .\VolScript.ps1 -c spotify"

    Write-Host "  .\VolScript.ps1 spotify -c"

    Write-Host ""
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
    Show-VolScriptHelp
