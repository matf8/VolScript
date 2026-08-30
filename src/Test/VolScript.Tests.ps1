$ErrorActionPreference = "Stop"

$script:ProjectRoot =
    (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

$script:SrcRoot =
    Join-Path $script:ProjectRoot "src"

Import-Module (Join-Path $script:SrcRoot "HotKeys\HotKeys.psm1") -Force
Import-Module (Join-Path $script:SrcRoot "Config\Config.psm1") -Force
Import-Module (Join-Path $script:SrcRoot "Utils\ArgValidate.psm1") -Force
Import-Module (Join-Path $script:SrcRoot "Utils\ProcessLifecycle.psm1") -Force


Import-Module (Join-Path $script:SrcRoot "Utils\Instance.psm1") -Force


Import-Module (Join-Path $script:SrcRoot "Utils\MenuInput.psm1") -Force


Describe "Menu input" {
    It "accepts valid single-key choices" {
        Test-VolScriptMenuChoice `
            -Choice "1" `
            -ValidChoices @("1", "2", "3") |
            Should -Be $true

        Test-VolScriptMenuChoice `
            -Choice "s" `
            -ValidChoices @("S", "Q") |
            Should -Be $true

        Test-VolScriptMenuChoice `
            -Choice "x" `
            -ValidChoices @("S", "Q") |
            Should -Be $false
    }
}


Describe "Config paths" {
    It "resolves default config to config/config.json" {
        $ProjectRoot =
            (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

        $Expected =
            Join-Path $ProjectRoot "config\config.json"

        $Actual =
            Get-VolScriptDefaultConfigPath

        (Resolve-Path -LiteralPath $Actual).Path |
            Should -Be (Resolve-Path -LiteralPath $Expected).Path
    }

    It "builds process profile file names" {
        Get-VolScriptProcessConfigFileName -ProcessName "cod" |
            Should -Be "config.cod.json"

        Get-VolScriptProcessConfigFileName -ProcessName "cod.exe" |
            Should -Be "config.cod.json"
    }

    It "resolves editor path for default config" {
        $ProjectRoot =
            (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

        $Expected =
            Join-Path $ProjectRoot "config\config.json"

        $Resolved =
            Resolve-VolScriptEditorConfigPath

        (Resolve-Path -LiteralPath $Resolved).Path |
            Should -Be (Resolve-Path -LiteralPath $Expected).Path
    }

    It "creates profile config when editing a new process" {
        $ProfileName = "pestereditor$([guid]::NewGuid().ToString('N').Substring(0, 8))"
        $ProfilePath =
            Get-VolScriptProcessConfigPath `
                -ProcessName $ProfileName

        if (Test-Path $ProfilePath)
        {
            Remove-Item -Path $ProfilePath -Force
        }

        try
        {
            $Resolved =
                Resolve-VolScriptEditorConfigPath `
                    -ProcessName $ProfileName

            (Resolve-Path -LiteralPath $Resolved).Path |
                Should -Be (Resolve-Path -LiteralPath $ProfilePath).Path

            Test-Path $ProfilePath | Should -Be $true
        }
        finally
        {
            Clear-VolScriptActiveConfigPath

            if (Test-Path $ProfilePath)
            {
                Remove-Item -Path $ProfilePath -Force
            }
        }
    }
}


Describe "Instance shortcuts" {
    It "detects shortcut conflicts" {
        Test-VolScriptShortcutConflict `
            -ShortcutsA @("ALT+SHIFT+P", "ALT+SHIFT+O") `
            -ShortcutsB @("ALT+SHIFT+Q", "ALT+SHIFT+P") |
            Should -Be $true

        Test-VolScriptShortcutConflict `
            -ShortcutsA @("ALT+SHIFT+P") `
            -ShortcutsB @("CTRL+ALT+SHIFT+P") |
            Should -Be $false
    }

    It "detects a single primary running instance" {
        $Instances = @(
            [PSCustomObject]@{
                pid         = 1234
                processName = "spotify"
                configPath  = "config\config.json"
                isPrimary   = $true
                shortcuts   = [PSCustomObject]@{
                    volume50  = "ALT+SHIFT+P"
                    volume100 = "ALT+SHIFT+O"
                    exit      = "ALT+SHIFT+Q"
                }
            }
        )

        $Primary = @(
            $Instances |
            Where-Object { $_.isPrimary }
        )

        $Primary.Count | Should -Be 1
    }

    It "registers a second instance without array errors" {
        $Existing = [PSCustomObject]@{
            pid         = 1000
            processName = "cod"
            configPath  = "config\config.json"
            isPrimary   = $true
            shortcuts   = [PSCustomObject]@{
                volume50  = "ALT+SHIFT+P"
                volume100 = "ALT+SHIFT+O"
                exit      = "ALT+SHIFT+Q"
            }
        }

        $Filtered = @(
            @($Existing) |
            Where-Object { $_.pid -ne 2000 }
        )

        $Updated = $Filtered + @(
            [PSCustomObject]@{
                pid         = 2000
                processName = "spotify"
                configPath  = "config\config.spotify.json"
                isPrimary   = $false
                shortcuts   = [PSCustomObject]@{
                    volume50  = "CTRL+ALT+SHIFT+P"
                    volume100 = "CTRL+ALT+SHIFT+O"
                    exit      = "CTRL+ALT+SHIFT+Q"
                }
            }
        )

        $Updated.Count | Should -Be 2
        $Updated[1].processName | Should -Be "spotify"
    }

    It "cleans stale running.json entries" {
        $RunningPath =
            Join-Path `
                $env:LOCALAPPDATA `
                "VolScript\running.json"
        $Backup = $null

        if (Test-Path $RunningPath)
        {
            $Backup = Get-Content -Path $RunningPath -Raw
        }

        try
        {
            @(
                [PSCustomObject]@{
                    pid         = 99999999
                    processName = "stale"
                    configPath  = "config\config.json"
                    isPrimary   = $true
                    shortcuts   = [PSCustomObject]@{
                        volume50  = "ALT+SHIFT+P"
                        volume100 = "ALT+SHIFT+O"
                        exit      = "ALT+SHIFT+Q"
                    }
                }
            ) | ConvertTo-Json -Depth 4 |
                Set-Content `
                    -Path $RunningPath `
                    -Encoding UTF8 `
                    -NoNewline

            $Instances = Get-VolScriptRunningInstances

            $Instances | Should -Be @()
            Test-Path $RunningPath | Should -Be $false
        }
        finally
        {
            if ($null -ne $Backup)
            {
                Set-Content `
                    -Path $RunningPath `
                    -Value $Backup `
                    -Encoding UTF8 `
                    -NoNewline
            }
            elseif (Test-Path $RunningPath)
            {
                Remove-Item -Path $RunningPath -Force
            }
        }
    }
}


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
