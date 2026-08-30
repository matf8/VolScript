$ErrorActionPreference = "Stop"


# ============================================================
# Dependencies
# ============================================================

Import-Module `
    "$PSScriptRoot\..\Config\Config.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\..\AudioManager\AudioManager.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\..\HotKeys\HotKeys.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\..\UI\Display.psm1" `
    -Force

Import-Module `
    "$PSScriptRoot\..\Utils\ProcessLifecycle.psm1" `
    -Force


# ============================================================
# Start VolScript
# ============================================================

function Start-VolScript
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [switch]$Quiet
    )


    # ========================================================
    # Configuration
    # ========================================================

    $Config =
        Get-VolScriptConfig

    $Volume50Pct =
        [int]($Config.Volumes.Volume50 * 100)

    $Volume100Pct =
        [int]($Config.Volumes.Volume100 * 100)

    Initialize-VolScriptOutputMode `
        -Quiet:$Quiet

    if ($Quiet)
    {
        Import-Module `
            "$PSScriptRoot\..\UI\Tray.psm1" `
            -Force

        Start-VolScriptTray `
            -ProcessName $ProcessName `
            -ExitKey $Config.Shortcuts.Exit `
            -HideConsole
    }

    try
    {

    # ========================================================
    # Lifecycle loop
    # ========================================================

    while ($true)
    {

        # ====================================================
        # Standby: wait for target process
        # ====================================================

        if (-not $Quiet)
        {
            Clear-Host

            Initialize-VolScriptStandbyDashboard `
                -ProcessName $ProcessName `
                -Volume50Key $Config.Shortcuts.Volume50 `
                -Volume100Key $Config.Shortcuts.Volume100 `
                -ExitKey $Config.Shortcuts.Exit `
                -Volume50Pct $Volume50Pct `
                -Volume100Pct $Volume100Pct
        }
        else
        {
            Update-VolScriptTray `
                -ProcessName $ProcessName `
                -Status "waiting"
        }

        Start-VolScriptHotkeys `
            -Volume50Key $Config.Shortcuts.Volume50 `
            -Volume100Key $Config.Shortcuts.Volume100 `
            -ExitKey $Config.Shortcuts.Exit

        $TargetProcess = $null

        while ($null -eq $TargetProcess)
        {
            if (-not $Quiet)
            {
                Update-VolScriptStandbySpinner `
                    -ProcessName $ProcessName
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

            if ($Action -eq 3)
            {
                if (-not $Quiet)
                {
                    Show-Exit `
                        -ExitKey $Config.Shortcuts.Exit
                }

                Stop-VolScriptHotkeys

                return
            }

            $TargetProcess =
                Get-VolScriptTargetProcess `
                    -ProcessName $ProcessName

            Start-Sleep `
                -Milliseconds 250
        }

        $TargetPid = $TargetProcess.Id


        # ====================================================
        # Active: process is running
        # ====================================================

        $CurrentVolumePct = -1

        try
        {
            $CurrentVolumePct =
                [int](
                    (Get-TargetAudioVolume `
                        -ProcessName $ProcessName) * 100
                )
        }
        catch
        {
            $CurrentVolumePct = -1
        }

        if (-not $Quiet)
        {
            Clear-Host

            Initialize-VolScriptActiveDashboard `
                -ProcessName $ProcessName `
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
                -ProcessName $ProcessName `
                -Status "active" `
                -VolumePercent $CurrentVolumePct
        }


        # ====================================================
        # Main loop
        # ====================================================

        while ($true)
        {

            # ==================================================
            # Check target process
            # ==================================================

            $ProcessStillRunning =
                Get-Process `
                    -Id $TargetPid `
                    -ErrorAction SilentlyContinue

            if ($null -eq $ProcessStillRunning)
            {
                if (-not $Quiet)
                {
                    Show-ProcessTerminated `
                        -ProcessName $ProcessName
                }
                else
                {
                    Update-VolScriptTray `
                        -ProcessName $ProcessName `
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


            # ==================================================
            # Check hotkey
            # ==================================================

            $Action =
                Get-VolScriptHotkeyAction


            switch ($Action)
            {

                # ==============================================
                # Volume 50
                # ==============================================

                1
                {
                    try
                    {
                        Set-TargetAudioVolume `
                            -ProcessName $ProcessName `
                            -Volume $Config.Volumes.Volume50

                        $ActualVolume =
                            [int](
                                (Get-TargetAudioVolume `
                                    -ProcessName $ProcessName) * 100
                            )

                        if ($Quiet)
                        {
                            Update-VolScriptTray `
                                -ProcessName $ProcessName `
                                -Status "active" `
                                -VolumePercent $ActualVolume
                        }
                        else
                        {
                            Show-VolumeChange `
                                -Key $Config.Shortcuts.Volume50 `
                                -ProcessName $ProcessName `
                                -Volume $ActualVolume
                        }
                    }
                    catch
                    {
                        $Message =
                            $_.Exception.InnerException.Message

                        if ([string]::IsNullOrWhiteSpace($Message))
                        {
                            $Message =
                                $_.Exception.Message
                        }

                        Show-Error `
                            -Message $Message
                    }
                }


                # ==============================================
                # Volume 100
                # ==============================================

                2
                {
                    try
                    {
                        Set-TargetAudioVolume `
                            -ProcessName $ProcessName `
                            -Volume $Config.Volumes.Volume100

                        $ActualVolume =
                            [int](
                                (Get-TargetAudioVolume `
                                    -ProcessName $ProcessName) * 100
                            )

                        if ($Quiet)
                        {
                            Update-VolScriptTray `
                                -ProcessName $ProcessName `
                                -Status "active" `
                                -VolumePercent $ActualVolume
                        }
                        else
                        {
                            Show-VolumeChange `
                                -Key $Config.Shortcuts.Volume100 `
                                -ProcessName $ProcessName `
                                -Volume $ActualVolume
                        }
                    }
                    catch
                    {
                        $Message =
                            $_.Exception.InnerException.Message

                        if ([string]::IsNullOrWhiteSpace($Message))
                        {
                            $Message =
                                $_.Exception.Message
                        }

                        Show-Error `
                            -Message $Message
                    }
                }


                # ==============================================
                # Exit
                # ==============================================

                3
                {
                    if (-not $Quiet)
                    {
                        Show-Exit `
                            -ExitKey $Config.Shortcuts.Exit
                    }

                    Stop-VolScriptHotkeys

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
