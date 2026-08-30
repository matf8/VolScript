$ErrorActionPreference = "Stop"


Import-Module `
    "$PSScriptRoot\HotKeysCore.psm1" `
    -Force


Export-ModuleMember -Function `
    ConvertTo-VolScriptHotkey, `
    Test-VolScriptHotkey, `
    Read-VolScriptHotkeyCapture, `
    Start-VolScriptHotkeys, `
    Stop-VolScriptHotkeys, `
    Get-VolScriptHotkeyAction
