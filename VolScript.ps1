param(
    [Parameter(Position = 0)]
    [string]$ProcessName,

    [Alias("h")]
    [switch]$Help,

    [Alias("c")]
    [switch]$Config,

    [Alias("q")]
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"


# ============================================================
# Modules
# ============================================================

Import-Module `
    "$PSScriptRoot\src\Loader.psm1"

Import-VolScriptModules


# ============================================================
# Help
# ============================================================

if (
    $Help -or
    $ProcessName -eq "--help" -or
    $ProcessName -eq "-h"
)
{
    Show-VolScriptHelp

    exit 0
}


# ============================================================
# Config
# ============================================================

$ConfigMode =
    $Config -or
    $ProcessName -eq "--config" -or
    $ProcessName -eq "-c"

if ($ConfigMode)
{
    $ProfileProcess = $null

    if (
        -not [string]::IsNullOrWhiteSpace($ProcessName) -and
        $ProcessName -ne "--config" -and
        $ProcessName -ne "-c"
    )
    {
        if (-not (Test-ProcessName $ProcessName))
        {
            Show-InvalidProcessName

            exit 1
        }

        $ProfileProcess = $ProcessName
    }

    Start-VolScriptConfigEditor `
        -ProcessName $ProfileProcess

    exit 0
}


# ============================================================
# Argument validation
# ============================================================

if (-not (Test-ProcessName $ProcessName))
{
    Show-InvalidProcessName

    exit 1
}


# ============================================================
# Instance resolution
# ============================================================

$Startup =
    Resolve-VolScriptStartup `
        -ProcessName $ProcessName `
        -Quiet:$Quiet

if ($Startup.Action -ne "Start")
{
    Clear-VolScriptActiveConfigPath

    exit 0
}


# ============================================================
# Start
# ============================================================

Start-VolScript `
    -ProcessName $Startup.ProcessName `
    -ConfigPath $Startup.ConfigPath `
    -IsPrimary:$Startup.IsPrimary `
    -Quiet:$Quiet
