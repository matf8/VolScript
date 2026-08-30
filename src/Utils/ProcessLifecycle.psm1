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
# Export
# ============================================================

Export-ModuleMember -Function Get-VolScriptTargetProcess
