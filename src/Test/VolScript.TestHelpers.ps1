function Get-TestVolScriptCommandPath
{
    return Join-Path `
        $env:LOCALAPPDATA `
        "VolScript\command.json"
}


function Backup-TestVolScriptCommandFile
{
    param(
        [ref]$Existed,

        [ref]$Backup
    )

    $Path = Get-TestVolScriptCommandPath

    $Existed.Value = Test-Path $Path

    if ($Existed.Value)
    {
        $Backup.Value = Get-Content -Path $Path -Raw
    }
}


function Restore-TestVolScriptCommandFile
{
    param(
        [bool]$Existed,

        [string]$Backup
    )

    $Path = Get-TestVolScriptCommandPath

    if ($Existed)
    {
        Set-Content `
            -Path $Path `
            -Value $Backup `
            -Encoding UTF8 `
            -NoNewline
    }
    elseif (Test-Path $Path)
    {
        Remove-Item -Path $Path -Force
    }
}


function New-TestVolScriptRunningInstance
{
    param(
        [int]$ProcessId = $PID,

        [string]$ProcessName = "spotify",

        [string]$ConfigPath = (Get-VolScriptDefaultConfigPath),

        [bool]$IsPrimary = $true,

        [string]$Volume50 = "ALT+SHIFT+P",

        [string]$Volume100 = "ALT+SHIFT+O",

        [string]$Exit = "ALT+SHIFT+Q"
    )

    return [PSCustomObject]@{
        pid         = $ProcessId
        processName = $ProcessName
        configPath  = $ConfigPath
        isPrimary   = $IsPrimary
        shortcuts   = [PSCustomObject]@{
            volume50  = $Volume50
            volume100 = $Volume100
            exit      = $Exit
        }
    }
}
