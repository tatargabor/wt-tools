## Why

On macOS, `wt-control` can only be launched from the terminal. There is no way to start it from Spotlight (Cmd+Space), Alfred, Raycast, or the Dock — because macOS launchers only discover `.app` bundles, not shell scripts in `~/.local/bin/`. Linux already has a `.desktop` file for Alt+F2 discovery. macOS needs the equivalent: a minimal `.app` bundle.

## What Changes

- Add a macOS `.app` bundle generator to `install.sh` that creates `~/Applications/WT Control.app`
- The `.app` bundle contains a minimal `Info.plist` and an executable wrapper that delegates to the existing `wt-control` shell script
- Optional app icon (`.icns`) for Dock/Spotlight display
- After install, "WT Control" is discoverable via Cmd+Space and can be pinned to the Dock

## Capabilities

### New Capabilities

- `macos-app-bundle`: Generation and installation of a macOS `.app` bundle for the Control Center GUI, making it launchable from Spotlight, Alfred, Raycast, and the Dock.

### Modified Capabilities

- `control-center`: Add a new launch scenario (launch from macOS .app bundle) to the "Robust GUI Launch" requirement.

## Impact

- **install.sh**: New section to generate and install the `.app` bundle (macOS only)
- **Existing behavior**: No changes to Linux `.desktop` flow or CLI `wt-control` behavior
- **No new dependencies**: Uses only standard macOS conventions (`.app` directory structure, `Info.plist` XML)
