$ErrorActionPreference = "Stop"


# ============================================================
# Help
# ============================================================

function Show-VolScriptHelp
{
    Write-Host ""

    Write-Host "+------------------------------------------+" `
        -ForegroundColor Cyan

    Write-Host "|                 VolScript                |" `
        -ForegroundColor Cyan

    Write-Host "|             Audio Controller             |" `
        -ForegroundColor Cyan

    Write-Host "+------------------------------------------+" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-Host "Usage" `
        -ForegroundColor DarkGray

    Write-Host "  .\VolScript.ps1 <process>"

    Write-Host ""

    Write-Host "Example" `
        -ForegroundColor DarkGray

    Write-Host "  .\VolScript.ps1 spotify"

    Write-Host ""

    Write-Host "Options" `
        -ForegroundColor DarkGray

    Write-Host "  -h, --help      Show this help message"

    Write-Host "  -c, --config    Edit shortcuts and volumes"

    Write-Host ""
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function Show-VolScriptHelp
