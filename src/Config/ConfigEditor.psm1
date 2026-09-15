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
# Raw preset helpers
# ============================================================

function Get-ConfigEditorPresetIds
{
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    return @(
        Get-VolScriptRawVolumePresetIds `
            -Config $Config
    )
}


function Get-ConfigEditorPresetPct
{
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [Parameter(Mandatory)]
        [string]$PresetId
    )

    return [int]([double]$Config.volumes.$PresetId * 100)
}


function Get-ConfigEditorMenuModel
{
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $PresetIds =
        Get-ConfigEditorPresetIds `
            -Config $Config

    $ShortcutItems = @()
    $VolumeItems = @()
    $Choice = 1

    foreach ($PresetId in $PresetIds)
    {
        $Pct =
            Get-ConfigEditorPresetPct `
                -Config $Config `
                -PresetId $PresetId

        $ShortcutItems += [PSCustomObject]@{
            Choice   = [string]$Choice
            PresetId = $PresetId
            Label    = "Volume $Pct%"
            Hotkey   = [string]$Config.shortcuts.$PresetId
        }

        $Choice++
    }

    $ExitChoice = [string]$Choice

    $ShortcutItems += [PSCustomObject]@{
        Choice   = $ExitChoice
        PresetId = "exit"
        Label    = "Exit"
        Hotkey   = [string]$Config.shortcuts.exit
        IsExit   = $true
    }

    $Choice++

    foreach ($PresetId in $PresetIds)
    {
        $Pct =
            Get-ConfigEditorPresetPct `
                -Config $Config `
                -PresetId $PresetId

        $VolumeItems += [PSCustomObject]@{
            Choice   = [string]$Choice
            PresetId = $PresetId
            Label    = "Volume $Pct% level"
            Percent  = $Pct
        }

        $Choice++
    }

    return [PSCustomObject]@{
        PresetIds     = $PresetIds
        ShortcutItems = $ShortcutItems
        VolumeItems   = $VolumeItems
        ExitChoice    = $ExitChoice
    }
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

        [Parameter(Mandatory)]
        [object]$MenuModel,

        [switch]$Dirty
    )

    Show-VolScriptBanner `
        -Subtitle "Configuration" `
        -Dirty:$Dirty

    Write-Host "  File: $ConfigDisplayPath" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host ""

    Write-Host "  Shortcuts" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    foreach ($Item in $MenuModel.ShortcutItems)
    {
        $Pad =
            if ($Item.IsExit)
            {
                "       "
            }
            else
            {
                "  "
            }

        Write-Host "  [$($Item.Choice)] $($Item.Label)" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Accent) `
            -NoNewline

        Write-Host "$Pad-> $($Item.Hotkey)"
    }

    Write-Host ""

    Write-Host "  Volumes" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    foreach ($Item in $MenuModel.VolumeItems)
    {
        Write-Host "  [$($Item.Choice)] $($Item.Label)" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Accent) `
            -NoNewline

        Write-Host "  -> $($Item.Percent)%"
    }

    Write-Host ""

    Write-Host "  Actions" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  [A] Add volume shortcut"

    Write-Host "  [D] Delete volume shortcut"

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


function Read-ConfigEditorChoice
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ValidChoices
    )

    $NeedsLineInput =
        @(
            $ValidChoices |
            Where-Object {
                $_.Length -gt 1
            }
        ).Count -gt 0

    if (-not $NeedsLineInput)
    {
        return Read-VolScriptMenuChoice `
            -ValidChoices $ValidChoices
    }

    while ($true)
    {
        Write-Host "  Select option" -NoNewline
        Write-Host ": " -NoNewline

        $Choice =
            (Read-Host).Trim().ToUpper()

        if (Test-VolScriptMenuChoice `
            -Choice $Choice `
            -ValidChoices $ValidChoices)
        {
            return $Choice.ToUpper()
        }

        Write-Host ""

        Write-Host "  Invalid option: $Choice" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Error)

        Write-Host ""
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


function Add-ConfigEditorVolumePreset
{
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $Level =
        Read-ConfigVolume `
            -Label "New volume level" `
            -Current 0.5

    $Pct = [int]($Level * 100)
    $PresetId = "volume$Pct"

    $ExistingIds =
        Get-ConfigEditorPresetIds `
            -Config $Config

    $Exists =
        $ExistingIds |
        Where-Object {
            $_.Equals(
                $PresetId,
                [StringComparison]::OrdinalIgnoreCase)
        }

    if ($null -ne $Exists -and @($Exists).Count -gt 0)
    {
        Write-Host ""

        Write-Host `
            "  Preset '$PresetId' already exists. Edit it from the menu instead." `
            -ForegroundColor (Get-VolScriptThemeColor -Role Error)

        Start-Sleep `
            -Milliseconds 1400

        return $false
    }

    $Hotkey =
        Read-ConfigHotkey `
            -Label "New Volume $Pct% shortcut" `
            -Current "ALT+SHIFT+V"

    $Config.volumes |
        Add-Member `
            -MemberType NoteProperty `
            -Name $PresetId `
            -Value $Level `
            -Force

    $Config.shortcuts |
        Add-Member `
            -MemberType NoteProperty `
            -Name $PresetId `
            -Value $Hotkey `
            -Force

    return $true
}


function Remove-ConfigEditorVolumePreset
{
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $PresetIds =
        Get-ConfigEditorPresetIds `
            -Config $Config

    if ($PresetIds.Count -le 1)
    {
        Write-Host ""

        Write-Host `
            "  At least one volume preset is required." `
            -ForegroundColor (Get-VolScriptThemeColor -Role Error)

        Start-Sleep `
            -Milliseconds 1200

        return $false
    }

    Write-Host ""

    Write-Host "  Delete which preset?" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    $Index = 1
    $Choices = @()

    foreach ($PresetId in $PresetIds)
    {
        $Pct =
            Get-ConfigEditorPresetPct `
                -Config $Config `
                -PresetId $PresetId

        Write-Host "  [$Index] $PresetId ($Pct%)" `
            -ForegroundColor (Get-VolScriptThemeColor -Role Accent)

        $Choices += [string]$Index
        $Index++
    }

    Write-Host "  [C] Cancel"

    $Choices += "C"

    Write-Host ""

    $Choice =
        Read-ConfigEditorChoice `
            -ValidChoices $Choices

    if ($Choice -eq "C")
    {
        return $false
    }

    $SelectedIndex = [int]$Choice - 1
    $PresetId = $PresetIds[$SelectedIndex]

    $null =
        $Config.volumes.PSObject.Properties.Remove($PresetId)

    $null =
        $Config.shortcuts.PSObject.Properties.Remove($PresetId)

    return $true
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

            $MenuModel =
                Get-ConfigEditorMenuModel `
                    -Config $Config

            Show-ConfigEditorMenu `
                -Config $Config `
                -ConfigDisplayPath $ConfigDisplayPath `
                -MenuModel $MenuModel `
                -Dirty:$script:ConfigDirty

            $ValidChoices = @(
                $MenuModel.ShortcutItems |
                ForEach-Object {
                    $_.Choice
                }
            )

            $ValidChoices += @(
                $MenuModel.VolumeItems |
                ForEach-Object {
                    $_.Choice
                }
            )

            $ValidChoices += @(
                "A"
                "D"
                "S"
                "Q"
            )

            $Choice =
                Read-ConfigEditorChoice `
                    -ValidChoices $ValidChoices

            $ShortcutItem =
                @(
                    $MenuModel.ShortcutItems |
                    Where-Object {
                        $_.Choice -eq $Choice
                    }
                ) |
                Select-Object -First 1

            if ($null -ne $ShortcutItem)
            {
                if ($ShortcutItem.IsExit)
                {
                    $Config.shortcuts.exit =
                        Read-ConfigHotkey `
                            -Label "Exit shortcut" `
                            -Current $Config.shortcuts.exit
                }
                else
                {
                    $Pct =
                        Get-ConfigEditorPresetPct `
                            -Config $Config `
                            -PresetId $ShortcutItem.PresetId

                    $Config.shortcuts.($ShortcutItem.PresetId) =
                        Read-ConfigHotkey `
                            -Label "Volume $Pct% shortcut" `
                            -Current $Config.shortcuts.($ShortcutItem.PresetId)
                }

                $script:ConfigDirty = $true

                continue
            }

            $VolumeItem =
                @(
                    $MenuModel.VolumeItems |
                    Where-Object {
                        $_.Choice -eq $Choice
                    }
                ) |
                Select-Object -First 1

            if ($null -ne $VolumeItem)
            {
                $Config.volumes.($VolumeItem.PresetId) =
                    Read-ConfigVolume `
                        -Label $VolumeItem.Label `
                        -Current ([double]$Config.volumes.($VolumeItem.PresetId))

                $script:ConfigDirty = $true

                continue
            }

            switch ($Choice)
            {
                "A"
                {
                    if (Add-ConfigEditorVolumePreset -Config $Config)
                    {
                        $script:ConfigDirty = $true
                    }
                }

                "D"
                {
                    if (Remove-ConfigEditorVolumePreset -Config $Config)
                    {
                        $script:ConfigDirty = $true
                    }
                }

                "S"
                {
                    $PresetIds =
                        Get-ConfigEditorPresetIds `
                            -Config $Config

                    if ($PresetIds.Count -lt 1)
                    {
                        Write-Host ""

                        Write-Host `
                            "  At least one volume preset is required." `
                            -ForegroundColor (Get-VolScriptThemeColor -Role Error)

                        Start-Sleep `
                            -Milliseconds 1200

                        continue
                    }

                    $Shortcuts = @(
                        $PresetIds |
                        ForEach-Object {
                            [string]$Config.shortcuts.$_
                        }
                    )

                    $Shortcuts += [string]$Config.shortcuts.exit

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

                    $VolumesValid = $true

                    foreach ($PresetId in $PresetIds)
                    {
                        $Level =
                            [double]$Config.volumes.$PresetId

                        if ($Level -lt 0 -or $Level -gt 1)
                        {
                            $VolumesValid = $false
                            break
                        }
                    }

                    if (-not $VolumesValid)
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
