$ErrorActionPreference = "Stop"


# ============================================================
# Shared C# loader
# ============================================================

function Add-VolScriptCompiledTypes
{
    param(
        [Parameter(Mandatory)]
        [string]$TypeGuard,

        [Parameter(Mandatory)]
        [string]$CorePath,

        [Parameter(Mandatory)]
        [string[]]$SourceFiles,

        [Parameter(Mandatory)]
        [string[]]$UsingStatements
    )

    if ($TypeGuard -as [type])
    {
        return
    }

    $Source = @()

    $Source += $UsingStatements
    $Source += ""

    foreach ($File in $SourceFiles)
    {
        $Content =
            Get-Content `
                (Join-Path $CorePath $File) `
                -Raw

        $Content =
            [regex]::Replace(
                $Content,
                '(?m)^[ \t]*using\s+[\w.*]+;\s*\r?\n',
                '')

        $Source += $Content
        $Source += ""
    }

    Add-Type `
        -TypeDefinition ($Source -join "`n")
}


function Initialize-VolScriptCompiledTypes
{
    $SrcRoot =
        Split-Path `
            $PSScriptRoot `
            -Parent

    Add-VolScriptCompiledTypes `
        -TypeGuard "VolScript.VolScriptHotKeys" `
        -CorePath (Join-Path $SrcRoot "HotKeys\Core") `
        -SourceFiles @(
            "Constants.cs"
            "Native\User32.cs"
            "Native\Kernel32.cs"
            "Keyboard\HotkeyModifierHelper.cs"
            "Keyboard\HotkeyNameHelper.cs"
            "Keyboard\KeyboardHookListener.cs"
            "HotKeys.cs"
            "HotkeyCapture.cs"
        ) `
        -UsingStatements @(
            "using System;"
            "using System.Diagnostics;"
            "using System.Runtime.InteropServices;"
            "using System.Text;"
            "using System.Threading;"
            "using VolScript.HotKeys;"
            "using VolScript.HotKeys.Keyboard;"
            "using VolScript.HotKeys.Native;"
        )

    Add-VolScriptCompiledTypes `
        -TypeGuard "VolScript.Audio.CoreAudio" `
        -CorePath (Join-Path $SrcRoot "AudioManager\Core") `
        -SourceFiles @(
            "Constants.cs"
            "Guids.cs"
            "Interfaces.cs"
            "Com\Helpers.cs"
            "Com\Classes.cs"
            "Session.cs"
            "CoreAudio.cs"
        ) `
        -UsingStatements @(
            "using System;"
            "using System.ComponentModel;"
            "using System.Diagnostics;"
            "using System.Runtime.InteropServices;"
        )

    Add-VolScriptCompiledTypes `
        -TypeGuard "VolScript.UI.ConsoleWindow" `
        -CorePath (Join-Path $SrcRoot "UI\Core") `
        -SourceFiles @(
            "Native\Kernel32.cs"
            "Native\User32.cs"
            "ConsoleWindow.cs"
        ) `
        -UsingStatements @(
            "using System;"
            "using System.Runtime.InteropServices;"
            "using VolScript.UI.Native;"
        )
}


Initialize-VolScriptCompiledTypes


Export-ModuleMember -Function Initialize-VolScriptCompiledTypes
