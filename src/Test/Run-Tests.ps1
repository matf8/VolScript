$ErrorActionPreference = "Stop"

if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Pester not found. Install it with:"
    Write-Host "  Install-Module Pester -Force -SkipPublisherCheck -Scope CurrentUser"
    exit 1
}

Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Write-Host ""
Write-Host "Running VolScript tests..."
Write-Host ""

$Result =
    Invoke-Pester `
        -Path (Join-Path $PSScriptRoot "VolScript.Tests.ps1") `
        -Output Detailed `
        -PassThru

Write-Host ""
Write-Host "Passed: $($Result.PassedCount)  Failed: $($Result.FailedCount)  Total: $($Result.TotalCount)"

if ($Result.FailedCount -gt 0) {
    exit 1
}

exit 0
