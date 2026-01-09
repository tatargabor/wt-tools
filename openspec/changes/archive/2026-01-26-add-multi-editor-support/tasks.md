## 1. Core Editor Detection
- [x] 1.1 Add editor definitions to `bin/wt-common.sh` (EDITORS array with name, command, window_class)
- [x] 1.2 Implement `find_editor()` function replacing `find_zed()`
- [x] 1.3 Add `get_editor_config()` to read user preference from config
- [x] 1.4 Add `detect_available_editors()` function
- [x] 1.5 Write unit tests for editor detection (`tests/test_editor_detection.sh`)

## 2. Configuration Management
- [x] 2.1 Create `bin/wt-config` script with `editor` subcommand
- [x] 2.2 Implement `wt-config editor list` - show available editors
- [x] 2.3 Implement `wt-config editor set <name>` - set preferred editor
- [x] 2.4 Implement `wt-config editor show` - show current editor
- [x] 2.5 Add config validation (reject invalid editor names)
- [x] 2.6 Write tests for wt-config (`tests/test_editor_integration.py`)

## 3. Update Worktree Scripts
- [x] 3.1 Update `bin/wt-work` to use `find_editor()` instead of `find_zed()`
- [x] 3.2 Update Claude Code launch logic per editor type
- [x] 3.3 Update `bin/wt-focus` to use editor-specific window class
- [x] 3.4 Update `bin/wt-new` to support multiple editors (setup_editor_config)
- [x] 3.5 Test each script with vscode editor config

## 4. GUI Updates
- [ ] 4.1 Add editor selection to settings/config dialog
- [ ] 4.2 Update `handlers.py` to use configurable editor
- [ ] 4.3 Show current editor in status bar or settings
- [ ] 4.4 Add editor icons/indicators in UI

## 5. Installation Scripts
- [ ] 5.1 Update `install.sh` to detect all supported editors
- [ ] 5.2 Update `install.ps1` for Windows editor detection
- [ ] 5.3 Add first-run editor selection prompt
- [ ] 5.4 Document editor-specific Claude Code setup in install output

## 6. Testing
- [x] 6.1 Create `tests/test_editor_integration.py` with pytest
- [x] 6.2 Add mock tests for editor detection (no editor required)
- [x] 6.3 Add integration test markers for tests requiring editors
- [ ] 6.4 Create CI workflow for editor detection tests
- [ ] 6.5 Add test matrix: [zed, vscode, cursor, windsurf] x [linux, macos, windows]

## 7. Documentation
- [ ] 7.1 Update CLAUDE.md with editor configuration
- [ ] 7.2 Update README with supported editors
- [ ] 7.3 Add EDITORS.md with editor-specific setup instructions
- [ ] 7.4 Update openspec/project.md to remove ZED-only constraint

## 8. Validation
- [x] 8.1 Run `openspec validate add-multi-editor-support --strict`
- [ ] 8.2 Test fresh install with each editor
- [x] 8.3 Test migration from ZED-only config (auto fallback works)
- [ ] 8.4 Test on Linux, macOS, Windows (if available)
