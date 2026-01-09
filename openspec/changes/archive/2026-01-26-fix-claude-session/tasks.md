# Tasks

## Phase 1: Local JSONL Usage Calculation

1. [x] Create `gui/usage_calculator.py` module
   - Parse JSONL files from `~/.claude/projects/`
   - Extract token usage from `message.usage` objects
   - Filter by timestamp for time windows
   - Sum input/output/cache tokens
   - Cross-platform path handling with `pathlib`

2. [x] Add usage estimation logic
   - Calculate 5h window usage (messages in last 5 hours)
   - Calculate 7-day window usage
   - Estimate percentage based on configurable limits
   - Return structured data matching current API format

3. [x] Update `gui/workers/usage.py`
   - Use API as primary source when session available
   - Use JSONL calculator as fallback (no auth needed)
   - Remove `get_session_from_browser()` method
   - Remove `browser_cookie3` dependency

4. [x] Add estimated limits to config
   - Add `usage.estimated_5h_limit` setting (default: 500000 tokens)
   - Add `usage.estimated_weekly_limit` setting (default: 5000000 tokens)
   - Add `usage.show_estimated_indicator` setting (default: true)

## Phase 2: Improve WebView Login (Optional)

5. [ ] Improve `gui/dialogs/claude_login.py`
   - Add "Open in browser" button for OAuth
   - Better cookie capture with retry logic
   - Show success message when session captured

6. [ ] Add session validation
   - Test session before storing
   - Clear invalid sessions automatically
   - Show login prompt when session expires

## Phase 3: Cleanup & Cross-Platform

7. [x] Remove unused dependencies
   - Remove `browser_cookie3` from requirements
   - Keep `cloudscraper` (only used after explicit login)

8. [x] Update UI indicators
   - Show "~" prefix for estimated values (local data)
   - Show usage percentages like claude.ai: "17% | 1h 37m"
   - Add tooltip explaining data source

9. [x] Cross-platform path handling
   - Use `Path.home() / ".claude"` for all platforms
   - Renamed `gui/platform` to `gui/platforms` to avoid stdlib collision
   - Handle missing directories gracefully

## Phase 4: Testing

10. [x] Test on Linux (Ubuntu/Debian)
    - Verified JSONL parsing works
    - Verified API usage fetching works
    - Verified usage display shows correct percentages

11. [ ] Test on macOS (if available)
    - Verify path handling
    - Verify Qt/PySide6 works
    - Document any platform-specific issues

12. [ ] Test on Windows (if available)
    - Verify path handling with backslashes
    - Verify PySide6 works
    - Document any platform-specific issues

## Summary of Changes

### Files Created
- `gui/usage_calculator.py` - Local JSONL token usage calculator

### Files Modified
- `gui/workers/usage.py` - Simplified to use API first, local fallback
- `gui/constants.py` - Added usage config defaults
- `gui/control_center/main_window.py` - Updated display to match claude.ai format
- `gui/control_center/mixins/handlers.py` - Pass config to UsageWorker
- `gui/requirements.txt` - Removed browser_cookie3
- `pyproject.toml` - Removed browser_cookie3

### Files Renamed
- `gui/platform/` → `gui/platforms/` - Fixed stdlib collision with `platform` module
