## 1. SVG Icon Creation

- [x] 1.1 Create `assets/` directory and write `assets/icon.svg` — white "WT" on dark (#2D3748) rounded-rectangle background, programmatically generated
- [x] 1.2 Create `scripts/generate-icon.py` that writes the SVG, renders PNG (256x256 via PySide6), and generates .icns (macOS via iconutil)
- [x] 1.3 Run `scripts/generate-icon.py` to produce `assets/icon.svg`, `assets/icon.png`, and `assets/icon.icns`

## 2. macOS Installation

- [x] 2.1 Update `install_macos_app_bundle()` in `install.sh` to copy `assets/icon.icns` → `~/Applications/WT Control.app/Contents/Resources/app.icns`

## 3. Linux Installation

- [x] 3.1 Update `install_desktop_entry()` in `install.sh` to copy `assets/icon.png` → `~/.local/share/icons/wt-control.png` and set `Icon=` to that path

## 4. Qt Application Icon

- [x] 4.1 In `gui/main.py`, set app name to "WT Control", load `assets/icon.png` and call `app.setWindowIcon()` with graceful fallback if file missing

## 5. Verification

- [x] 5.1 Verify macOS .app bundle shows the custom "WT" icon in Finder
