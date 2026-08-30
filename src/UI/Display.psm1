$ErrorActionPreference = "Stop"


# ============================================================
# Header
# ============================================================

function Show-VolScriptHeader
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [string]$Volume50Key,

        [Parameter(Mandatory)]
        [string]$Volume100Key,

        [Parameter(Mandatory)]
        [string]$ExitKey
    )

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

    Write-Host "  Target" `
        -ForegroundColor DarkGray

    Write-Host "  * " `
        -ForegroundColor Green `
        -NoNewline

    Write-Host "$ProcessName.exe"

    Write-Host ""

    Write-Host "  Shortcuts" `
        -ForegroundColor DarkGray

    Write-Host "  $Volume50Key" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host "   = 15%"

    Write-Host "  $Volume100Key" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host "   = 100%"

    Write-Host "  $ExitKey" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host "      = Exit"

    Write-Host ""

    Write-Host "  Status" `
        -ForegroundColor DarkGray

    Write-Host "  * " `
        -ForegroundColor Green `
        -NoNewline

    Write-Host "Running"

    Write-Host ""
}


# ============================================================
# Volume
# ============================================================

function Show-VolumeChange
{
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [int]$Volume
    )

    Write-Host ""

    Write-Host "  $Key" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host `
        " -> $ProcessName $Volume%"
}


# ============================================================
# Error
# ============================================================

function Show-Error
{
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host ""

    Write-Host "  ERROR: $Message" `
        -ForegroundColor Red

    Write-Host ""
}


# ============================================================
# Exit
# ============================================================

function Show-Exit
{
    Write-Host ""

    Write-Host "  ESC" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host " -> Exiting..." `
        -ForegroundColor Yellow

    Write-Host ""
}


# ============================================================
# Waiting for process
# ============================================================

function Show-WaitingForProcess
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [string]$ExitKey
    )

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

    Write-Host "  Target" `
        -ForegroundColor DarkGray

    Write-Host "  * " `
        -ForegroundColor Yellow `
        -NoNewline

    Write-Host "$ProcessName.exe"

    Write-Host ""

    Write-Host "  Shortcuts" `
        -ForegroundColor DarkGray

    Write-Host "  $ExitKey" `
        -ForegroundColor Cyan `
        -NoNewline

    Write-Host "      = Exit"

    Write-Host ""

    Write-Host "  Status" `
        -ForegroundColor DarkGray

    Write-Host "  * " `
        -ForegroundColor Yellow `
        -NoNewline

    Write-Host "Waiting for process..."

    Write-Host ""
}


# ============================================================
# Process terminated
# ============================================================

function Show-ProcessTerminated
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    Write-Host ""

    Write-Host "  * " `
        -ForegroundColor Yellow `
        -NoNewline

    Write-Host "$ProcessName.exe terminated."

    Write-Host "  Returning to standby..." `
        -ForegroundColor DarkGray

    Write-Host ""
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    Show-VolScriptHeader, `
    Show-WaitingForProcess, `
    Show-VolumeChange, `
    Show-Error, `
    Show-Exit, `
    Show-ProcessTerminated
