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
        [string]$ProcessName
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


    # ========================================================
    # Lifecycle loop
    # ========================================================

    while ($true)
    {

        # ====================================================
        # Standby: wait for target process
        # ====================================================

        Clear-Host

        Initialize-VolScriptStandbyDashboard `
            -ProcessName $ProcessName `
            -Volume50Key $Config.Shortcuts.Volume50 `
            -Volume100Key $Config.Shortcuts.Volume100 `
            -ExitKey $Config.Shortcuts.Exit `
            -Volume50Pct $Volume50Pct `
            -Volume100Pct $Volume100Pct

        Start-VolScriptHotkeys `
            -Volume50Key $Config.Shortcuts.Volume50 `
            -Volume100Key $Config.Shortcuts.Volume100 `
            -ExitKey $Config.Shortcuts.Exit

        $TargetProcess = $null

        while ($null -eq $TargetProcess)
        {
            Update-VolScriptStandbySpinner `
                -ProcessName $ProcessName

            $Action =
                Get-VolScriptHotkeyAction

            if ($Action -eq 3)
            {
                Show-Exit `
                    -ExitKey $Config.Shortcuts.Exit

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

        Clear-Host

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

        Initialize-VolScriptActiveDashboard `
            -ProcessName $ProcessName `
            -Volume50Key $Config.Shortcuts.Volume50 `
            -Volume100Key $Config.Shortcuts.Volume100 `
            -ExitKey $Config.Shortcuts.Exit `
            -Volume50Pct $Volume50Pct `
            -Volume100Pct $Volume100Pct `
            -CurrentVolumePct $CurrentVolumePct


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
                Show-ProcessTerminated `
                    -ProcessName $ProcessName

                Stop-VolScriptHotkeys

                Start-Sleep `
                    -Milliseconds 1500

                break
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

                        Show-VolumeChange `
                            -Key $Config.Shortcuts.Volume50 `
                            -ProcessName $ProcessName `
                            -Volume $ActualVolume
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

                        Show-VolumeChange `
                            -Key $Config.Shortcuts.Volume100 `
                            -ProcessName $ProcessName `
                            -Volume $ActualVolume
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
                    Show-Exit `
                        -ExitKey $Config.Shortcuts.Exit

                    Stop-VolScriptHotkeys

                    return
                }
            }


            Start-Sleep `
                -Milliseconds 250
        }
    }
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function Start-VolScript
