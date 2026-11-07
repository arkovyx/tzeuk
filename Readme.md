<p align="center">
  <img src="assets/banner.png" alt="TZEUK banner" width="980" />
</p>

# TZEUK

TZEUK is a custom desktop shell built with Quickshell for Hyprland. It brings together a status bar, app launcher, notification/calendar popups, workspace-aware widgets, and a stylized panel-driven experience designed around a compact, elegant desktop workflow.

## Highlights

- Quickshell-powered desktop shell for Hyprland
- Custom bar and panel UI
- Launcher and glyph/character picker
- Notification and calendar popups
- Theme-driven styling and modular layout
- Workspace, service, and desktop integration pieces

## Project structure

```text
.
├── assets/          # Artwork and visual assets
├── bar/             # Top bar widgets and status blocks
├── fonts/           # Font files used by the shell
├── glyphs/          # Glyph/character assets and helpers
├── launcher/        # Application launcher UI
├── panel/           # Panel, popups, and tabs
├── services/        # Service integrations and desktop helpers
├── sounds/          # Audio assets
├── themes/          # Theme definitions
├── workspaces/      # Workspace-related components
├── chars-gen.py     # Script for generating char metadata
├── chars.json       # Character data used by the UI
├── shell.qml        # Main Quickshell shell entry point
├── Readme.md        # Project documentation
└── ...
```

## Requirements

- Linux
- Hyprland
- Quickshell
- Python 3 (for the character generation script)

## Getting started

1. Clone the repository:

```bash
git clone https://github.com/arkovyx/tzeuk.git
cd tzeuk
```

2. Make sure Quickshell and Hyprland are installed and configured on your system.

3. Start the shell through your Quickshell/Hyprland configuration, or point your Quickshell config at `shell.qml`.

4. If you need to regenerate the bundled character data, run:

```bash
python3 chars-gen.py
```

## Main entry point

The shell is defined in `shell.qml`, which wires together the main desktop components:

- `Bar`
- `Panel`
- `Launcher`
- `CalendarPopup`
- `NotifPopup`
- `CharPicker`

This makes the project a full custom shell environment rather than a standalone widget set.

## Notes

This repository is tailored to a personal desktop setup and is best treated as a custom Hyprland/Quickshell shell configuration rather than a generic package. It is designed for users who want a highly opinionated, themed desktop experience with custom UI behavior.

## Contribution

If you want to tweak the layout, themes, widgets, or behavior, the easiest starting points are:

- `shell.qml` for root composition
- `bar/` for status widgets
- `panel/` for the side panels and popups
- `themes/Theme.qml` for styling

---

Built for a custom desktop workflow with Quickshell and Hyprland.
