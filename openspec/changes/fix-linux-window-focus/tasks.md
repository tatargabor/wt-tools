## 1. WM_CLASS Mapping and find_window_by_title Fix

- [x] 1.1 Add `_WM_CLASS_MAP` dict to `LinuxPlatform` mapping app_name to WM_CLASS (Zed → dev.zed.Zed, Code → code, Cursor → cursor, Windsurf → windsurf)
- [x] 1.2 Rewrite `find_window_by_title()` to use two-step approach: filter by `--class` when `app_name` is provided, then Python-side precise title matching (exact or "basename — " prefix)
- [x] 1.3 When `app_name` is not provided or not in the map, fall back to current `xdotool search --name` behavior

## 2. Tests

- [x] 2.1 Add GUI test in `tests/gui/test_27_linux_window_focus.py` covering: WM_CLASS filtering, precise title matching (exact, folder+file pattern, rejection of prefix-similar worktrees), fallback when no app_name
