## Design: fix-gui-initial-bugs

### 1. Safari Session Import

**Problem:** `_import_browser_session()` doesn't try Safari.

**Solution:** Add Safari to the browsers list:
```python
browsers = [
    ("firefox", browser_cookie3.firefox),
    ("chrome", browser_cookie3.chrome),
    ("chromium", browser_cookie3.chromium),
    ("edge", browser_cookie3.edge),
    ("safari", browser_cookie3.safari),  # <-- NEW
]
```

### 2. Worktree List Initialization

**Problem:** The worktree list is empty at startup because `self.worktrees` isn't populated yet when the GUI appears.

**Solution:** The `refresh_status()` call in `__init__` already exists (line 111), but the worker may not have returned data yet. Need to verify that `StatusWorker` gets initial data synchronously.

### 3. Always-on-Top for Dialogs

**Problem:** On macOS, after opening dialogs, the main window loses its always-on-top status.

**Solution:**
- Explicit `raise_()` and `activateWindow()` call after dialog closure
- `raise_()` is also needed after `show()` on macOS

### 4. Work Dialog Operation

**Problem:** Opening worktrees from WorkDialog doesn't work.

**Solution:** Verify that SCRIPT_DIR/wt-work exists and is executable on macOS.
