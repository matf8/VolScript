$ErrorActionPreference = "Stop"


Import-Module `
    "$PSScriptRoot\..\UI\Theme.psm1" `
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
# Invalid argument
# ============================================================

function Show-InvalidProcessName
{
    Write-Host ""

    Write-Host `
        "ERROR: process name is required." `
        -ForegroundColor (Get-VolScriptThemeColor -Role Error)

    Write-Host ""

    Write-Host "Usage:"

    Write-Host `
        "  .\VolScript.ps1 <ProcessName>"

    Write-Host ""

    Write-Host "Examples:"

    Write-Host `
        "  .\VolScript.ps1 spotify"

    Write-Host `
        "  .\VolScript.ps1 cod -q"

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
        "  .\VolScript.ps1 -c spotify"

    Write-Host `
        "  .\VolScript.ps1 --config"

    Write-Host ""
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    Test-ProcessName, `
    Show-InvalidProcessName
