$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\CoreAudio.psm1"

function Set-TargetAudioVolume {
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [ValidateRange(0.0, 1.0)]
        [float]$Volume
    )

    Set-ProcessAudioVolume `
        -ProcessName $ProcessName `
        -Volume $Volume
}

function Get-TargetAudioVolume {
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    return [VolScript.Audio.CoreAudio]::GetProcessVolume(
        $ProcessName
    )
}

Export-ModuleMember `
    -Function Set-TargetAudioVolume, Get-TargetAudioVolume
