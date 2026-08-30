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
        "HotKeys.cs"
    )

    $Source = @()

    foreach ($File in $SourceFiles)
    {
        $Content =
            Get-Content `
                (Join-Path $CorePath $File) `
                -Raw

        $Source += $Content
        $Source += ""
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
                $Modifier = 0x11
                continue
            }

            "ALT"
            {
                $Modifier = 0x12
                continue
            }

            "SHIFT"
            {
                $Modifier = 0x10
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
    Start-VolScriptHotkeys, `
    Stop-VolScriptHotkeys, `
    Get-VolScriptHotkeyAction
