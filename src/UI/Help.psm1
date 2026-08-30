$ErrorActionPreference = "Stop"


# ============================================================
# Help
# ============================================================

Import-Module `
    "$PSScriptRoot\Display.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\Theme.psm1" `
    -Force


function Show-VolScriptHelp
{
    Show-VolScriptBanner

    Write-Host "Usage" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  .\VolScript.ps1 <process>"

    Write-Host ""

    Write-Host "Example" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  .\VolScript.ps1 spotify"

    Write-Host ""

    Write-Host "Options" `
        -ForegroundColor (Get-VolScriptThemeColor -Role Label)

    Write-Host "  -h, --help      Show this help message"

    Write-Host "  -c, --config    Edit shortcuts and volumes"

    Write-Host ""
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function Show-VolScriptHelp
