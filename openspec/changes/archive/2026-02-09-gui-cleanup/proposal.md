## Why

The GUI codebase has accumulated dead code, unused infrastructure, and color profile inconsistencies during the refactor from the monolithic `main_old.py` to the modular mixin architecture. Before going to production, these need to be cleaned up to reduce confusion and prevent visual bugs.

## What Changes

- **Delete dead files**: Remove `gui/main_old.py` (4880 lines, unreferenced), `gui/platforms/` directory (superseded by `gui/platform/`), `gui/widgets/ClickableLabel` (unused by active code)
- **Remove unused menu infrastructure**: Delete `MenuBuilder` class and `MENU_ICONS` dict from `gui/control_center/mixins/menu_builder.py` — never used, menus are built manually in `menus.py`
- **Fix missing color keys**: Add `text_secondary` to all COLOR_PROFILES (referenced in `table.py:398` but undefined, falls back to `#000000`). Add `text_primary` to `high_contrast` profile (missing, causes black-on-dark-background text).
- **Remove duplicate Push menu item**: The row context menu has both Git > Push (`git push`) and Worktree > Push Branch (`wt-push` script) — confusing. Remove the Worktree submenu's "Push Branch" item since Git > Push is the standard action and wt-push is a niche script.
- **Normalize tray menu style**: Remove emojis from tray menu items to match the plain text style of main menu and context menus.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `color-profiles`: Adding missing `text_secondary` key to all profiles and `text_primary` to `high_contrast`
- `menu-system`: Removing duplicate Push Branch from Worktree submenu, normalizing tray menu emoji style

## Impact

- **Files deleted**: `gui/main_old.py`, `gui/platforms/` (5 files), `gui/widgets/clickable_label.py`, `gui/widgets/__init__.py` (or emptied), `gui/control_center/mixins/menu_builder.py`
- **Files modified**: `gui/constants.py` (color profiles), `gui/control_center/mixins/menus.py` (row context menu, tray menu), `gui/control_center/main_window.py` (tray menu)
- **No API or behavior changes** — purely internal cleanup and visual bug fixes
