## Why

CI is failing on master and all PRs. The failures are due to shellcheck not supporting zsh syntax, outdated tests expecting deprecated behavior, and missing Qt platform configuration for headless environments. This blocks all pull requests from being merged.

## What Changes

- Exclude `wt-completions.zsh` from shellcheck linting (zsh uses syntax shellcheck doesn't understand)
- Fix or skip outdated tests in `test_editor_integration.py` that test deprecated/removed features
- Fix `test_29_memory.py::test_context_menu_install_hooks_action` which expects menu items in wrong location
- Add `QT_QPA_PLATFORM=offscreen` for Ubuntu CI to fix pytest-qt headless failures
- Add `.shellcheckrc` to suppress style warnings that aren't actual bugs

## Capabilities

### New Capabilities

(none - this is a fix, not a new feature)

### Modified Capabilities

(none - fixing CI configuration and tests, not changing spec-level behavior)

## Impact

- `.github/workflows/ci.yml` - CI workflow configuration
- `bin/wt-completions.zsh` - exclude from shellcheck
- `tests/test_editor_integration.py` - fix or remove outdated tests
- `tests/gui/test_29_memory.py` - fix menu capture logic
- `.shellcheckrc` - new file to configure shellcheck behavior
