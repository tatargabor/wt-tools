## 1. Delete Dead Files

- [x] 1.1 Delete `gui/main_old.py`
- [x] 1.2 Delete `gui/platforms/` directory (all 5 files: `__init__.py`, `base.py`, `linux.py`, `macos.py`, `windows.py`)
- [x] 1.3 Delete `gui/widgets/clickable_label.py` and `gui/widgets/__init__.py` (ClickableLabel is unused)
- [x] 1.4 Delete `gui/control_center/mixins/menu_builder.py` (MenuBuilder, MENU_ICONS, plugin infra — unused)

## 2. Fix Color Profiles

- [x] 2.1 Add `text_secondary` key to all 4 profiles in `gui/constants.py` COLOR_PROFILES (light: `#60a5fa`, dark: `#60a5fa`, gray: `#60a5fa`, high_contrast: `#00aaff`)
- [x] 2.2 Add `text_primary` key to `high_contrast` profile (`#ffffff`) in `gui/constants.py`
- [x] 2.3 Remove the inline fallback in `table.py:398` — simplify to just `self.get_color("text_secondary")` since the key now exists in all profiles

## 3. Clean Up Menus

- [x] 3.1 Remove "Push Branch" from the Worktree submenu in `gui/control_center/mixins/menus.py` `show_row_context_menu()`
- [x] 3.2 Remove `wt_push_branch()` handler from `gui/control_center/mixins/handlers.py` (no longer referenced)
- [x] 3.3 Remove emojis from tray menu items in `gui/control_center/main_window.py` `setup_tray()` — change to plain text: "New Worktree...", "Settings...", "Quit"

## 4. Tests

- [x] 4.1 Update or add test to verify all `get_color()` keys used in the codebase exist in all COLOR_PROFILES
- [x] 4.2 Verify existing GUI tests still pass after deletions (run `PYTHONPATH=. python -m pytest tests/gui/ -v --tb=short`)
