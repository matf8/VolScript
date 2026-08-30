$ErrorActionPreference = "Stop"


Import-Module `
    "$PSScriptRoot\HotKeysCore.psm1"


$Script:VolScriptHotkeyAction = [PSCustomObject]@{
    None      = 0
    Volume50  = 1
    Volume100 = 2
    Exit      = 3
}


Export-ModuleMember -Function `
    ConvertTo-VolScriptHotkey, `
    Test-VolScriptHotkey, `
    Read-VolScriptHotkeyCapture, `
    Start-VolScriptHotkeys, `
    Stop-VolScriptHotkeys, `
    Get-VolScriptHotkeyAction `
    -Variable VolScriptHotkeyAction
