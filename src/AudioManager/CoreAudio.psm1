$ErrorActionPreference = "Stop"


# ============================================================
# Load Core Audio
# ============================================================

if (-not ("VolScript.Audio.CoreAudio" -as [type]))
{
    $CoreAudioPath = Join-Path `
        $PSScriptRoot `
        "Core"

    $SourceFiles = @(
        "Constants.cs"
        "Guids.cs"
        "Interfaces.cs"
        "Com\Helpers.cs"
        "Com\Classes.cs"
        "Session.cs"
        "CoreAudio.cs"       
    )

    $UsingStatements = @(
        "using System;"
        "using System.ComponentModel;"
        "using System.Diagnostics;"
        "using System.Runtime.InteropServices;"
    )

    $Source = @()

    $Source += $UsingStatements
    $Source += ""

    foreach ($File in $SourceFiles)
    {
        $FilePath = Join-Path `
            $CoreAudioPath `
            $File

        $Content = Get-Content `
            $FilePath `
            -Raw

        $Content = [regex]::Replace(
            $Content,
            '(?m)^[ \t]*using\s+[^;]+;\s*\r?\n',
            ''
        )

        $Source += $Content
        $Source += ""
    }

    Add-Type `
        -TypeDefinition ($Source -join "`n")
}


# ============================================================
# Set process volume
# ============================================================

function Set-ProcessAudioVolume
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [ValidateRange(0.0, 1.0)]
        [float]$Volume
    )

    [VolScript.Audio.CoreAudio]::SetProcessVolume(
        $ProcessName,
        $Volume
    )
}


function Get-ProcessAudioVolume
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    return [VolScript.Audio.CoreAudio]::GetProcessVolume(
        $ProcessName
    )
}


Export-ModuleMember -Function `
    Set-ProcessAudioVolume, `
    Get-ProcessAudioVolume