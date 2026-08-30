$ErrorActionPreference = "Stop"


# ============================================================
# Dependencies
# ============================================================

Import-Module `
    "$PSScriptRoot\ProcessLifecycle.psm1" `
    -Force


# ============================================================
# Process name validation
# ============================================================

function Test-ProcessName
{
    param(
        [string]$ProcessName
    )

    return -not [string]::IsNullOrWhiteSpace(
        $ProcessName
    )
}


# ============================================================
# Process validation
# ============================================================

function Test-ProcessRunning
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    return $null -ne (
        Get-VolScriptTargetProcess `
            -ProcessName $ProcessName
    )
}


# ============================================================
# Invalid argument
# ============================================================

function Show-InvalidProcessName
{
    Write-Host ""

    Write-Host `
        "ERROR: process name is required." `
        -ForegroundColor Red

    Write-Host ""

    Write-Host "Usage:"

    Write-Host `
        "  .\VolScript.ps1 <ProcessName>"

    Write-Host ""

    Write-Host "Examples:"

    Write-Host `
        "  .\VolScript.ps1 spotify"

    Write-Host `
        "  .\VolScript.ps1 cod"

    Write-Host ""

    Write-Host "Help:"

    Write-Host `
        "  .\VolScript.ps1 -h"

    Write-Host `
        "  .\VolScript.ps1 --help"

    Write-Host ""

    Write-Host "Config:"

    Write-Host `
        "  .\VolScript.ps1 -c"

    Write-Host `
        "  .\VolScript.ps1 --config"

    Write-Host ""
}


# ============================================================
# Process not running
# ============================================================

function Show-ProcessNotRunning
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    Write-Host ""

    Write-Host `
        "ERROR: process '$ProcessName' is not running." `
        -ForegroundColor Red

    Write-Host ""
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    Test-ProcessName, `
    Test-ProcessRunning, `
    Show-InvalidProcessName, `
    Show-ProcessNotRunning
