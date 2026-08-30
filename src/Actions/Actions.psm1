$ErrorActionPreference = "Stop"


# ============================================================
# Dependencies
# ============================================================
# Requires Config.psm1 and Instance.psm1 imported by the caller.

Import-Module `
    "$PSScriptRoot\..\AudioManager\AudioManager.psm1"

Import-Module `
    "$PSScriptRoot\..\HotKeys\HotKeys.psm1"

Import-Module `
    "$PSScriptRoot\..\UI\Display.psm1"

Import-Module `
    "$PSScriptRoot\..\Utils\ProcessLifecycle.psm1"


# ============================================================
# Instance helpers
# ============================================================

function Update-VolScriptInstanceRegistration
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [object]$Config,

        [Parameter(Mandatory)]
        [bool]$IsPrimary
    )

    Register-VolScriptInstance `
        -ProcessId $PID `
        -ProcessName $ProcessName `
        -ConfigPath $ConfigPath `
        -Shortcuts $Config.Shortcuts `
        -IsPrimary $IsPrimary
}


function Test-VolScriptTargetChangeRequested
{
    param(
        [Parameter(Mandatory)]
        [string]$TargetProcessName
    )

    $Command =
        Receive-VolScriptInstanceCommand `
            -ProcessId $PID

    if ($null -eq $Command)
    {
        return $null
    }

    if ($Command.action -ne "ChangeTarget")
    {
        return $null
    }

    $NewTarget = [string]$Command.processName

    if ([string]::IsNullOrWhiteSpace($NewTarget))
    {
        return $null
    }

    if ($NewTarget -eq $TargetProcessName)
    {
        return $null
    }

    return $NewTarget
}


function Apply-VolScriptTargetChange
{
    param(
        [Parameter(Mandatory)]
        [string]$NewTarget,

        [Parameter(Mandatory)]
        [object]$Config,

        [Parameter(Mandatory)]
        [bool]$IsPrimary,

        [switch]$Quiet,

        [switch]$UpdateTrayWaiting
    )

    Stop-VolScriptHotkeys

    Update-VolScriptInstanceRegistration `
        -ProcessName $NewTarget `
        -ConfigPath $Config.ConfigPath `
        -Config $Config `
        -IsPrimary $IsPrimary

    if ($Quiet -and $UpdateTrayWaiting)
    {
        Update-VolScriptTray `
            -ProcessName $NewTarget `
            -Status "waiting"
    }

    return $NewTarget
}


function Get-VolScriptActionErrorMessage
{
    param(
        [Parameter(Mandatory)]
        $ErrorRecord
    )

    $Message =
        $ErrorRecord.Exception.InnerException.Message

    if ([string]::IsNullOrWhiteSpace($Message))
    {
        $Message =
            $ErrorRecord.Exception.Message
    }

    return $Message
}


function Invoke-VolScriptVolumeAction
{
    param(
        [Parameter(Mandatory)]
        [string]$TargetProcessName,

        [Parameter(Mandatory)]
        [object]$Config,

        [Parameter(Mandatory)]
        [ValidateSet("Volume50", "Volume100")]
        [string]$Level,

        [switch]$Quiet
    )

    $Volume =
        if ($Level -eq "Volume50")
        {
            $Config.Volumes.Volume50
        }
        else
        {
            $Config.Volumes.Volume100
        }

    $ShortcutKey =
        if ($Level -eq "Volume50")
        {
            $Config.Shortcuts.Volume50
        }
        else
        {
            $Config.Shortcuts.Volume100
        }

    try
    {
        Set-TargetAudioVolume `
            -ProcessName $TargetProcessName `
            -Volume $Volume

        $ActualVolume =
            [int](
                (Get-TargetAudioVolume `
                    -ProcessName $TargetProcessName) * 100
            )

        if ($Quiet)
        {
            Update-VolScriptTray `
                -ProcessName $TargetProcessName `
                -Status "active" `
                -VolumePercent $ActualVolume
        }
        else
        {
            Show-VolumeChange `
                -Key $ShortcutKey `
                -ProcessName $TargetProcessName `
                -Volume $ActualVolume
        }
    }
    catch
    {
        Show-Error `
            -Message (Get-VolScriptActionErrorMessage -ErrorRecord $_)
    }
}


function Invoke-VolScriptExitAction
{
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [switch]$Quiet
    )

    if (-not $Quiet)
    {
        Show-Exit `
            -ExitKey $Config.Shortcuts.Exit
    }

    Stop-VolScriptHotkeys
}


# ============================================================
# Start VolScript
# ============================================================

function Start-VolScript
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [bool]$IsPrimary = $true,

        [switch]$Quiet
    )

    $TargetProcessName = $ProcessName

    $Config =
        Get-VolScriptConfig `
            -ConfigPath $ConfigPath

    $Volume50Pct =
        [int]($Config.Volumes.Volume50 * 100)

    $Volume100Pct =
        [int]($Config.Volumes.Volume100 * 100)

    Initialize-VolScriptOutputMode `
        -Quiet:$Quiet

    Update-VolScriptInstanceRegistration `
        -ProcessName $TargetProcessName `
        -ConfigPath $Config.ConfigPath `
        -Config $Config `
        -IsPrimary $IsPrimary

    if ($Quiet)
    {
        Start-VolScriptTray `
            -ProcessName $TargetProcessName `
            -ExitKey $Config.Shortcuts.Exit `
            -HideConsole
    }

    try
    {

    while ($true)
    {
        $TargetChange =
            Test-VolScriptTargetChangeRequested `
                -TargetProcessName $TargetProcessName

        if ($null -ne $TargetChange)
        {
            $TargetProcessName =
                Apply-VolScriptTargetChange `
                    -NewTarget $TargetChange `
                    -Config $Config `
                    -IsPrimary $IsPrimary `
                    -Quiet:$Quiet `
                    -UpdateTrayWaiting
        }

        if (-not $Quiet)
        {
            Clear-Host

            Initialize-VolScriptStandbyDashboard `
                -ProcessName $TargetProcessName `
                -Volume50Key $Config.Shortcuts.Volume50 `
                -Volume100Key $Config.Shortcuts.Volume100 `
                -ExitKey $Config.Shortcuts.Exit `
                -Volume50Pct $Volume50Pct `
                -Volume100Pct $Volume100Pct
        }
        else
        {
            Update-VolScriptTray `
                -ProcessName $TargetProcessName `
                -Status "waiting"
        }

        Start-VolScriptHotkeys `
            -Volume50Key $Config.Shortcuts.Volume50 `
            -Volume100Key $Config.Shortcuts.Volume100 `
            -ExitKey $Config.Shortcuts.Exit

        $TargetProcess = $null

        while ($null -eq $TargetProcess)
        {
            $TargetChange =
                Test-VolScriptTargetChangeRequested `
                    -TargetProcessName $TargetProcessName

            if ($null -ne $TargetChange)
            {
                $TargetProcessName =
                    Apply-VolScriptTargetChange `
                        -NewTarget $TargetChange `
                        -Config $Config `
                        -IsPrimary $IsPrimary `
                        -Quiet:$Quiet

                break
            }

            if (-not $Quiet)
            {
                Update-VolScriptStandbySpinner `
                    -ProcessName $TargetProcessName
            }

            if ($Quiet)
            {
                Invoke-VolScriptTrayPump
            }

            if (
                $Quiet -and
                (Test-VolScriptTrayExitRequested)
            )
            {
                Stop-VolScriptHotkeys

                return
            }

            $Action =
                Get-VolScriptHotkeyAction

            if ($Action -eq $VolScriptHotkeyAction.Exit)
            {
                Invoke-VolScriptExitAction `
                    -Config $Config `
                    -Quiet:$Quiet

                return
            }

            $TargetProcess =
                Get-VolScriptTargetProcess `
                    -ProcessName $TargetProcessName

            Start-Sleep `
                -Milliseconds 250
        }

        if ($null -eq $TargetProcess)
        {
            continue
        }

        $TargetPid = $TargetProcess.Id

        $CurrentVolumePct = -1

        try
        {
            $CurrentVolumePct =
                [int](
                    (Get-TargetAudioVolume `
                        -ProcessName $TargetProcessName) * 100
                )
        }
        catch
        {
            $CurrentVolumePct = -1
        }

        if (-not $Quiet)
        {
            Initialize-VolScriptActiveDashboard `
                -ProcessName $TargetProcessName `
                -Volume50Key $Config.Shortcuts.Volume50 `
                -Volume100Key $Config.Shortcuts.Volume100 `
                -ExitKey $Config.Shortcuts.Exit `
                -Volume50Pct $Volume50Pct `
                -Volume100Pct $Volume100Pct `
                -CurrentVolumePct $CurrentVolumePct
        }
        else
        {
            Update-VolScriptTray `
                -ProcessName $TargetProcessName `
                -Status "active" `
                -VolumePercent $CurrentVolumePct
        }

        while ($true)
        {
            $TargetChange =
                Test-VolScriptTargetChangeRequested `
                    -TargetProcessName $TargetProcessName

            if ($null -ne $TargetChange)
            {
                $TargetProcessName =
                    Apply-VolScriptTargetChange `
                        -NewTarget $TargetChange `
                        -Config $Config `
                        -IsPrimary $IsPrimary `
                        -Quiet:$Quiet

                break
            }

            $ProcessStillRunning =
                Get-Process `
                    -Id $TargetPid `
                    -ErrorAction SilentlyContinue

            if ($null -eq $ProcessStillRunning)
            {
                if (-not $Quiet)
                {
                    Show-ProcessTerminated `
                        -ProcessName $TargetProcessName
                }
                else
                {
                    Update-VolScriptTray `
                        -ProcessName $TargetProcessName `
                        -Status "waiting"
                }

                Stop-VolScriptHotkeys

                Start-Sleep `
                    -Milliseconds 1500

                break
            }

            if ($Quiet)
            {
                Invoke-VolScriptTrayPump
            }

            if (
                $Quiet -and
                (Test-VolScriptTrayExitRequested)
            )
            {
                Stop-VolScriptHotkeys

                return
            }

            $Action =
                Get-VolScriptHotkeyAction

            switch ($Action)
            {
                { $_ -eq $VolScriptHotkeyAction.Volume50 }
                {
                    Invoke-VolScriptVolumeAction `
                        -TargetProcessName $TargetProcessName `
                        -Config $Config `
                        -Level "Volume50" `
                        -Quiet:$Quiet
                }

                { $_ -eq $VolScriptHotkeyAction.Volume100 }
                {
                    Invoke-VolScriptVolumeAction `
                        -TargetProcessName $TargetProcessName `
                        -Config $Config `
                        -Level "Volume100" `
                        -Quiet:$Quiet
                }

                { $_ -eq $VolScriptHotkeyAction.Exit }
                {
                    Invoke-VolScriptExitAction `
                        -Config $Config `
                        -Quiet:$Quiet

                    return
                }
            }

            Start-Sleep `
                -Milliseconds 250
        }
    }

    }
    finally
    {
        Unregister-VolScriptInstance `
            -ProcessId $PID

        Clear-VolScriptActiveConfigPath

        if ($Quiet)
        {
            Stop-VolScriptTray
        }
    }
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function Start-VolScript
