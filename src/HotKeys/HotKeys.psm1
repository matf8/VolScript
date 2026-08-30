$ErrorActionPreference = "Stop"


# ============================================================
# Load Hotkeys Core
# ============================================================

if (-not ("VolScript.VolScriptHotKeys" -as [type]))
{
    $CorePath =
        Join-Path `
            $PSScriptRoot `
            "Core"

    $SourceFiles = @(
        "HotKeys.cs",
        "HotkeyCapture.cs"
    )

    $Source = @()
    $IsFirstFile = $true

    foreach ($File in $SourceFiles)
    {
        $Content =
            Get-Content `
                (Join-Path $CorePath $File) `
                -Raw

        if (-not $IsFirstFile)
        {
            $Content =
                [regex]::Replace(
                    $Content,
                    '(?m)^using .*;\r?\n',
                    '')
        }

        $Source += $Content
        $Source += ""

        $IsFirstFile = $false
    }

    Add-Type `
        -TypeDefinition ($Source -join "`n")
}


# ============================================================
# Convert hotkey
# ============================================================

function ConvertTo-VolScriptHotkey
{
    param(
        [Parameter(Mandatory)]
        [string]$Hotkey
    )

    $Parts =
        $Hotkey.ToUpper().Split(
            "+",
            [System.StringSplitOptions]::RemoveEmptyEntries
        )

    $Modifier = 0
    $Key = $null

    foreach ($Part in $Parts)
    {
        switch ($Part)
        {
            # ------------------------------------------------
            # Modifiers
            # ------------------------------------------------

            "CTRL"
            {
                $Modifier = $Modifier -bor 2
                continue
            }

            "CONTROL"
            {
                $Modifier = $Modifier -bor 2
                continue
            }

            "ALT"
            {
                $Modifier = $Modifier -bor 4
                continue
            }

            "SHIFT"
            {
                $Modifier = $Modifier -bor 1
                continue
            }


            # ------------------------------------------------
            # Special keys
            # ------------------------------------------------

            "ESC"
            {
                $Key = 0x1B
                continue
            }


            # ------------------------------------------------
            # Function keys
            # ------------------------------------------------

            "F1"  { $Key = 0x70; continue }
            "F2"  { $Key = 0x71; continue }
            "F3"  { $Key = 0x72; continue }
            "F4"  { $Key = 0x73; continue }
            "F5"  { $Key = 0x74; continue }
            "F6"  { $Key = 0x75; continue }
            "F7"  { $Key = 0x76; continue }
            "F8"  { $Key = 0x77; continue }
            "F9"  { $Key = 0x78; continue }
            "F10" { $Key = 0x79; continue }
            "F11" { $Key = 0x7A; continue }
            "F12" { $Key = 0x7B; continue }


            # ------------------------------------------------
            # Letters
            # ------------------------------------------------

            "A" { $Key = 0x41; continue }
            "B" { $Key = 0x42; continue }
            "C" { $Key = 0x43; continue }
            "D" { $Key = 0x44; continue }
            "E" { $Key = 0x45; continue }
            "F" { $Key = 0x46; continue }
            "G" { $Key = 0x47; continue }
            "H" { $Key = 0x48; continue }
            "I" { $Key = 0x49; continue }
            "J" { $Key = 0x4A; continue }
            "K" { $Key = 0x4B; continue }
            "L" { $Key = 0x4C; continue }
            "M" { $Key = 0x4D; continue }
            "N" { $Key = 0x4E; continue }
            "O" { $Key = 0x4F; continue }
            "P" { $Key = 0x50; continue }
            "Q" { $Key = 0x51; continue }
            "R" { $Key = 0x52; continue }
            "S" { $Key = 0x53; continue }
            "T" { $Key = 0x54; continue }
            "U" { $Key = 0x55; continue }
            "V" { $Key = 0x56; continue }
            "W" { $Key = 0x57; continue }
            "X" { $Key = 0x58; continue }
            "Y" { $Key = 0x59; continue }
            "Z" { $Key = 0x5A; continue }


            # ------------------------------------------------
            # Numbers
            # ------------------------------------------------

            "0" { $Key = 0x30; continue }
            "1" { $Key = 0x31; continue }
            "2" { $Key = 0x32; continue }
            "3" { $Key = 0x33; continue }
            "4" { $Key = 0x34; continue }
            "5" { $Key = 0x35; continue }
            "6" { $Key = 0x36; continue }
            "7" { $Key = 0x37; continue }
            "8" { $Key = 0x38; continue }
            "9" { $Key = 0x39; continue }


            # ------------------------------------------------
            # Invalid
            # ------------------------------------------------

            default
            {
                throw "Unsupported hotkey key: $Part"
            }
        }
    }

    if ($null -eq $Key)
    {
        throw "Invalid hotkey: $Hotkey"
    }

    return [PSCustomObject]@{
        Key      = $Key
        Modifier = $Modifier
    }
}


# ============================================================
# Validate hotkey
# ============================================================

function Test-VolScriptHotkey
{
    param(
        [Parameter(Mandatory)]
        [string]$Hotkey
    )

    try
    {
        $null =
            ConvertTo-VolScriptHotkey `
                -Hotkey $Hotkey

        return $true
    }
    catch
    {
        return $false
    }
}


# ============================================================
# Hotkey capture
# ============================================================

function Get-VolScriptHotkeyCaptureStateKey
{
    param(
        [switch]$Complete,

        [string]$Result
    )

    if ($Complete)
    {
        return "DONE:$Result"
    }

    $Parts = @()

    if ([VolScript.VolScriptHotkeyCapture]::ControlPressed)
    {
        $Parts += "CTRL"
    }

    if ([VolScript.VolScriptHotkeyCapture]::AltPressed)
    {
        $Parts += "ALT"
    }

    if ([VolScript.VolScriptHotkeyCapture]::ShiftPressed)
    {
        $Parts += "SHIFT"
    }

    if ($Parts.Count -eq 0)
    {
        return "IDLE"
    }

    return ($Parts -join "+") + "+"
}


function Show-VolScriptHotkeyCaptureLine
{
    param(
        [Parameter(Mandatory)]
        [int]$LineTop,

        [switch]$Complete,

        [string]$Result,

        [switch]$Force
    )

    $StateKey =
        Get-VolScriptHotkeyCaptureStateKey `
            -Complete:$Complete `
            -Result $Result

    if (
        -not $Force -and
        $StateKey -eq $script:LastCaptureDisplayKey
    )
    {
        return $false
    }

    $script:LastCaptureDisplayKey = $StateKey

    $Width =
        [Math]::Max(
            [Console]::WindowWidth,
            80)

    [Console]::SetCursorPosition(
        0,
        $LineTop)

    Write-Host "  Shortcut: " `
        -NoNewline `
        -ForegroundColor DarkGray

    if ($Complete -and -not [string]::IsNullOrWhiteSpace($Result))
    {
        Write-Host $Result `
            -NoNewline `
            -ForegroundColor Green
    }
    else
    {
        $Parts = @()

        if ([VolScript.VolScriptHotkeyCapture]::ControlPressed)
        {
            $Parts += "CTRL"
        }

        if ([VolScript.VolScriptHotkeyCapture]::AltPressed)
        {
            $Parts += "ALT"
        }

        if ([VolScript.VolScriptHotkeyCapture]::ShiftPressed)
        {
            $Parts += "SHIFT"
        }

        for ($Index = 0; $Index -lt $Parts.Count; $Index++)
        {
            if ($Index -gt 0)
            {
                Write-Host " + " `
                    -NoNewline `
                    -ForegroundColor DarkGray
            }

            Write-Host $Parts[$Index] `
                -NoNewline `
                -ForegroundColor Cyan
        }

        if ($Parts.Count -gt 0)
        {
            Write-Host " + " `
                -NoNewline `
                -ForegroundColor DarkGray

            Write-Host "..." `
                -NoNewline `
                -ForegroundColor Yellow
        }
        else
        {
            Write-Host "..." `
                -NoNewline `
                -ForegroundColor DarkGray
        }
    }

    $Remaining =
        $Width - [Console]::CursorLeft

    if ($Remaining -gt 0)
    {
        Write-Host (
            (" " * $Remaining)
        ) -NoNewline
    }

    return $true
}


function Read-VolScriptHotkeyCapture
{
    param(
        [Parameter(Mandatory)]
        [string]$Current
    )

    $script:LastCaptureDisplayKey = $null

    Write-Host ""

    Write-Host "  Press keys for the shortcut." `
        -ForegroundColor DarkGray

    Write-Host "  Enter = keep current" `
        -ForegroundColor DarkGray

    Write-Host ""

    $CaptureLineTop = [Console]::CursorTop

    [VolScript.VolScriptHotkeyCapture]::Start()

    try
    {
        while (-not [VolScript.VolScriptHotkeyCapture]::IsComplete)
        {
            $null =
                Show-VolScriptHotkeyCaptureLine `
                    -LineTop $CaptureLineTop

            Start-Sleep `
                -Milliseconds 50
        }

        if ([VolScript.VolScriptHotkeyCapture]::KeepCurrent)
        {
            Show-VolScriptHotkeyCaptureLine `
                -LineTop $CaptureLineTop `
                -Complete `
                -Result $Current `
                -Force | Out-Null

            Write-Host ""

            return $Current
        }

        $Result =
            [VolScript.VolScriptHotkeyCapture]::Result

        Show-VolScriptHotkeyCaptureLine `
            -LineTop $CaptureLineTop `
            -Complete `
            -Result $Result `
            -Force | Out-Null

        Write-Host ""

        return $Result
    }
    finally
    {
        [VolScript.VolScriptHotkeyCapture]::Stop()

        Start-Sleep `
            -Milliseconds 100

        [VolScript.VolScriptHotkeyCapture]::FlushConsoleInput()

        while ([Console]::KeyAvailable)
        {
            $null =
                [Console]::ReadKey($true)
        }

        $script:LastCaptureDisplayKey = $null
    }
}


# ============================================================
# Start
# ============================================================

function Start-VolScriptHotkeys
{
    param(
        [Parameter(Mandatory)]
        [string]$Volume50Key,

        [Parameter(Mandatory)]
        [string]$Volume100Key,

        [Parameter(Mandatory)]
        [string]$ExitKey
    )

    $Hotkey50 =
        ConvertTo-VolScriptHotkey `
            -Hotkey $Volume50Key

    $Hotkey100 =
        ConvertTo-VolScriptHotkey `
            -Hotkey $Volume100Key

    $HotkeyExit =
        ConvertTo-VolScriptHotkey `
            -Hotkey $ExitKey

    [VolScript.VolScriptHotKeys]::Configure(
        $Hotkey50.Key,
        $Hotkey50.Modifier,
        $Hotkey100.Key,
        $Hotkey100.Modifier,
        $HotkeyExit.Key,
        $HotkeyExit.Modifier
    )

    [VolScript.VolScriptHotKeys]::Start()
}


# ============================================================
# Stop
# ============================================================

function Stop-VolScriptHotkeys
{
    [VolScript.VolScriptHotKeys]::Stop()
}


# ============================================================
# Get action
# ============================================================

function Get-VolScriptHotkeyAction
{
    return [VolScript.VolScriptHotKeys]::LastAction
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    ConvertTo-VolScriptHotkey, `
    Test-VolScriptHotkey, `
    Read-VolScriptHotkeyCapture, `
    Start-VolScriptHotkeys, `
    Stop-VolScriptHotkeys, `
    Get-VolScriptHotkeyAction
