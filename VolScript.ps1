param(
    [string]$ProcessName
)

$ErrorActionPreference = "Stop"


# ============================================================
# Modules
# ============================================================

Import-Module `
    "$PSScriptRoot\src\Utils\ArgValidate.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\src\Actions\Actions.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\src\UI\Help.psm1" `
    -Force


# ============================================================
# Help
# ============================================================

if (
    $ProcessName -eq "--help" -or
    $ProcessName -eq "-h"
)
{
    Show-VolScriptHelp

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
# Process validation
# ============================================================

if (-not (Test-ProcessRunning $ProcessName))
{
    Show-ProcessNotRunning `
        -ProcessName $ProcessName

    exit 1
}


# ============================================================
# Start
# ============================================================

Start-VolScript `
    -ProcessName $ProcessName
