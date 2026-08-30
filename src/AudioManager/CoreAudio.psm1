$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\..\Core\Core.psm1"


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
