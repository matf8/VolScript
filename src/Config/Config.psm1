$ErrorActionPreference = "Stop"


# ============================================================
# Configuration paths
# ============================================================

function Get-VolScriptConfigDirectory
{
    return Join-Path `
        $PSScriptRoot `
        "..\..\config"
}


function Get-VolScriptDefaultConfigPath
{
    return Join-Path `
        (Get-VolScriptConfigDirectory) `
        "config.json"
}


function Get-VolScriptProcessConfigFileName
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    $Name = $ProcessName.Trim()

    if ($Name.EndsWith(".exe", [StringComparison]::OrdinalIgnoreCase))
    {
        $Name = $Name.Substring(0, $Name.Length - 4)
    }

    $Name = ($Name.ToLowerInvariant() -replace '[^a-z0-9\-]', '')

    if ([string]::IsNullOrWhiteSpace($Name))
    {
        throw "Invalid process name for config profile: $ProcessName"
    }

    return "config.$Name.json"
}


function Get-VolScriptProcessConfigPath
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    return Join-Path `
        (Get-VolScriptConfigDirectory) `
        (Get-VolScriptProcessConfigFileName -ProcessName $ProcessName)
}


function Get-VolScriptConfigPath
{
    if (-not [string]::IsNullOrWhiteSpace($script:VolScriptActiveConfigPath))
    {
        return $script:VolScriptActiveConfigPath
    }

    return Get-VolScriptDefaultConfigPath
}


function Set-VolScriptActiveConfigPath
{
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    $script:VolScriptActiveConfigPath = $ConfigPath
}


function Clear-VolScriptActiveConfigPath
{
    $script:VolScriptActiveConfigPath = $null
}


function Test-VolScriptPrimaryConfigPath
{
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    $DefaultPath =
        (Get-VolScriptDefaultConfigPath | Resolve-Path).Path

    $Resolved =
        (Resolve-Path $ConfigPath).Path

    return ($Resolved -eq $DefaultPath)
}


function Get-VolScriptNotePropertyNames
{
    param(
        [Parameter(Mandatory)]
        [object]$Object
    )

    if ($null -eq $Object)
    {
        return @()
    }

    return @(
        $Object.PSObject.Properties |
        Where-Object {
            $_.MemberType -eq "NoteProperty"
        } |
        ForEach-Object {
            $_.Name
        }
    )
}


function Get-VolScriptRawVolumePresetIds
{
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    return @(
        Get-VolScriptNotePropertyNames `
            -Object $Config.volumes
    )
}


# ============================================================
# Profile initialization
# ============================================================

function Initialize-VolScriptProcessConfig
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    $ProfilePath =
        Get-VolScriptProcessConfigPath `
            -ProcessName $ProcessName

    if (Test-Path $ProfilePath)
    {
        return $ProfilePath
    }

    $DefaultPath = Get-VolScriptDefaultConfigPath

    if (-not (Test-Path $DefaultPath))
    {
        throw "Default configuration file not found: $DefaultPath"
    }

    $DefaultConfig =
        Get-Content `
            -Path $DefaultPath `
            -Raw |
        ConvertFrom-Json

    if ($null -ne $DefaultConfig.shortcuts.volume50)
    {
        $DefaultConfig.shortcuts.volume50 = "CTRL+ALT+SHIFT+P"
    }

    if ($null -ne $DefaultConfig.shortcuts.volume100)
    {
        $DefaultConfig.shortcuts.volume100 = "CTRL+ALT+SHIFT+O"
    }

    $DefaultConfig.shortcuts.exit = "CTRL+ALT+SHIFT+Q"

    Save-VolScriptConfig `
        -Config $DefaultConfig `
        -ConfigPath $ProfilePath

    return $ProfilePath
}


# ============================================================
# Configuration
# ============================================================

function Get-VolScriptConfig
{
    param(
        [string]$ConfigPath
    )

    if (-not [string]::IsNullOrWhiteSpace($ConfigPath))
    {
        Set-VolScriptActiveConfigPath `
            -ConfigPath $ConfigPath
    }

    $ResolvedPath = Get-VolScriptConfigPath

    if (-not (Test-Path $ResolvedPath))
    {
        throw "Configuration file not found: $ResolvedPath"
    }

    try
    {
        $Config = Get-Content `
            -Path $ResolvedPath `
            -Raw |
            ConvertFrom-Json
    }
    catch
    {
        throw "Invalid configuration file: $ResolvedPath"
    }


    if ($null -eq $Config.shortcuts)
    {
        throw "Configuration error: 'shortcuts' is required."
    }

    if ($null -eq $Config.volumes)
    {
        throw "Configuration error: 'volumes' is required."
    }


    if ([string]::IsNullOrWhiteSpace(
        $Config.shortcuts.exit))
    {
        throw "Configuration error: 'shortcuts.exit' is required."
    }


    $VolumeIds =
        Get-VolScriptRawVolumePresetIds `
            -Config $Config

    if ($VolumeIds.Count -lt 1)
    {
        throw "Configuration error: at least one volume preset is required."
    }

    $ShortcutIds =
        Get-VolScriptNotePropertyNames `
            -Object $Config.shortcuts |
        Where-Object {
            -not $_.Equals(
                "exit",
                [StringComparison]::OrdinalIgnoreCase)
        }

    foreach ($ShortcutId in $ShortcutIds)
    {
        $Matched =
            $VolumeIds |
            Where-Object {
                $_.Equals(
                    $ShortcutId,
                    [StringComparison]::OrdinalIgnoreCase)
            }

        if ($null -eq $Matched -or @($Matched).Count -eq 0)
        {
            throw "Configuration error: 'shortcuts.$ShortcutId' has no matching volumes entry."
        }
    }

    $Presets = @()

    foreach ($VolumeId in $VolumeIds)
    {
        $Hotkey =
            [string]$Config.shortcuts.$VolumeId

        if ([string]::IsNullOrWhiteSpace($Hotkey))
        {
            throw "Configuration error: 'shortcuts.$VolumeId' is required."
        }

        $Level =
            [float]$Config.volumes.$VolumeId

        if ($Level -lt 0 -or $Level -gt 1)
        {
            throw "Configuration error: 'volumes.$VolumeId' must be between 0 and 1."
        }

        $Presets += [PSCustomObject]@{
            Id      = $VolumeId
            Hotkey  = $Hotkey
            Level   = $Level
        }
    }


    return [PSCustomObject]@{

        ConfigPath = $ResolvedPath

        Presets = $Presets

        Exit = [string]$Config.shortcuts.exit
    }
}


function Get-VolScriptShortcutList
{
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $Shortcuts = @(
        $Config.Presets |
        ForEach-Object {
            [string]$_.Hotkey
        }
    )

    $Shortcuts += [string]$Config.Exit

    return $Shortcuts
}


function Get-VolScriptShortcutMap
{
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $Map = [ordered]@{}

    foreach ($Preset in $Config.Presets)
    {
        $Map[[string]$Preset.Id] = [string]$Preset.Hotkey
    }

    $Map["exit"] = [string]$Config.Exit

    return [PSCustomObject]$Map
}


function Get-VolScriptPreset
{
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [Parameter(Mandatory)]
        [string]$PresetId
    )

    $Preset =
        @(
            $Config.Presets |
            Where-Object {
                $_.Id.Equals(
                    $PresetId,
                    [StringComparison]::OrdinalIgnoreCase)
            }
        ) |
        Select-Object -First 1

    if ($null -eq $Preset)
    {
        throw "Unknown volume preset: $PresetId"
    }

    return $Preset
}


function Resolve-VolScriptEditorConfigPath
{
    param(
        [string]$ProcessName
    )

    Clear-VolScriptActiveConfigPath

    if ([string]::IsNullOrWhiteSpace($ProcessName))
    {
        return Get-VolScriptDefaultConfigPath
    }

    $ProfilePath =
        Get-VolScriptProcessConfigPath `
            -ProcessName $ProcessName

    if (-not (Test-Path $ProfilePath))
    {
        $ProfilePath =
            Initialize-VolScriptProcessConfig `
                -ProcessName $ProcessName
    }

    return $ProfilePath
}


function Get-VolScriptConfigDisplayPath
{
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    $FileName = Split-Path $ConfigPath -Leaf

    return Join-Path "config" $FileName
}


# ============================================================
# Save configuration
# ============================================================

function Save-VolScriptConfig
{
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [string]$ConfigPath
    )

    if (-not [string]::IsNullOrWhiteSpace($ConfigPath))
    {
        Set-VolScriptActiveConfigPath `
            -ConfigPath $ConfigPath
    }

    $ResolvedPath = Get-VolScriptConfigPath

    $Culture =
        [System.Globalization.CultureInfo]::InvariantCulture

    $VolumeIds =
        Get-VolScriptRawVolumePresetIds `
            -Config $Config

    if ($VolumeIds.Count -lt 1)
    {
        throw "Configuration error: at least one volume preset is required."
    }

    if ([string]::IsNullOrWhiteSpace(
        $Config.shortcuts.exit))
    {
        throw "Configuration error: 'shortcuts.exit' is required."
    }

    $ShortcutLines = @()
    $VolumeLines = @()

    foreach ($VolumeId in $VolumeIds)
    {
        $Hotkey =
            [string]$Config.shortcuts.$VolumeId

        if ([string]::IsNullOrWhiteSpace($Hotkey))
        {
            throw "Configuration error: 'shortcuts.$VolumeId' is required."
        }

        $Level =
            [double]$Config.volumes.$VolumeId

        if ($Level -lt 0 -or $Level -gt 1)
        {
            throw "Configuration error: 'volumes.$VolumeId' must be between 0 and 1."
        }

        $ShortcutLines +=
            "`t`t`"$VolumeId`": `"$Hotkey`","

        $VolumeLines +=
            "`t`t`"$VolumeId`": $($Level.ToString($Culture)),"
    }

    $ShortcutLines +=
        "`t`t`"exit`": `"$([string]$Config.shortcuts.exit)`""

    if ($VolumeLines.Count -gt 0)
    {
        $LastIndex = $VolumeLines.Count - 1
        $VolumeLines[$LastIndex] =
            $VolumeLines[$LastIndex].TrimEnd(',')
    }

    $Json = @"
{
	"shortcuts": {
$($ShortcutLines -join "`n")
	},
	"volumes": {
$($VolumeLines -join "`n")
	}
}
"@

    Set-Content `
        -Path $ResolvedPath `
        -Value $Json `
        -Encoding UTF8 `
        -NoNewline
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    Get-VolScriptConfigDirectory, `
    Get-VolScriptDefaultConfigPath, `
    Get-VolScriptProcessConfigFileName, `
    Get-VolScriptProcessConfigPath, `
    Get-VolScriptConfigPath, `
    Set-VolScriptActiveConfigPath, `
    Clear-VolScriptActiveConfigPath, `
    Test-VolScriptPrimaryConfigPath, `
    Initialize-VolScriptProcessConfig, `
    Resolve-VolScriptEditorConfigPath, `
    Get-VolScriptConfigDisplayPath, `
    Get-VolScriptConfig, `
    Get-VolScriptShortcutList, `
    Get-VolScriptShortcutMap, `
    Get-VolScriptPreset, `
    Get-VolScriptRawVolumePresetIds, `
    Get-VolScriptNotePropertyNames, `
    Save-VolScriptConfig
