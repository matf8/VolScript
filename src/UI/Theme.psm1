$ErrorActionPreference = "Stop"


# ============================================================
# Theme palettes
# ============================================================

$script:VolScriptThemePalettes = @{
    dark = @{
        Banner    = "Cyan"
        Label     = "DarkGray"
        Accent    = "Cyan"
        Success   = "Green"
        Warning   = "Yellow"
        Error     = "Red"
        Muted     = "DarkGray"
        Highlight = "Green"
    }

    light = @{
        Banner    = "DarkCyan"
        Label     = "DarkGray"
        Accent    = "DarkCyan"
        Success   = "DarkGreen"
        Warning   = "DarkYellow"
        Error     = "DarkRed"
        Muted     = "DarkGray"
        Highlight = "DarkGreen"
    }
}


# ============================================================
# Detection
# ============================================================

function Test-VolScriptLightBackground
{
    $Override =
        $env:VOLSCRIPT_THEME

    if ($Override -eq "dark")
    {
        return $false
    }

    if ($Override -eq "light")
    {
        return $true
    }

    try
    {
        $Background =
            [Console]::BackgroundColor

        if ($Host.UI -and $Host.UI.RawUI)
        {
            $Background =
                $Host.UI.RawUI.BackgroundColor
        }

        return $Background -in @(
            [ConsoleColor]::White
            [ConsoleColor]::Gray
            [ConsoleColor]::Yellow
        )
    }
    catch
    {
        return $false
    }
}


function Initialize-VolScriptTheme
{
    $ThemeName =
        if (Test-VolScriptLightBackground)
        {
            "light"
        }
        else
        {
            "dark"
        }

    $script:VolScriptThemeName = $ThemeName
    $script:VolScriptTheme =
        $script:VolScriptThemePalettes[$ThemeName]
}


function Get-VolScriptThemeName
{
    if ($null -eq $script:VolScriptTheme)
    {
        Initialize-VolScriptTheme
    }

    return $script:VolScriptThemeName
}


function Get-VolScriptThemeColor
{
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            "Banner",
            "Label",
            "Accent",
            "Success",
            "Warning",
            "Error",
            "Muted",
            "Highlight"
        )]
        [string]$Role
    )

    if ($null -eq $script:VolScriptTheme)
    {
        Initialize-VolScriptTheme
    }

    return $script:VolScriptTheme[$Role]
}


Initialize-VolScriptTheme


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    Get-VolScriptThemeColor, `
    Get-VolScriptThemeName, `
    Initialize-VolScriptTheme, `
    Test-VolScriptLightBackground
