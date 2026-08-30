$ErrorActionPreference = "Stop"

$script:ProjectRoot =
    (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

$script:SrcRoot =
    Join-Path $script:ProjectRoot "src"

Import-Module (Join-Path $script:SrcRoot "HotKeys\HotKeys.psm1") -Force
Import-Module (Join-Path $script:SrcRoot "Config\Config.psm1") -Force
Import-Module (Join-Path $script:SrcRoot "Utils\ArgValidate.psm1") -Force
Import-Module (Join-Path $script:SrcRoot "Utils\ProcessLifecycle.psm1") -Force


Describe "Module loading" {
    It "loads HotKeys C# types" {
        [VolScript.VolScriptHotKeys] | Should -Not -BeNullOrEmpty
        [VolScript.VolScriptHotkeyCapture] | Should -Not -BeNullOrEmpty
    }

    It "exports core commands" {
        Get-Command ConvertTo-VolScriptHotkey | Should -Not -BeNullOrEmpty
        Get-Command Start-VolScriptHotkeys | Should -Not -BeNullOrEmpty
        Get-Command Get-VolScriptConfig | Should -Not -BeNullOrEmpty
        Get-Command Get-VolScriptTargetProcess | Should -Not -BeNullOrEmpty
    }
}


Describe "ConvertTo-VolScriptHotkey" {
    It "parses a single key" {
        $Result = ConvertTo-VolScriptHotkey -Hotkey "Q"

        $Result.Key | Should -Be 0x51
        $Result.Modifier | Should -Be 0
    }

    It "parses CTRL+ALT combinations" {
        $Result = ConvertTo-VolScriptHotkey -Hotkey "CTRL+ALT+F1"

        $Result.Key | Should -Be 0x70
        $Result.Modifier | Should -Be 6
    }

    It "accepts CONTROL as an alias for CTRL" {
        $Result = ConvertTo-VolScriptHotkey -Hotkey "CONTROL+SHIFT+K"

        $Result.Key | Should -Be 0x4B
        $Result.Modifier | Should -Be 3
    }

    It "parses function keys" {
        $Result = ConvertTo-VolScriptHotkey -Hotkey "F12"

        $Result.Key | Should -Be 0x7B
        $Result.Modifier | Should -Be 0
    }

    It "throws for unsupported keys" {
        { ConvertTo-VolScriptHotkey -Hotkey "CTRL+HOME" } |
            Should -Throw "*Unsupported hotkey key*"
    }

    It "throws when no key is provided" {
        { ConvertTo-VolScriptHotkey -Hotkey "CTRL" } |
            Should -Throw "*Invalid hotkey*"
    }
}


Describe "Test-VolScriptHotkey" {
    It "returns true for valid shortcuts" {
        Test-VolScriptHotkey -Hotkey "ALT+SHIFT+P" | Should -Be $true
    }

    It "returns false for invalid shortcuts" {
        Test-VolScriptHotkey -Hotkey "CTRL+NOTAKEY" | Should -Be $false
    }
}


Describe "Get-VolScriptConfig" {
    It "loads and normalizes config.json" {
        $Config = Get-VolScriptConfig

        $Config.Shortcuts.Volume50 | Should -Be "ALT+SHIFT+P"
        $Config.Shortcuts.Volume100 | Should -Be "ALT+SHIFT+O"
        $Config.Shortcuts.Exit | Should -Be "ALT+SHIFT+Q"
        $Config.Volumes.Volume50 | Should -Be ([float]0.15)
        $Config.Volumes.Volume100 | Should -Be ([float]1.0)
    }

    It "maps shortcuts to valid hotkeys" {
        $Config = Get-VolScriptConfig

        Test-VolScriptHotkey -Hotkey $Config.Shortcuts.Volume50 |
            Should -Be $true
        Test-VolScriptHotkey -Hotkey $Config.Shortcuts.Volume100 |
            Should -Be $true
        Test-VolScriptHotkey -Hotkey $Config.Shortcuts.Exit |
            Should -Be $true
    }
}


Describe "Save-VolScriptConfig" {
    BeforeAll {
        $ConfigPath = Get-VolScriptConfigPath
        $script:ConfigBackup = Get-Content -Path $ConfigPath -Raw
    }

    AfterAll {
        Set-Content `
            -Path (Get-VolScriptConfigPath) `
            -Value $script:ConfigBackup `
            -Encoding UTF8 `
            -NoNewline
    }

    It "writes readable JSON with tabs" {
        $Config =
            Get-Content -Path (Get-VolScriptConfigPath) -Raw |
            ConvertFrom-Json

        Save-VolScriptConfig -Config $Config

        $Saved = Get-Content -Path (Get-VolScriptConfigPath) -Raw

        $Saved | Should -Match "`"shortcuts`":"
        $Saved | Should -Match "`"volumes`":"
        $Saved | Should -Not -Match "ConvertTo-Json"

        $Reloaded = Get-VolScriptConfig
        $Reloaded.Shortcuts.Volume50 | Should -Be $Config.shortcuts.volume50
    }
}


Describe "Test-ProcessName" {
    It "accepts non-empty process names" {
        Test-ProcessName -ProcessName "cod" | Should -Be $true
        Test-ProcessName -ProcessName "spotify" | Should -Be $true
    }

    It "rejects empty process names" {
        Test-ProcessName -ProcessName "" | Should -Be $false
        Test-ProcessName -ProcessName "   " | Should -Be $false
        Test-ProcessName | Should -Be $false
    }
}


Describe "Get-VolScriptTargetProcess" {
    It "strips the .exe extension from the process name" {
        Mock Get-Process -ModuleName ProcessLifecycle {
            param(
                [string]$Name
            )

            return [PSCustomObject]@{
                Id   = 1234
                Name = $Name
            }
        }

        $Process =
            Get-VolScriptTargetProcess -ProcessName "cod.exe"

        $Process.Name | Should -Be "cod"
    }
}


Describe "VolScript.ps1 CLI" {
    It "shows help and exits with code 0" {
        $ProjectRoot =
            (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

        $ScriptPath = Join-Path $ProjectRoot "VolScript.ps1"

        $Process =
            Start-Process `
                -FilePath "powershell.exe" `
                -ArgumentList @(
                    "-NoProfile"
                    "-ExecutionPolicy"
                    "Bypass"
                    "-File"
                    $ScriptPath
                    "-h"
                ) `
                -Wait `
                -PassThru `
                -NoNewWindow

        $Process.ExitCode | Should -Be 0
    }

    It "exits with code 1 when process name is missing" {
        $ProjectRoot =
            (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

        $ScriptPath = Join-Path $ProjectRoot "VolScript.ps1"

        $Process =
            Start-Process `
                -FilePath "powershell.exe" `
                -ArgumentList @(
                    "-NoProfile"
                    "-ExecutionPolicy"
                    "Bypass"
                    "-File"
                    $ScriptPath
                ) `
                -Wait `
                -PassThru `
                -NoNewWindow

        $Process.ExitCode | Should -Be 1
    }
}
