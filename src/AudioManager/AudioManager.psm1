$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\CoreAudio.psm1" -Force

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

Export-ModuleMember `
    -Function Set-TargetAudioVolume