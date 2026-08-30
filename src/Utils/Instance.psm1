$ErrorActionPreference = "Stop"


# Requires Config.psm1 imported by the caller.

Import-Module `
    "$PSScriptRoot\MenuInput.psm1"

# ============================================================
# State paths
# ============================================================

function Get-VolScriptStateDirectory
{
    $Path =
        Join-Path `
            $env:LOCALAPPDATA `
            "VolScript"

    if (-not (Test-Path $Path))
    {
        New-Item `
            -Path $Path `
            -ItemType Directory `
            -Force | Out-Null
    }

    return $Path
}


function Get-VolScriptRunningInstancesPath
{
    return Join-Path `
        (Get-VolScriptStateDirectory) `
        "running.json"
}


function Get-VolScriptCommandPath
{
    return Join-Path `
        (Get-VolScriptStateDirectory) `
        "command.json"
}


function Get-VolScriptCommandTempPath
{
    return "$(Get-VolScriptCommandPath).tmp"
}


$Script:VolScriptInstanceCommandAction = @{
    ChangeTarget = "ChangeTarget"
}


# ============================================================
# Running instances
# ============================================================

function Get-VolScriptRunningInstances
{
    $Path = Get-VolScriptRunningInstancesPath

    if (-not (Test-Path $Path))
    {
        return @()
    }

    try
    {
        $Instances =
            Get-Content `
                -Path $Path `
                -Raw |
            ConvertFrom-Json
    }
    catch
    {
        return @()
    }

    if ($null -eq $Instances)
    {
        return @()
    }

    if ($Instances -isnot [System.Collections.IEnumerable] -or
        $Instances -is [string])
    {
        $Instances = @($Instances)
    }

    $Alive = @()

    foreach ($Instance in $Instances)
    {
        if ($null -eq $Instance.pid)
        {
            continue
        }

        $Process =
            Get-Process `
                -Id $Instance.pid `
                -ErrorAction SilentlyContinue

        if ($null -eq $Process)
        {
            continue
        }

        $Alive += $Instance
    }

    if ($Alive.Count -ne $Instances.Count)
    {
        Set-VolScriptRunningInstances `
            -Instances $Alive
    }

    return @($Alive)
}


function Set-VolScriptRunningInstances
{
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Instances
    )

    if ($null -eq $Instances -or $Instances.Count -eq 0)
    {
        $Path = Get-VolScriptRunningInstancesPath

        if (Test-Path $Path)
        {
            Remove-Item `
                -Path $Path `
                -Force
        }

        return
    }

    $Json =
        $Instances |
        ConvertTo-Json `
            -Depth 4

    Set-Content `
        -Path (Get-VolScriptRunningInstancesPath) `
        -Value $Json `
        -Encoding UTF8 `
        -NoNewline
}


function Register-VolScriptInstance
{
    param(
        [Parameter(Mandatory)]
        [int]$ProcessId,

        [Parameter(Mandatory)]
        [string]$ProcessName,

        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [object]$Shortcuts,

        [Parameter(Mandatory)]
        [bool]$IsPrimary
    )

    $Instances = @(
        @(Get-VolScriptRunningInstances) |
        Where-Object { $_.pid -ne $ProcessId }
    )

    $Instances += [PSCustomObject]@{
        pid         = $ProcessId
        processName = $ProcessName
        configPath  = $ConfigPath
        isPrimary   = $IsPrimary
        shortcuts   = [PSCustomObject]@{
            volume50  = [string]$Shortcuts.Volume50
            volume100 = [string]$Shortcuts.Volume100
            exit      = [string]$Shortcuts.Exit
        }
    }

    Set-VolScriptRunningInstances `
        -Instances $Instances
}


function Unregister-VolScriptInstance
{
    param(
        [Parameter(Mandatory)]
        [int]$ProcessId
    )

    $Instances = @(
        @(Get-VolScriptRunningInstances) |
        Where-Object { $_.pid -ne $ProcessId }
    )

    Set-VolScriptRunningInstances `
        -Instances $Instances
}


# ============================================================
# Shortcut conflicts
# ============================================================

function Test-VolScriptShortcutConflict
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ShortcutsA,

        [Parameter(Mandatory)]
        [string[]]$ShortcutsB
    )

    foreach ($Shortcut in $ShortcutsA)
    {
        if ($ShortcutsB -contains $Shortcut)
        {
            return $true
        }
    }

    return $false
}


function Test-VolScriptShortcutsConflictWithRunning
{
    param(
        [Parameter(Mandatory)]
        [string[]]$Shortcuts,

        [int]$ExcludeProcessId = -1
    )

    foreach ($Instance in Get-VolScriptRunningInstances)
    {
        if (
            $ExcludeProcessId -ge 0 -and
            $Instance.pid -eq $ExcludeProcessId
        )
        {
            continue
        }

        $Other = @(
            [string]$Instance.shortcuts.volume50
            [string]$Instance.shortcuts.volume100
            [string]$Instance.shortcuts.exit
        )

        if (Test-VolScriptShortcutConflict `
            -ShortcutsA $Shortcuts `
            -ShortcutsB $Other)
        {
            return $true
        }
    }

    return $false
}


# ============================================================
# IPC
# ============================================================

function Send-VolScriptInstanceCommand
{
    param(
        [Parameter(Mandatory)]
        [int]$TargetProcessId,

        [Parameter(Mandatory)]
        [ValidateSet("ChangeTarget")]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    $Payload = [PSCustomObject]@{
        targetPid   = $TargetProcessId
        action      = $Script:VolScriptInstanceCommandAction[$Action]
        processName = $ProcessName
        createdAt   = (Get-Date).ToString("o")
    }

    $Path = Get-VolScriptCommandPath
    $TempPath = Get-VolScriptCommandTempPath

    if (Test-Path $TempPath)
    {
        Remove-Item `
            -Path $TempPath `
            -Force
    }

    Set-Content `
        -Path $TempPath `
        -Value ($Payload | ConvertTo-Json) `
        -Encoding UTF8 `
        -NoNewline

    Move-Item `
        -Path $TempPath `
        -Destination $Path `
        -Force
}


function Receive-VolScriptInstanceCommand
{
    param(
        [Parameter(Mandatory)]
        [int]$ProcessId
    )

    $Path = Get-VolScriptCommandPath

    if (-not (Test-Path $Path))
    {
        return $null
    }

    try
    {
        $Command =
            Get-Content `
                -Path $Path `
                -Raw |
            ConvertFrom-Json
    }
    catch
    {
        Remove-Item `
            -Path $Path `
            -Force `
            -ErrorAction SilentlyContinue

        return $null
    }

    if ($Command.targetPid -ne $ProcessId)
    {
        return $null
    }

    Remove-Item `
        -Path $Path `
        -Force

    return $Command
}


# ============================================================
# Prompt
# ============================================================

function Read-VolScriptInstancePromptChoice
{
    param(
        [Parameter(Mandatory)]
        [string]$CurrentTarget,

        [Parameter(Mandatory)]
        [string]$RequestedProcess
    )

    Write-Host ""
    Write-Host "  VolScript is already running." `
        -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Current target: $CurrentTarget" `
        -ForegroundColor DarkGray
    Write-Host "  Requested:      $RequestedProcess" `
        -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [1] Change target to $RequestedProcess" `
        -ForegroundColor Cyan
    Write-Host "  [2] New instance (separate shortcuts)" `
        -ForegroundColor Cyan
    Write-Host "  [3] Cancel" `
        -ForegroundColor Cyan
    Write-Host ""

    $Choice =
        Read-VolScriptMenuChoice `
            -ValidChoices @("1", "2", "3")

    switch ($Choice)
    {
        "1" { return "ChangeTarget" }
        "2" { return "NewInstance" }
        "3" { return "Cancel" }
    }
}


function Show-VolScriptInstancePrompt
{
    param(
        [Parameter(Mandatory)]
        [string]$CurrentTarget,

        [Parameter(Mandatory)]
        [string]$RequestedProcess,

        [switch]$Quiet
    )

    if ($Quiet)
    {
        Add-Type `
            -AssemblyName System.Windows.Forms `
            -ErrorAction Stop

        $Message =
            "VolScript is already running (target: $CurrentTarget).`n`n" +
            "Yes = Change target to $RequestedProcess`n" +
            "No = New instance with separate shortcuts`n" +
            "Cancel = Do nothing"

        $Result =
            [System.Windows.Forms.MessageBox]::Show(
                $Message,
                "VolScript",
                [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
                [System.Windows.Forms.MessageBoxIcon]::Question)

        switch ($Result)
        {
            ([System.Windows.Forms.DialogResult]::Yes)
            {
                return "ChangeTarget"
            }

            ([System.Windows.Forms.DialogResult]::No)
            {
                return "NewInstance"
            }

            default
            {
                return "Cancel"
            }
        }
    }

    return Read-VolScriptInstancePromptChoice `
        -CurrentTarget $CurrentTarget `
        -RequestedProcess $RequestedProcess
}


function Show-VolScriptInstanceMessage
{
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [switch]$Quiet
    )

    if ($Quiet)
    {
        Add-Type `
            -AssemblyName System.Windows.Forms `
            -ErrorAction Stop

        [System.Windows.Forms.MessageBox]::Show(
            $Message,
            "VolScript",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information) |
            Out-Null

        return
    }

    Write-Host ""
    Write-Host "  $Message" `
        -ForegroundColor Yellow
    Write-Host ""
}


# ============================================================
# Startup resolution
# ============================================================

function Resolve-VolScriptStartup
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,

        [switch]$Quiet
    )

    if ($ProcessName.EndsWith(".exe", [StringComparison]::OrdinalIgnoreCase))
    {
        $ProcessName =
            $ProcessName.Substring(
                0,
                $ProcessName.Length - 4)
    }

    $Running =
        @(Get-VolScriptRunningInstances)

    $SameProcessRunning = @(
        $Running |
        Where-Object {
            $_.processName.Equals(
                $ProcessName,
                [StringComparison]::OrdinalIgnoreCase)
        }
    )

    if ($SameProcessRunning.Count -gt 0)
    {
        Show-VolScriptInstanceMessage `
            -Message "VolScript is already running for $ProcessName." `
            -Quiet:$Quiet

        return [PSCustomObject]@{
            Action = "Cancel"
        }
    }

    $ProfilePath =
        Get-VolScriptProcessConfigPath `
            -ProcessName $ProcessName

    $ProfileRunning = @(
        $Running |
        Where-Object {
            $_.configPath -eq $ProfilePath
        }
    )

    if ($ProfileRunning.Count -gt 0)
    {
        Show-VolScriptInstanceMessage `
            -Message "VolScript is already running for $ProcessName." `
            -Quiet:$Quiet

        return [PSCustomObject]@{
            Action = "Cancel"
        }
    }

    $PrimaryRunning = @(
        $Running |
        Where-Object { $_.isPrimary }
    )

    if ($PrimaryRunning.Count -gt 0)
    {
        $Primary = $PrimaryRunning[0]

        $Choice =
            Show-VolScriptInstancePrompt `
                -CurrentTarget $Primary.processName `
                -RequestedProcess $ProcessName `
                -Quiet:$Quiet

        switch ($Choice)
        {
            "ChangeTarget"
            {
                Send-VolScriptInstanceCommand `
                    -TargetProcessId $Primary.pid `
                    -Action "ChangeTarget" `
                    -ProcessName $ProcessName

                Show-VolScriptInstanceMessage `
                    -Message "Target change sent to the running instance." `
                    -Quiet:$Quiet

                return [PSCustomObject]@{
                    Action = "Cancel"
                }
            }

            "NewInstance"
            {
                $CreatedPath =
                    Initialize-VolScriptProcessConfig `
                        -ProcessName $ProcessName

                $Config =
                    Get-VolScriptConfig `
                        -ConfigPath $CreatedPath

                $Shortcuts =
                    Get-VolScriptShortcutList `
                        -Config $Config

                if (Test-VolScriptShortcutsConflictWithRunning `
                    -Shortcuts $Shortcuts)
                {
                    Show-VolScriptInstanceMessage `
                        -Message "Shortcut conflict detected. Edit config\$(Split-Path $CreatedPath -Leaf) with -c and assign unique shortcuts." `
                        -Quiet:$Quiet

                    return [PSCustomObject]@{
                        Action = "Cancel"
                    }
                }

                return [PSCustomObject]@{
                    Action      = "Start"
                    ProcessName = $ProcessName
                    ConfigPath  = $CreatedPath
                    IsPrimary   = $false
                }
            }

            default
            {
                return [PSCustomObject]@{
                    Action = "Cancel"
                }
            }
        }
    }

    if (Test-Path $ProfilePath)
    {
        $Config =
            Get-VolScriptConfig `
                -ConfigPath $ProfilePath

        $Shortcuts =
            Get-VolScriptShortcutList `
                -Config $Config

        if (Test-VolScriptShortcutsConflictWithRunning `
            -Shortcuts $Shortcuts)
        {
            Show-VolScriptInstanceMessage `
                -Message "Shortcut conflict with a running instance. Edit $(Split-Path $ProfilePath -Leaf) before starting." `
                -Quiet:$Quiet

            return [PSCustomObject]@{
                Action = "Cancel"
            }
        }

        return [PSCustomObject]@{
            Action      = "Start"
            ProcessName = $ProcessName
            ConfigPath  = $ProfilePath
            IsPrimary   = $false
        }
    }

    $DefaultPath = Get-VolScriptDefaultConfigPath

    $Config =
        Get-VolScriptConfig `
            -ConfigPath $DefaultPath

    $Shortcuts =
        Get-VolScriptShortcutList `
            -Config $Config

    if (Test-VolScriptShortcutsConflictWithRunning `
        -Shortcuts $Shortcuts)
    {
        Show-VolScriptInstanceMessage `
            -Message "Default shortcuts conflict with a running instance. Create a profile config or stop the other instance." `
            -Quiet:$Quiet

        return [PSCustomObject]@{
            Action = "Cancel"
        }
    }

    return [PSCustomObject]@{
        Action      = "Start"
        ProcessName = $ProcessName
        ConfigPath  = $DefaultPath
        IsPrimary   = $true
    }
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    Get-VolScriptRunningInstances, `
    Register-VolScriptInstance, `
    Unregister-VolScriptInstance, `
    Test-VolScriptShortcutConflict, `
    Test-VolScriptShortcutsConflictWithRunning, `
    Send-VolScriptInstanceCommand, `
    Receive-VolScriptInstanceCommand, `
    Resolve-VolScriptStartup
