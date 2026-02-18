## 1. Shell Lint Fixes

- [x] 1.1 Create `.shellcheckrc` with disable directives for style warnings (SC2034, SC2155, SC2206, SC2207)
- [x] 1.2 Update `.github/workflows/ci.yml` to exclude `wt-completions.zsh` from shellcheck

## 2. Test Fixes - Editor Integration

- [x] 2.1 Remove `test_get_editor_property_window_class` test (tests non-existent feature)
- [x] 2.2 Remove `test_get_editor_property_claude_launch` test (tests non-existent feature)
- [x] 2.3 Fix or remove `test_list_runs` to handle deprecated `wt-focus --list` behavior

## 3. Test Fixes - Memory Menu

- [x] 3.1 Update `_MenuCapture` class in `test_29_memory.py` to recursively capture submenu actions
- [x] 3.2 Verify `test_context_menu_install_hooks_action` passes with updated capture

## 4. CI Environment Fixes

- [x] 4.1 Add `QT_QPA_PLATFORM=offscreen` environment variable for Linux test runs in ci.yml

## 5. Verification

- [x] 5.1 Run tests locally to verify all fixes work
- [ ] 5.2 Push branch and verify CI passes
