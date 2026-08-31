param(
    [Parameter(Mandatory = $false)]
    [string]$Process,

    [string]$InstallPath,

    [string]$ShortcutDirectory,

    [switch]$NoQuiet
)

$ErrorActionPreference = "Stop"

function Show-VolScriptShortcutConfirmDialog
{
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Add-Type `
        -AssemblyName System.Windows.Forms `
        -ErrorAction Stop

    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        "VolScript",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information) |
        Out-Null
}

if ([string]::IsNullOrWhiteSpace($InstallPath))
{
    $InstallPath =
        (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if ([string]::IsNullOrWhiteSpace($ShortcutDirectory))
{
    $ShortcutDirectory =
        [Environment]::GetFolderPath("Desktop")
}

$Process = $Process.Trim()

if ([string]::IsNullOrWhiteSpace($Process))
{
    $Process = Read-Host "Process name (e.g. cod, spotify)"
    $Process = $Process.Trim()
}

if ([string]::IsNullOrWhiteSpace($Process))
{
    Write-Host ""
    Write-Host "Process name is required. Shortcut was not created." `
        -ForegroundColor Red
    Write-Host ""
    exit 1
}

if ($Process.EndsWith(".exe", [StringComparison]::OrdinalIgnoreCase))
{
    $Process =
        $Process.Substring(0, $Process.Length - 4)
}

$ScriptPath =
    Join-Path $InstallPath "VolScript.ps1"

if (-not (Test-Path $ScriptPath))
{
    Write-Host ""
    Write-Host "VolScript.ps1 not found at: $ScriptPath" `
        -ForegroundColor Red
    Write-Host ""
    exit 1
}

$IconPath =
    (Resolve-Path (Join-Path $InstallPath "assets\VolScript.ico")).Path

$ProcessLabel =
    $Process.ToUpperInvariant()

$ShortcutPath =
    Join-Path $ShortcutDirectory ("VS 4 {0}.lnk" -f $ProcessLabel)

$Shell = New-Object -ComObject WScript.Shell

$Shortcut = $Shell.CreateShortcut($ShortcutPath)

if ($NoQuiet)
{
    $Arguments =
        @(
            "-NoProfile"
            "-ExecutionPolicy"
            "Bypass"
            "-File"
            ('"{0}"' -f $ScriptPath)
            $Process
        )

    $Shortcut.TargetPath =
        "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments = ($Arguments -join " ")
}
else
{
    $LauncherPath =
        Join-Path $InstallPath "scripts\Launch-Quiet.vbs"

    if (-not (Test-Path $LauncherPath))
    {
        Write-Host ""
        Write-Host "Launch-Quiet.vbs not found at: $LauncherPath" `
            -ForegroundColor Red
        Write-Host ""
        exit 1
    }

    $Shortcut.TargetPath =
        "$env:SystemRoot\System32\wscript.exe"
    $Shortcut.Arguments =
        ('//B //Nologo "{0}" {1}' -f $LauncherPath, $Process)
}

$Shortcut.WorkingDirectory = $InstallPath
$Shortcut.IconLocation = "{0},0" -f $IconPath
$Shortcut.Description = "VS 4 $ProcessLabel - VolScript per-app volume hotkeys"
$Shortcut.Save()

$LocationLabel =
    if (
        $ShortcutDirectory -eq
        [Environment]::GetFolderPath("Desktop")
    )
    {
        "desktop"
    }
    else
    {
        $ShortcutDirectory
    }

Write-Host ""
Write-Host "Shortcut created on your ${LocationLabel}:" `
    -ForegroundColor Green
Write-Host ""
Write-Host "  $(Split-Path $ShortcutPath -Leaf)" `
    -ForegroundColor Cyan
Write-Host "  $ShortcutPath" `
    -ForegroundColor DarkGray
Write-Host ""
Write-Host "Double-click it to start VolScript for $ProcessLabel." `
    -ForegroundColor Yellow
Write-Host ""

Show-VolScriptShortcutConfirmDialog `
    -Message (
        "Shortcut created on your ${LocationLabel}:`n`n" +
        "$(Split-Path $ShortcutPath -Leaf)"
    )
