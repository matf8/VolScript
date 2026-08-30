$ErrorActionPreference = "Stop"


# ============================================================
# Dependencies
# ============================================================
# Requires Config.psm1 imported by the caller.

Import-Module `
    "$PSScriptRoot\..\Utils\MenuInput.psm1"

Import-Module `
    "$PSScriptRoot\..\HotKeys\HotKeys.psm1"

Import-Module `
    "$PSScriptRoot\..\UI\Display.psm1"

Import-Module `
    "$PSScriptRoot\..\UI\Theme.psm1"


# ============================================================
# Load raw config
# ============================================================

function Get-VolScriptRawConfig
{
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

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
        [object]$Config,

        [Parameter(Mandatory)]
        [string]$ConfigDisplayPath,

        [switch]$Dirty
    )

    $Volume50Pct =
        [int]([double]$Config.volumes.volume50 * 100)

    $Volume100Pct =
        [int]([double]$Config.volumes.volume100 * 100)

    Show-VolScriptBanner `
        -Subtitle "Configuration" `
        -Dirty:$Dirty

    Write-Host "  File: $ConfigDisplayPath" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host ""

    Write-Host "  Shortcuts" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  [1] Volume $Volume50Pct%" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Accent) `
        -NoNewline

    Write-Host "  -> $($Config.shortcuts.volume50)"

    Write-Host "  [2] Volume $Volume100Pct%" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Accent) `
        -NoNewline

    Write-Host " -> $($Config.shortcuts.volume100)"

    Write-Host "  [3] Exit" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Accent) `
        -NoNewline

    Write-Host "       -> $($Config.shortcuts.exit)"

    Write-Host ""

    Write-Host "  Volumes" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  [4] Volume $Volume50Pct% level" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Accent) `
        -NoNewline

    Write-Host "  -> $Volume50Pct%"

    Write-Host "  [5] Volume $Volume100Pct% level" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Accent) `
        -NoNewline

    Write-Host " -> $Volume100Pct%"

    Write-Host ""

    Write-Host "  Actions" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

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
            -ForegroundColor (Get-VolScriptThemeColor -Role Label)

        Write-Host "  Current: $Current" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Label)

        $Value =
            Read-VolScriptHotkeyCapture `
                -Current $Current

        if (Test-VolScriptHotkey -Hotkey $Value)
        {
            return $Value.ToUpper()
        }

        Write-Host ""

        Write-Host "  Invalid shortcut: $Value" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Error)
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
            -ForegroundColor (Get-VolScriptThemeColor -Role Label)

        Write-Host "  Current: $CurrentPct%" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Label)

        Write-Host "  Range: 0-100" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Label)

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
                -ForegroundColor (Get-VolScriptThemeColor -Role Error)

            continue
        }

        $Percent = $Parsed

        if ($Percent -lt 0 -or $Percent -gt 100)
        {
            Write-Host ""

            Write-Host "  Volume must be between 0 and 100." `
                -ForegroundColor (Get-VolScriptThemeColor -Role Error)

            continue
        }

        return $Percent / 100
    }
}


function Test-ConfigEditorDiscard
{
    param(
        [switch]$Dirty
    )

    if (-not $Dirty)
    {
        return $true
    }

    Write-Host ""

    Write-Host "  Unsaved changes will be lost." `
        -ForegroundColor (Get-VolScriptThemeColor -Role Warning)

    Write-Host ""

    $Confirm =
        Read-Host "  Discard changes? [y/N]"

    return ($Confirm -match "^[yY]")
}


# ============================================================
# Config editor
# ============================================================

function Start-VolScriptConfigEditor
{
    param(
        [string]$ProcessName
    )

    try
    {
        $ConfigPath =
            Resolve-VolScriptEditorConfigPath `
                -ProcessName $ProcessName

        Set-VolScriptActiveConfigPath `
            -ConfigPath $ConfigPath

        $ConfigDisplayPath =
            Get-VolScriptConfigDisplayPath `
                -ConfigPath $ConfigPath

        $Config =
            Get-VolScriptRawConfig `
                -ConfigPath $ConfigPath

        $script:ConfigDirty = $false

        while ($true)
        {
            Clear-Host

            Show-ConfigEditorMenu `
                -Config $Config `
                -ConfigDisplayPath $ConfigDisplayPath `
                -Dirty:$script:ConfigDirty

        $Choice =
            Read-VolScriptMenuChoice `
                -ValidChoices @(
                    "1"
                    "2"
                    "3"
                    "4"
                    "5"
                    "S"
                    "Q"
                )

        switch ($Choice)
        {
            "1"
            {
                $Config.shortcuts.volume50 =
                    Read-ConfigHotkey `
                        -Label "Volume 50% shortcut" `
                        -Current $Config.shortcuts.volume50

                $script:ConfigDirty = $true
            }

            "2"
            {
                $Config.shortcuts.volume100 =
                    Read-ConfigHotkey `
                        -Label "Volume 100% shortcut" `
                        -Current $Config.shortcuts.volume100

                $script:ConfigDirty = $true
            }

            "3"
            {
                $Config.shortcuts.exit =
                    Read-ConfigHotkey `
                        -Label "Exit shortcut" `
                        -Current $Config.shortcuts.exit

                $script:ConfigDirty = $true
            }

            "4"
            {
                $Config.volumes.volume50 =
                    Read-ConfigVolume `
                        -Label "Volume 50% level" `
                        -Current ([double]$Config.volumes.volume50)

                $script:ConfigDirty = $true
            }

            "5"
            {
                $Config.volumes.volume100 =
                    Read-ConfigVolume `
                        -Label "Volume 100% level" `
                        -Current ([double]$Config.volumes.volume100)

                $script:ConfigDirty = $true
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
                            -ForegroundColor (Get-VolScriptThemeColor -Role Error)

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
                        -ForegroundColor (Get-VolScriptThemeColor -Role Error)

                    Start-Sleep `
                        -Milliseconds 1200

                    continue
                }

                Save-VolScriptConfig `
                    -Config $Config

                Clear-Host

                Write-Host ""

                Write-Host "  Configuration saved." `
                    -ForegroundColor (Get-VolScriptThemeColor -Role Success)

                Write-Host ""

                return
            }

            "Q"
            {
                if (-not (Test-ConfigEditorDiscard -Dirty:$script:ConfigDirty))
                {
                    continue
                }

                Clear-Host

                Write-Host ""

                Write-Host "  Changes discarded." `
                    -ForegroundColor (Get-VolScriptThemeColor -Role Warning)

                Write-Host ""

                return
            }

            default
            {
                Write-Host ""

                Write-Host "  Invalid option: $Choice" `
                    -ForegroundColor (Get-VolScriptThemeColor -Role Error)

                Start-Sleep `
                    -Milliseconds 800
            }
        }
        }
    }
    finally
    {
        Clear-VolScriptActiveConfigPath
    }
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function Start-VolScriptConfigEditor
