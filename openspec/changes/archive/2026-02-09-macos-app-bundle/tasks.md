## 1. App Bundle Generator in install.sh

- [x] 1.1 Add `install_macos_app_bundle()` function to `install.sh` that creates the `~/Applications/WT Control.app` directory structure: `Contents/`, `Contents/MacOS/`, `Contents/Resources/`
- [x] 1.2 Generate `Contents/Info.plist` via heredoc with CFBundleName, CFBundleIdentifier, CFBundleExecutable, CFBundleIconFile, LSUIElement fields
- [x] 1.3 Generate `Contents/MacOS/wt-control` executable wrapper that execs `$HOME/.local/bin/wt-control "$@"`, with error dialog (via osascript) if wt-control is not found
- [x] 1.4 Set executable permission on `Contents/MacOS/wt-control` (chmod +x)
- [x] 1.5 Run `mdimport ~/Applications/WT\ Control.app` to trigger Spotlight indexing

## 2. Integration into install.sh main flow

- [x] 2.1 Call `install_macos_app_bundle` from `main()` with platform guard (`[[ "$OSTYPE" == darwin* ]]`), alongside the existing `install_desktop_entry` call
- [x] 2.2 Add success message after bundle creation (e.g., "macOS app bundle installed — search 'WT Control' in Spotlight")

## 3. Verification

- [x] 3.1 Run `install.sh` on macOS and verify the `.app` bundle is created at `~/Applications/WT Control.app`
- [x] 3.2 Verify "WT Control" appears in Spotlight (Cmd+Space) and launches the GUI
- [x] 3.3 Verify the `.app` wrapper shows an error dialog if `~/.local/bin/wt-control` is missing
