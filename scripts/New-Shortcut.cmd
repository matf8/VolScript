@echo off
setlocal EnableExtensions

cd /d "%~dp0"

set "PROCESS=%~1"

if "%PROCESS%"=="" (
    set /p "PROCESS=Process name (e.g. cod, spotify): "
)

if "%PROCESS%"=="" (
    echo.
    echo Process name is required. Shortcut was not created.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0New-Shortcut.ps1" -Process "%PROCESS%"

if errorlevel 1 (
    pause
    exit /b 1
)

pause
