## Context

WT Control currently has no custom icon. The macOS `.app` bundle's `Info.plist` references `app.icns` but the file doesn't exist, so macOS shows a generic icon. The Linux `.desktop` entry uses the system theme's `utilities-terminal` icon. The tray icon is a dynamic colored circle (QPainter-generated) that changes color based on agent status — this is intentional and stays as-is.

## Goals / Non-Goals

**Goals:**
- Recognizable "W" icon in Spotlight, Dock, Linux app launcher, and taskbar
- SVG source file committed to repo (vector, editable)
- Pre-built `.png` and `.icns` committed to repo (no build step required at install time)
- Zero new runtime dependencies

**Non-Goals:**
- Changing the tray icon (it's a status indicator, not branding)
- Animated icons
- Multiple icon variants/themes
- High-fidelity design work (simple geometric "W" is fine)

## Decisions

### 1. SVG design: white "W" on dark rounded-rectangle background

A bold white "W" letter on a dark background (#2D3748 or similar slate/charcoal) with rounded corners. This is:
- Readable at small sizes (16x16 menubar)
- High contrast in both light and dark OS themes
- Simple to generate programmatically as SVG

Alternative considered: Gradient/3D effects — rejected for complexity and poor small-size rendering.

### 2. Icon generation: Python script using SVG string + cairosvg/sips

A Python script (`scripts/generate-icon.py`) that:
1. Writes the SVG string to `assets/icon.svg`
2. Uses `cairosvg` (pip) to render SVG → PNG at multiple sizes (16, 32, 64, 128, 256, 512, 1024)
3. On macOS: uses `sips` and `iconutil` (built-in) to create `.icns` from the PNGs
4. On Linux: the 256px PNG is sufficient for `.desktop`

The script is a **dev tool** run once (or when the icon changes). The resulting `assets/icon.svg`, `assets/icon.png`, and `assets/icon.icns` are committed to the repo. Users never run this script — `install.sh` just copies the pre-built files.

Alternative considered: Requiring `cairosvg` at install time — rejected because it's a dev-only dependency.
Alternative considered: Using `rsvg-convert` (librsvg CLI) — less portable, not available on macOS by default.

### 3. File locations

```
assets/
  icon.svg         ← source (committed)
  icon.png         ← 256x256 rendered (committed)
  icon.icns        ← macOS icon set (committed)
scripts/
  generate-icon.py ← dev tool (committed, run manually)
```

### 4. Installation: copy pre-built files

- **macOS .app**: `install.sh` copies `assets/icon.icns` → `~/Applications/WT Control.app/Contents/Resources/app.icns`
- **Linux .desktop**: `install.sh` copies `assets/icon.png` → `~/.local/share/icons/wt-control.png`, updates `Icon=` path
- **Qt window icon**: `gui/main.py` loads `assets/icon.png` via `QIcon` and calls `app.setWindowIcon()`

### 5. Qt window icon: resolve path relative to project root

The `gui/main.py` entry point already knows the project root (from `__file__` or PYTHONPATH). Load `assets/icon.png` relative to that. If the file doesn't exist (e.g., dev environment without assets), skip silently.

## Risks / Trade-offs

- **cairosvg dependency for generation** → Only needed by developers regenerating the icon. Not a runtime dependency. Can `pip install cairosvg` in a venv.
- **Committed binary files (.png, .icns)** → Small files (~50KB total). Worth committing to avoid build-time dependencies for users.
- **Icon quality** → A code-generated SVG won't be pixel-perfect at tiny sizes. Acceptable for a dev tool — not a consumer app.
