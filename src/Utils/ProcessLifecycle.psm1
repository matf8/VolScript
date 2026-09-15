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
# Process image path
# ============================================================

function Test-VolScriptExistingImagePath
{
    param(
        [string]$Path
    )

    return (
        -not [string]::IsNullOrWhiteSpace($Path) -and
        (Test-Path -LiteralPath $Path)
    )
}


function Get-VolScriptCimProcessImagePath
{
    param(
        [Parameter(Mandatory)]
        [int]$ProcessId
    )

    $CimProcess = $null

    try
    {
        $CimProcess =
            Get-CimInstance `
                -ClassName Win32_Process `
                -Filter "ProcessId=$ProcessId" `
                -ErrorAction SilentlyContinue
    }
    catch
    {
        return $null
    }

    if ($null -eq $CimProcess)
    {
        return $null
    }

    $Path = [string]$CimProcess.ExecutablePath

    if (Test-VolScriptExistingImagePath -Path $Path)
    {
        return $Path
    }

    return $null
}


function Get-VolScriptProcessImagePath
{
    [CmdletBinding(DefaultParameterSetName = "ByProcess")]
    param(
        [Parameter(ParameterSetName = "ByProcess", Mandatory)]
        [System.Diagnostics.Process]$Process,

        [Parameter(ParameterSetName = "ByProcessId", Mandatory)]
        [int]$ProcessId
    )

    if ($PSCmdlet.ParameterSetName -eq "ByProcessId")
    {
        $Process =
            Get-Process `
                -Id $ProcessId `
                -ErrorAction SilentlyContinue
    }

    if ($null -ne $Process)
    {
        $Path = $null

        try
        {
            $Path = [string]$Process.Path
        }
        catch
        {
            $Path = $null
        }

        if (Test-VolScriptExistingImagePath -Path $Path)
        {
            return $Path
        }

        $ProcessId = $Process.Id
    }

    if ($ProcessId -le 0)
    {
        return $null
    }

    return Get-VolScriptCimProcessImagePath `
        -ProcessId $ProcessId
}


# ============================================================
# Export
# ============================================================

Export-ModuleMember -Function `
    Get-VolScriptTargetProcess, `
    Get-VolScriptProcessImagePath
