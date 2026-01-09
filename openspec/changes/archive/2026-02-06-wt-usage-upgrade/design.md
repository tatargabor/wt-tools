## Context

The Control Center GUI and `wt-usage` CLI both track Claude token usage. Currently:
- `gui/usage_calculator.py` parses local JSONL files from `~/.claude/projects/` — works reliably, no auth needed
- `gui/workers/usage.py` (`UsageWorker`) tries claude.ai API with sessionKey cookie via `cloudscraper`, falls back to local JSONL
- `gui/dialogs/claude_login.py` provides a WebEngine-based login dialog to capture the sessionKey cookie
- `bin/wt-usage` is a thin CLI wrapper over `UsageCalculator` with basic JSON/text output
- `browser_cookie3` attempts automatic session import from browsers (unreliable across platforms)

The claude.ai API provides exact utilization percentages and reset times, but the authentication path is fragile. Local JSONL provides accurate token counts but cannot determine the actual usage limit or reset time.

## Goals / Non-Goals

**Goals:**
- Simplify session key acquisition to manual paste (browser DevTools → terminal/GUI)
- Upgrade `wt-usage` CLI with time ranges (`--today`, `--week`, `--month`), cost estimates, and better formatting
- Remove heavy/unreliable dependencies: `cloudscraper`, `browser_cookie3`, `QtWebEngine` login dialog
- Replace `cloudscraper` with stdlib `urllib.request` for API calls
- Add per-model cost estimation to `UsageCalculator`

**Non-Goals:**
- Automatic browser cookie extraction (proven unreliable)
- OAuth flow or localhost callback server (sessionKey is not an OAuth token)
- Determining exact Anthropic rate limits (they are not published)
- Real-time monitoring TUI (claude-monitor territory, not our goal)

## Decisions

### 1. Manual sessionKey paste over WebEngine login

**Decision**: Replace the WebEngine login dialog with a simple paste flow.

**CLI**: `wt-usage --login` opens `https://claude.ai` in default browser, prompts user to copy sessionKey from DevTools → Application → Cookies, paste into terminal.

**GUI**: Menu item "Set Session Key..." opens `QInputDialog.getText()`.

**Rationale**: WebEngine is a heavy dependency that requires QtWebEngine. Browser cookie extraction via `browser_cookie3` is unreliable (Safari keychain popup, Chrome encrypted cookies, platform differences). Manual paste is simple, reliable, and user-controlled.

**Alternatives considered**:
- Keep WebEngine dialog → too heavy, instable
- Browser extension → overkill for this use case
- Bookmarklet to copy cookie → HTTP-only cookies not accessible from JS

### 2. stdlib `urllib.request` instead of `cloudscraper`

**Decision**: Use `urllib.request` with proper headers for claude.ai API calls.

**Rationale**: The cloudscraper was needed for Cloudflare JS challenge bypass on the login page. For authenticated API calls (`/api/organizations`, `/api/organizations/{id}/usage`) with a valid sessionKey cookie, standard HTTP requests with proper User-Agent should work. If Cloudflare blocks these, fallback to `curl` subprocess.

**Fallback**: If `urllib.request` gets blocked by Cloudflare, use `subprocess.run(["curl", ...])` as backup.

### 3. Cost estimation with hardcoded prices

**Decision**: Add `estimate_cost()` to `UsageCalculator` using hardcoded per-model token prices.

**Prices** (as of Feb 2026):
- claude-opus-4: $15/M input, $75/M output, $3.75/M cache read, $18.75/M cache write
- claude-sonnet-4: $3/M input, $15/M output, $0.30/M cache read, $3.75/M cache write
- claude-haiku-4: $0.80/M input, $4/M output, $0.08/M cache read, $1/M cache write

**Rationale**: Prices change infrequently. Hardcoding avoids external API calls. Users understand these are estimates (displayed with "~" prefix). Prices can be updated in a single dict when needed.

### 4. `wt-usage` CLI output format

**Default** (no flags): 5h window token summary
**`--today`/`--week`/`--month`**: Specific time range
**`--cost`**: Include estimated USD cost
**`--login`**: Session key acquisition flow
**`--format json|text`**: Output format (existing, kept)

Text output example:
```
Claude Usage (today):
  Input tokens:     1,234
  Output tokens:    5,678
  Cache read:      45,000
  Cache create:    12,000
  Total:           63,912
  Est. cost:       ~$2.45

Session: 47% | resets in 2h 13m    (exact, via API)
Weekly:  12% | resets in 5d 8h     (exact, via API)
```

If no sessionKey: session/weekly lines show token totals instead of percentages.

## Risks / Trade-offs

- **[Cloudflare blocks urllib]** → Mitigation: Fall back to `curl` subprocess. If both fail, gracefully degrade to local-only mode (already working).
- **[SessionKey expires frequently]** → Mitigation: Clear error message suggesting `wt-usage --login` again. UsageWorker falls back to local data automatically.
- **[Hardcoded prices become stale]** → Mitigation: Prices in a single dict, easy to update. Display with "~" prefix so users know it's estimated.
- **[Removing claude_login.py breaks menu references]** → Mitigation: Replace menu action with QInputDialog-based session key paste. Remove all imports of ClaudeLoginDialog.
