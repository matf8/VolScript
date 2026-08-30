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
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT license" /></a>
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

Get the project — [latest release zip](https://github.com/matf8/VolScript/releases/latest) or clone the repo — and open PowerShell in that folder.

Two ways to use VolScript:

| | Desktop shortcut | PowerShell direct |
|---|---|---|
| **Best for** | Daily use, gaming | Testing, config, dashboard |
| **How** | `New-Shortcut.ps1` → double-click `.lnk` | `.\VolScript.ps1` |
| **UI** | Tray only (`-q`) | Console or tray |

### 1 · Desktop shortcut *(recommended)*

**Step 1 — create the shortcut**

Right-click `scripts/New-Shortcut.ps1` → **Run with PowerShell** and enter the process name when prompted (`cod`, `spotify`, …).

Or from an open terminal:

```powershell
.\scripts\New-Shortcut.ps1 -Process cod
```

| Option | Description |
|--------|-------------|
| `-Process` | Target app, without `.exe` *(required)* |
| `-InstallPath` | VolScript folder if not the repo root |
| `-ShortcutDirectory` | Where to save the `.lnk` *(default: desktop)* |
| `-NoQuiet` | Shortcut launches with console visible instead of tray |

Creates `VS 4 COD.lnk` on your desktop with the VolScript icon. A confirmation dialog appears when it is ready. Empty process names are rejected.

**Step 2 — run VolScript**

Double-click the shortcut. VolScript sits in the tray until the app is running, then listens for hotkeys.

- Pin the `.lnk` to taskbar or copy it to **Startup** (`Win+R` → `shell:startup`) to launch with Windows.
- One shortcut = one process. Profiles live in `config/config.<process>.json`.
- If VolScript is already running, launching another shortcut opens a dialog: change target, new instance, or cancel.

### 2 · PowerShell direct

Run VolScript yourself — useful for first try, editing config, or the on-screen dashboard:

```powershell
.\VolScript.ps1 cod          # wait for cod, show dashboard
.\VolScript.ps1 cod -q       # wait for cod, tray only
.\VolScript.ps1 -c           # edit default config
.\VolScript.ps1 -c cod       # edit cod profile
.\VolScript.ps1 -h           # help
```

VolScript waits until the target process exists. If it closes, VolScript waits again. Exit with the exit hotkey or from the tray.

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
