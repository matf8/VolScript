$ErrorActionPreference = "Stop"


# ============================================================
# Get target process
# ============================================================

function Get-VolScriptTargetProcess
{
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    if ($ProcessName.EndsWith(".exe"))
    {
        $ProcessName = $ProcessName.Substring(
            0,
            $ProcessName.Length - 4
        )
    }

    return Get-Process `
        -Name $ProcessName `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}


# ============================================================
# Start process monitor
# ============================================================

function Start-VolScriptProcessMonitor
{
    param(
        [Parameter(Mandatory)]
        [System.Diagnostics.Process]$Process,

        [Parameter(Mandatory)]
        [scriptblock]$OnExit
    )

    $Process.EnableRaisingEvents = $true

    return Register-ObjectEvent `
        -InputObject $Process `
        -EventName Exited `
        -Action $OnExit
}


# ============================================================
# Stop process monitor
# ============================================================

function Stop-VolScriptProcessMonitor
{
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PSEventJob]$Subscription
    )

    Unregister-Event `
        -SubscriptionId $Subscription.Id `
        -ErrorAction SilentlyContinue

    Remove-Job `
        -Id $Subscription.Id `
        -Force `
        -ErrorAction SilentlyContinue
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    Get-VolScriptTargetProcess, `
    Start-VolScriptProcessMonitor, `
    Stop-VolScriptProcessMonitor
