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

    $DefaultConfig.shortcuts.volume50 = "CTRL+ALT+SHIFT+P"
    $DefaultConfig.shortcuts.volume100 = "CTRL+ALT+SHIFT+O"
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
        $Config.shortcuts.volume50))
    {
        throw "Configuration error: 'shortcuts.volume50' is required."
    }

    if ([string]::IsNullOrWhiteSpace(
        $Config.shortcuts.volume100))
    {
        throw "Configuration error: 'shortcuts.volume100' is required."
    }

    if ([string]::IsNullOrWhiteSpace(
        $Config.shortcuts.exit))
    {
        throw "Configuration error: 'shortcuts.exit' is required."
    }


    $Volume50 = [float]$Config.volumes.volume50
    $Volume100 = [float]$Config.volumes.volume100


    if ($Volume50 -lt 0 -or $Volume50 -gt 1)
    {
        throw "Configuration error: 'volumes.volume50' must be between 0 and 1."
    }

    if ($Volume100 -lt 0 -or $Volume100 -gt 1)
    {
        throw "Configuration error: 'volumes.volume100' must be between 0 and 1."
    }


    return [PSCustomObject]@{

        ConfigPath = $ResolvedPath

        Volumes = [PSCustomObject]@{
            Volume50 = $Volume50
            Volume100 = $Volume100
        }

        Shortcuts = [PSCustomObject]@{
            Volume50 = [string]$Config.shortcuts.volume50
            Volume100 = [string]$Config.shortcuts.volume100
            Exit = [string]$Config.shortcuts.exit
        }
    }
}


function Get-VolScriptShortcutList
{
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    return @(
        [string]$Config.Shortcuts.Volume50
        [string]$Config.Shortcuts.Volume100
        [string]$Config.Shortcuts.Exit
    )
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

    $Volume50 =
        [double]$Config.volumes.volume50

    $Volume100 =
        [double]$Config.volumes.volume100

    $Culture =
        [System.Globalization.CultureInfo]::InvariantCulture

    $Json = @"
{
	"shortcuts": {
		"volume50": "$([string]$Config.shortcuts.volume50)",
		"volume100": "$([string]$Config.shortcuts.volume100)",
		"exit": "$([string]$Config.shortcuts.exit)"
	},
	"volumes": {
		"volume50": $($Volume50.ToString($Culture)),
		"volume100": $($Volume100.ToString($Culture))
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
    Save-VolScriptConfig
