$ErrorActionPreference = "Stop"


# ============================================================
# Dependencies
# ============================================================

Import-Module `
    "$PSScriptRoot\Config.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\..\HotKeys\HotKeys.psm1" `
    -Force


# ============================================================
# Load raw config
# ============================================================

function Get-VolScriptRawConfig
{
    $ConfigPath = Get-VolScriptConfigPath

    if (-not (Test-Path $ConfigPath))
    {
        throw "Configuration file not found: $ConfigPath"
    }

    return Get-Content `
        -Path $ConfigPath `
        -Raw |
        ConvertFrom-Json
}


# ============================================================
# Menu
# ============================================================

function Show-ConfigEditorMenu
{
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $Volume50Pct =
        [int]([double]$Config.volumes.volume50 * 100)

    $Volume100Pct =
        [int]([double]$Config.volumes.volume100 * 100)

    Write-Host ""

    Write-Host "+------------------------------------------+" `
        -ForegroundColor Cyan

    Write-Host "|                 VolScript                |" `
        -ForegroundColor Cyan

    Write-Host "|                Configuration             |" `
        -ForegroundColor Cyan

    Write-Host "+------------------------------------------+" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-Host "  Shortcuts" `
        -ForegroundColor DarkGray

    Write-Host "  [1] Volume $Volume50Pct%" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host "  -> $($Config.shortcuts.volume50)"

    Write-Host "  [2] Volume $Volume100Pct%" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host " -> $($Config.shortcuts.volume100)"

    Write-Host "  [3] Exit" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host "       -> $($Config.shortcuts.exit)"

    Write-Host ""

    Write-Host "  Volumes" `
        -ForegroundColor DarkGray

    Write-Host "  [4] Volume $Volume50Pct% level" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host "  -> $Volume50Pct%"

    Write-Host "  [5] Volume $Volume100Pct% level" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host " -> $Volume100Pct%"

    Write-Host ""

    Write-Host "  Actions" `
        -ForegroundColor DarkGray

    Write-Host "  [S] Save and exit"

    Write-Host "  [Q] Quit without saving"

    Write-Host ""
}


# ============================================================
# Prompt helpers
# ============================================================

function Read-ConfigHotkey
{
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$Current
    )

    while ($true)
    {
        Write-Host ""

        Write-Host "  $Label" `
            -ForegroundColor DarkGray

        Write-Host "  Current: $Current" `
            -ForegroundColor DarkGray

        $Value =
            Read-VolScriptHotkeyCapture `
                -Current $Current

        if (Test-VolScriptHotkey -Hotkey $Value)
        {
            return $Value.ToUpper()
        }

        Write-Host ""

        Write-Host "  Invalid shortcut: $Value" `
            -ForegroundColor Red
    }
}


function Read-ConfigVolume
{
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [double]$Current
    )

    $CurrentPct = [int]($Current * 100)

    while ($true)
    {
        Write-Host ""

        Write-Host "  $Label" `
            -ForegroundColor DarkGray

        Write-Host "  Current: $CurrentPct%" `
            -ForegroundColor DarkGray

        Write-Host "  Range: 0-100" `
            -ForegroundColor DarkGray

        Write-Host ""

        $Value =
            Read-Host "  New volume % (Enter to keep)"

        if ([string]::IsNullOrWhiteSpace($Value))
        {
            return $Current
        }

        $Parsed = 0.0

        if (-not [double]::TryParse(
            $Value,
            [ref]$Parsed
        ))
        {
            Write-Host ""

            Write-Host "  Invalid number: $Value" `
                -ForegroundColor Red

            continue
        }

        $Percent = $Parsed

        if ($Percent -lt 0 -or $Percent -gt 100)
        {
            Write-Host ""

            Write-Host "  Volume must be between 0 and 100." `
                -ForegroundColor Red

            continue
        }

        return $Percent / 100
    }
}


# ============================================================
# Config editor
# ============================================================

function Start-VolScriptConfigEditor
{
    $Config =
        Get-VolScriptRawConfig

    while ($true)
    {
        Clear-Host

        Show-ConfigEditorMenu `
            -Config $Config

        $Choice =
            Read-Host "  Select option"

        if ([string]::IsNullOrWhiteSpace($Choice))
        {
            continue
        }

        switch ($Choice.ToUpper())
        {
            "1"
            {
                $Config.shortcuts.volume50 =
                    Read-ConfigHotkey `
                        -Label "Volume 50% shortcut" `
                        -Current $Config.shortcuts.volume50
            }

            "2"
            {
                $Config.shortcuts.volume100 =
                    Read-ConfigHotkey `
                        -Label "Volume 100% shortcut" `
                        -Current $Config.shortcuts.volume100
            }

            "3"
            {
                $Config.shortcuts.exit =
                    Read-ConfigHotkey `
                        -Label "Exit shortcut" `
                        -Current $Config.shortcuts.exit
            }

            "4"
            {
                $Config.volumes.volume50 =
                    Read-ConfigVolume `
                        -Label "Volume 50% level" `
                        -Current ([double]$Config.volumes.volume50)
            }

            "5"
            {
                $Config.volumes.volume100 =
                    Read-ConfigVolume `
                        -Label "Volume 100% level" `
                        -Current ([double]$Config.volumes.volume100)
            }

            "S"
            {
                $Shortcuts = @(
                    $Config.shortcuts.volume50,
                    $Config.shortcuts.volume100,
                    $Config.shortcuts.exit
                )

                $IsValid = $true

                foreach ($Shortcut in $Shortcuts)
                {
                    if (-not (Test-VolScriptHotkey -Hotkey $Shortcut))
                    {
                        Write-Host ""

                        Write-Host `
                            "  Invalid shortcut: $Shortcut" `
                            -ForegroundColor Red

                        $IsValid = $false

                        break
                    }
                }

                if (-not $IsValid)
                {
                    Start-Sleep `
                        -Milliseconds 1200

                    continue
                }

                $Volume50 = [double]$Config.volumes.volume50
                $Volume100 = [double]$Config.volumes.volume100

                if (
                    $Volume50 -lt 0 -or $Volume50 -gt 1 -or
                    $Volume100 -lt 0 -or $Volume100 -gt 1
                )
                {
                    Write-Host ""

                    Write-Host `
                        "  Volumes must be between 0 and 100%." `
                        -ForegroundColor Red

                    Start-Sleep `
                        -Milliseconds 1200

                    continue
                }

                Save-VolScriptConfig `
                    -Config $Config

                Clear-Host

                Write-Host ""

                Write-Host "  Configuration saved." `
                    -ForegroundColor Green

                Write-Host ""

                return
            }

            "Q"
            {
                Clear-Host

                Write-Host ""

                Write-Host "  Changes discarded." `
                    -ForegroundColor Yellow

                Write-Host ""

                return
            }

            default
            {
                Write-Host ""

                Write-Host "  Invalid option: $Choice" `
                    -ForegroundColor Red

                Start-Sleep `
                    -Milliseconds 800
            }
        }
    }
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function Start-VolScriptConfigEditor
