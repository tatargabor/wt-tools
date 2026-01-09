## Why

WT Control uses generic/placeholder icons everywhere — the macOS .app bundle shows a generic app icon in Spotlight and Dock, the Linux .desktop entry uses the system `utilities-terminal` icon, and the Qt window has no application icon set. A custom "W" icon gives the app a recognizable identity across all platforms.

## What Changes

- Add an SVG icon source file (`assets/icon.svg`) with a stylized "W" design, generated programmatically
- Add a build/convert script that produces `.icns` (macOS) and `.png` (Linux/general) from the SVG
- Install the `.icns` into the macOS `.app` bundle (`Contents/Resources/app.icns`)
- Install the `.png` and update the Linux `.desktop` entry to reference it
- Set the Qt application icon (`QApplication.setWindowIcon`) for taskbar/window decoration

## Capabilities

### New Capabilities

- `app-icon`: Generation, conversion, and installation of the application icon across macOS and Linux.

### Modified Capabilities

- `macos-app-bundle`: The .app bundle now includes the actual `app.icns` icon file in `Contents/Resources/`.
- `control-center`: The GUI sets a window icon via `QApplication.setWindowIcon()`.

## Impact

- **New files**: `assets/icon.svg`, `assets/icon.png`, `assets/icon.icns`, icon generation script
- **install.sh**: Copy `.icns` into `.app` bundle, copy `.png` for Linux `.desktop`
- **gui/main.py**: Add `setWindowIcon()` call
- **Linux .desktop**: Change `Icon=` from `utilities-terminal` to the custom icon path
- **No new runtime dependencies**: SVG→PNG→ICNS conversion uses standard tools (available on macOS/Linux)
