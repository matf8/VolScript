$ErrorActionPreference = "Stop"


Import-Module `
    "$PSScriptRoot\..\Core\Core.psm1"

Import-Module `
    "$PSScriptRoot\..\UI\Theme.psm1"


# ============================================================
# Convert hotkey
# ============================================================

function ConvertTo-VolScriptHotkey
{
    param(
        [Parameter(Mandatory)]
        [string]$Hotkey
    )

    $KeyMap = @{
        "ESC" = 0x1B
        "F1"  = 0x70
        "F2"  = 0x71
        "F3"  = 0x72
        "F4"  = 0x73
        "F5"  = 0x74
        "F6"  = 0x75
        "F7"  = 0x76
        "F8"  = 0x77
        "F9"  = 0x78
        "F10" = 0x79
        "F11" = 0x7A
        "F12" = 0x7B
        "A"   = 0x41
        "B"   = 0x42
        "C"   = 0x43
        "D"   = 0x44
        "E"   = 0x45
        "F"   = 0x46
        "G"   = 0x47
        "H"   = 0x48
        "I"   = 0x49
        "J"   = 0x4A
        "K"   = 0x4B
        "L"   = 0x4C
        "M"   = 0x4D
        "N"   = 0x4E
        "O"   = 0x4F
        "P"   = 0x50
        "Q"   = 0x51
        "R"   = 0x52
        "S"   = 0x53
        "T"   = 0x54
        "U"   = 0x55
        "V"   = 0x56
        "W"   = 0x57
        "X"   = 0x58
        "Y"   = 0x59
        "Z"   = 0x5A
        "0"   = 0x30
        "1"   = 0x31
        "2"   = 0x32
        "3"   = 0x33
        "4"   = 0x34
        "5"   = 0x35
        "6"   = 0x36
        "7"   = 0x37
        "8"   = 0x38
        "9"   = 0x39
    }

    $Parts =
        $Hotkey.ToUpper().Split(
            "+",
            [System.StringSplitOptions]::RemoveEmptyEntries
        )

    $Modifier = 0
    $Key = $null

    foreach ($Part in $Parts)
    {
        if ($Part -eq "CTRL" -or $Part -eq "CONTROL")
        {
            $Modifier = $Modifier -bor 2
        }
        elseif ($Part -eq "ALT")
        {
            $Modifier = $Modifier -bor 4
        }
        elseif ($Part -eq "SHIFT")
        {
            $Modifier = $Modifier -bor 1
        }
        elseif ($KeyMap.ContainsKey($Part))
        {
            $Key = $KeyMap[$Part]
        }
        else
        {
            throw "Unsupported hotkey key: $Part"
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
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    if ($Complete -and -not [string]::IsNullOrWhiteSpace($Result))
    {
        Write-Host $Result `
            -NoNewline `
            -ForegroundColor (Get-VolScriptThemeColor -Role Success)
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
                    -ForegroundColor (Get-VolScriptThemeColor -Role Label)
            }

            Write-Host $Parts[$Index] `
                -NoNewline `
                -ForegroundColor (Get-VolScriptThemeColor -Role Accent)
        }

        if ($Parts.Count -gt 0)
        {
            Write-Host " + " `
                -NoNewline `
                -ForegroundColor (Get-VolScriptThemeColor -Role Label)

            Write-Host "..." `
                -NoNewline `
                -ForegroundColor (Get-VolScriptThemeColor -Role Warning)
        }
        else
        {
            Write-Host "..." `
                -NoNewline `
                -ForegroundColor (Get-VolScriptThemeColor -Role Label)
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
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  Enter = keep current" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

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


function Stop-VolScriptHotkeys
{
    [VolScript.VolScriptHotKeys]::Stop()
}


function Get-VolScriptHotkeyAction
{
    return [int][VolScript.VolScriptHotKeys]::LastAction
}


Export-ModuleMember -Function `
    ConvertTo-VolScriptHotkey, `
    Test-VolScriptHotkey, `
    Read-VolScriptHotkeyCapture, `
    Start-VolScriptHotkeys, `
    Stop-VolScriptHotkeys, `
    Get-VolScriptHotkeyAction
