$ErrorActionPreference = "Stop"


# ============================================================
# Configuration path
# ============================================================

function Get-VolScriptConfigPath
{
    return Join-Path `
        $PSScriptRoot `
        "..\..\config.json"
}


# ============================================================
# Configuration
# ============================================================

function Get-VolScriptConfig
{
    $ConfigPath = Get-VolScriptConfigPath

    if (-not (Test-Path $ConfigPath))
    {
        throw "Configuration file not found: $ConfigPath"
    }

    try
    {
        $Config = Get-Content `
            -Path $ConfigPath `
            -Raw |
            ConvertFrom-Json
    }
    catch
    {
        throw "Invalid configuration file: $ConfigPath"
    }


    # ========================================================
    # Validate configuration
    # ========================================================

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


    # ========================================================
    # Return normalized configuration
    # ========================================================

    return [PSCustomObject]@{

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


# ============================================================
# Save configuration
# ============================================================

function Save-VolScriptConfig
{
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $ConfigPath = Get-VolScriptConfigPath

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
        -Path $ConfigPath `
        -Value $Json `
        -Encoding UTF8 `
        -NoNewline
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    Get-VolScriptConfigPath, `
    Get-VolScriptConfig, `
    Save-VolScriptConfig
