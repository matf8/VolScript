param(
    [Parameter(Mandatory)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

$RepoRoot =
    (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$StageRoot =
    Join-Path `
        ([System.IO.Path]::GetTempPath()) `
        ("VolScript-v{0}-{1}" -f $Version, [guid]::NewGuid().ToString("N").Substring(0, 8))

$StageDir =
    Join-Path $StageRoot "VolScript"

$DistDir =
    Join-Path $RepoRoot "dist"

$ZipPath =
    Join-Path $DistDir ("VolScript-v{0}.zip" -f $Version)

$IncludePaths = @(
    "VolScript.ps1"
    "LICENSE"
    "README.md"
    "config\config.json"
    "assets\VolScript.ico"
    "assets\VolScript.png"
    "scripts\Launch-Quiet.vbs"
    "scripts\New-Shortcut.ps1"
    "src"
)

try
{
    New-Item `
        -Path $StageDir `
        -ItemType Directory `
        -Force | Out-Null

    foreach ($RelativePath in $IncludePaths)
    {
        $Source =
            Join-Path $RepoRoot $RelativePath

        if (-not (Test-Path $Source))
        {
            throw "Release file not found: $RelativePath"
        }

        $Destination =
            Join-Path $StageDir $RelativePath

        $DestinationParent =
            Split-Path $Destination -Parent

        if (-not (Test-Path $DestinationParent))
        {
            New-Item `
                -Path $DestinationParent `
                -ItemType Directory `
                -Force | Out-Null
        }

        if (Test-Path $Source -PathType Container)
        {
            Copy-Item `
                -Path $Source `
                -Destination $Destination `
                -Recurse `
                -Force
        }
        else
        {
            Copy-Item `
                -Path $Source `
                -Destination $Destination `
                -Force
        }
    }

    if (-not (Test-Path $DistDir))
    {
        New-Item `
            -Path $DistDir `
            -ItemType Directory `
            -Force | Out-Null
    }

    if (Test-Path $ZipPath)
    {
        Remove-Item `
            -Path $ZipPath `
            -Force
    }

    Compress-Archive `
        -Path (Join-Path $StageDir "*") `
        -DestinationPath $ZipPath `
        -Force

    $Hash =
        Get-FileHash `
            -Path $ZipPath `
            -Algorithm SHA256

    Write-Host ""
    Write-Host "Release archive created:"
    Write-Host "  $ZipPath"
    Write-Host ""
    Write-Host "SHA256:"
    Write-Host "  $($Hash.Hash)"
    Write-Host ""
}
finally
{
    if (Test-Path $StageRoot)
    {
        Remove-Item `
            -Path $StageRoot `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}
