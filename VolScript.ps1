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
    "$PSScriptRoot\src\Utils\ArgValidate.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\src\UI\UI.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\src\Actions\Actions.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\src\Config\ConfigEditor.psm1" `
    -Force


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

if (
    $Config -or
    $ProcessName -eq "--config" -or
    $ProcessName -eq "-c"
)
{
    Start-VolScriptConfigEditor

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
# Start
# ============================================================

Start-VolScript `
    -ProcessName $ProcessName `
    -Quiet:$Quiet
