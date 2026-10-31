<p align="center">
  <img src="assets/banner.png" alt="TZEUK Banner" width="100%">
</p>

<p align="center">
  A custom desktop shell for Hyprland built with <a href="https://quickshell.org/">Quickshell</a>.
</p>

---

## ✨ Features

TZEUK replaces standard tools like Waybar, SwayNC, and Dunst with a single, unified QML interface.

- **Dynamic Theming**: Live color updates across the entire shell using `pywal16`.
- **The Bar**: Interactive workspaces, active window title, system tray, and system stats.
- **Control Panel**: A glassmorphism-inspired panel with animated transitions.
  - **Home**: Media player with seek support, brightness slider, quick toggles, power menu, and a circular Cava audio visualizer.
  - **Audio**: Global output/input volumes and per-application volume control.
  - **Network**: WiFi list, connection status, and `nmtui` integration.
  - **Bluetooth**: Device scanning, pairing, connecting, and forgetting.
  - **System**: Live CPU, RAM, Battery, Disk, and Uptime displayed in circular progress rings.
  - **Notifications**: Native popups, notification history, Do Not Disturb, and clear-all.
- **Calendar**: Popup with ISO week numbers and a live clock.

## 📦 Dependencies

Make sure you have the following installed on your Arch Linux system:
- `quickshell`
- `hyprland`
- `pywal16`
- `cava`
- `networkmanager`
- `brightnessctl`
- <a href="https://github.com/shezdy/hyprsplit/">`hyprsplit`</a>
- A Nerd Font (Default: `JetBrainsMono Nerd Font`)

## 🚀 Installation
- Get the repo:
```
mkdir -p ~/.config/quickshell
git clone https://github.com/arkovyx/tzeuk.git ~/.config/quickshell/tzeuk
```
- Clone hyprsplit(if not):
```
# make sure hyprsplit is clone in hyprland config directory in hyprsplit folder
git clone https://github.com/shezdy/hyprsplit.git ~/.config/hypr/
```

- Make sure hyprland.lua has these lines:
```
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c ~/.config/quickshell/tzeuk")
    hl.exec_cmd("hypridle")
end)
```
```
local hs = require("hyprsplit")

hs.config({
    num_workspaces = 10,
    persistent_workspaces = true,
})
```
