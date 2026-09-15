$ErrorActionPreference = "Stop"


Import-Module `
    "$PSScriptRoot\HotKeysCore.psm1"


$Script:VolScriptHotkeyAction = [PSCustomObject]@{
    None = 0
    Exit = -1
}


Export-ModuleMember -Function `
    ConvertTo-VolScriptHotkey, `
    Test-VolScriptHotkey, `
    Read-VolScriptHotkeyCapture, `
    Start-VolScriptHotkeys, `
    Stop-VolScriptHotkeys, `
    Get-VolScriptHotkeyAction, `
    Get-VolScriptHotkeyPresetId `
    -Variable VolScriptHotkeyAction
