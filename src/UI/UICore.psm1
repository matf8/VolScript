$ErrorActionPreference = "Stop"


# ============================================================
# Load UI Core
# ============================================================

if (-not ("VolScript.UI.ConsoleWindow" -as [type]))
{
    $CorePath =
        Join-Path `
            $PSScriptRoot `
            "Core"

    $SourceFiles = @(
        "Native\Kernel32.cs"
        "Native\User32.cs"
        "ConsoleWindow.cs"
    )

    $UsingStatements = @(
        "using System;"
        "using System.Runtime.InteropServices;"
        "using VolScript.UI.Native;"
    )

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
                '(?m)^[ \t]*using\s+[\w.]+\s*;\s*\r?\n',
                '')

        $Source += $Content
        $Source += ""
    }

    Add-Type `
        -TypeDefinition ($Source -join "`n")
}
