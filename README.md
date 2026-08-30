<p align="center">
  <img src="assets/VolScript.png" width="96" alt="VolScript logo" />
</p>

<h1 align="center">VolScript</h1>

<p align="center">
  <strong>Per-app volume control for Windows — global hotkeys, no alt-tabs.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Windows-0078D6?style=flat-square&logo=windows&logoColor=white" alt="Windows" />
  <img src="https://img.shields.io/badge/shell-PowerShell-5391FE?style=flat-square&logo=powershell&logoColor=white" alt="PowerShell" />
  <img src="https://img.shields.io/badge/install-none-22c55e?style=flat-square" alt="No install" />
</p>

## Why VolScript?

You're in lobby with music on. The match starts — drop, helicopter, chaos — and the game **explodes to full volume**. Your music disappears. Your ears notice.

Fixing that means **Alt+Tab → Volume Mixer → slide → tab back**. Every time.

**VolScript** binds two hotkeys to one app: duck it instantly, restore it instantly. Everything else stays untouched. Games, Discord, Spotify, browsers — any process.

## What you get

| | |
|---|---|
| ⌨️ **Global hotkeys** | Works fullscreen, background, any focus |
| 🎯 **Per-process** | Only the app you target changes |
| 🔉 **Two presets** | Low + restore — levels you define |
| 📁 **Profiles** | One config per app, no shortcut clashes |
| 🔔 **Quiet mode** | Tray icon, hidden console (`-q`) |
| ⚙️ **Config editor** | `.\VolScript.ps1 -c` — no manual JSON |

## Run it

### 🖱️ Shortcuts — recommended

Create a `.lnk` per app. Double-click and forget.

**Target** (edit the path):

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Path\To\VolScript\VolScript.ps1" cod -q
```

| Shortcut | Change to |
|----------|-----------|
| VolScript — COD | `cod -q` |
| VolScript — Spotify | `spotify -q` |
| VolScript — Discord | `discord -q` |

Pin to taskbar or drop in **Startup** (`Win+R` → `shell:startup`) to launch with Windows.

Right-click the shortcut → **Properties** → **Change Icon** → browse to `assets\VolScript.ico` in the repo if you want the VolScript icon instead of the default PowerShell one.

> One shortcut = one process. Each app can have its own profile and hotkeys under `config/config.<process>.json`.

### 💻 PowerShell

```powershell
.\VolScript.ps1 cod        # console dashboard
.\VolScript.ps1 cod -q     # quiet / tray
.\VolScript.ps1 -c         # edit config
.\VolScript.ps1 -c cod     # edit profile
.\VolScript.ps1 -h         # help
```

VolScript waits until the process exists, then listens. Process closed? It waits again. Exit via hotkey or tray.

## Default hotkeys

| Action | Key | Level |
|--------|-----|-------|
| Duck | `ALT+SHIFT+P` | 15% |
| Restore | `ALT+SHIFT+O` | 100% |
| Exit | `ALT+SHIFT+Q` | — |

Edit in `config/config.json` or run `.\VolScript.ps1 -c`.

```json
{
  "shortcuts": { "volume50": "ALT+SHIFT+P", "volume100": "ALT+SHIFT+O", "exit": "ALT+SHIFT+Q" },
  "volumes":   { "volume50": 0.15, "volume100": 1 }
}
```

Profiles (`config/config.<process>.json`) are created automatically for extra instances — separate shortcuts so nothing overlaps.

<p align="center">
  <sub>Stay in the game. Control the noise.</sub>
</p>
