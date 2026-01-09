## Why

The current usage tracking relies on `cloudscraper` and `browser_cookie3` for session authentication, plus a heavy `QtWebEngine` login dialog. These dependencies are unreliable (Cloudflare blocks, Safari keychain popups, encrypted Chrome cookies) and add significant weight. Meanwhile, the local JSONL-based `UsageCalculator` already provides accurate token counts but the CLI (`wt-usage`) only outputs raw numbers without time-range options or cost estimates. The third-party `claude-monitor` package was evaluated and found redundant — it reads the same JSONL files we already parse.

## What Changes

- **Upgrade `wt-usage` CLI**: Add `--today`, `--week`, `--month` time range flags, `--cost` for estimated USD cost, and improved text output formatting
- **Add `--login` flow**: Opens default browser to claude.ai, prompts user to paste sessionKey from DevTools — replaces WebEngine login dialog
- **Simplify `UsageWorker`**: Replace `cloudscraper` with standard `urllib.request` for claude.ai API calls
- **GUI session key input**: Replace `ClaudeLoginDialog` (WebEngine) with simple `QInputDialog` for pasting session key
- **Remove heavy dependencies**: Drop `cloudscraper`, `browser_cookie3`, and `QtWebEngine` login dialog
- **Remove `claude-monitor`**: `pip uninstall claude-monitor` — redundant with our existing `UsageCalculator`
- **Add cost estimation**: Hardcoded per-model token prices in `UsageCalculator` for approximate USD cost

## Capabilities

### New Capabilities
- `usage-cli`: CLI token usage reporting with time ranges, cost estimates, and session key login flow

### Modified Capabilities
- `usage-display`: Remove cloudscraper/browser_cookie3 dependencies, simplify session key acquisition to manual paste, add cost estimation support

## Impact

- **Files modified**: `bin/wt-usage`, `gui/usage_calculator.py`, `gui/workers/usage.py`, `gui/constants.py`, `gui/control_center/mixins/handlers.py`, `gui/control_center/mixins/menu_builder.py`, `gui/requirements.txt`
- **Files removed**: `gui/dialogs/claude_login.py`
- **Dependencies removed**: `cloudscraper`, `browser_cookie3`
- **Dependencies added**: none (uses stdlib `urllib.request`)
- **Packages uninstalled**: `claude-monitor`
