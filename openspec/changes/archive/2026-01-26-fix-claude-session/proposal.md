# Fix Claude Session Management

## Summary
Replace hacky browser cookie scraping with a robust, cross-platform solution for Claude usage display that works on Linux, macOS, and Windows.

## Problem
1. **browser_cookie3 unreliable**: Depends on browser-specific cookie storage that changes between versions and platforms
2. **cloudscraper fragile**: Cloudflare bypass that can break anytime
3. **Not cross-platform**: Different browsers store cookies differently on each OS
4. **Not open-source friendly**: Scraping browser cookies feels like a hack, not a proper solution

## Analysis

### Available Data Sources

1. **Local JSONL files** (`~/.claude/projects/*/\*.jsonl`)
   - Contains per-message token usage data
   - Cross-platform, no authentication needed
   - Can calculate cumulative usage by aggregating recent messages
   - Used by ccusage tool

2. **Claude Analytics Admin API** (`/v1/organizations/usage_report/claude_code`)
   - Requires Admin API key (`sk-ant-admin...`)
   - Only available to organization admins, not personal accounts
   - Daily aggregated data, not real-time

3. **Claude.ai web interface** (`https://claude.ai/settings/usage`)
   - Real-time usage data
   - Requires session authentication
   - WebView login can capture session cookie

## Proposed Solution

**Primary: Local JSONL aggregation** (no auth needed, cross-platform)
- Parse local JSONL files to sum token usage
- Calculate 5h and weekly windows from timestamps
- Estimate usage percentage based on known limits

**Secondary: WebView login fallback** (for accurate real-time data)
- Keep WebView login dialog for users who want exact claude.ai data
- Use system default browser for OAuth instead of embedded WebView
- Store session key securely after successful login

## Scope
- `gui/workers/usage.py` - Replace browser cookie scraping with JSONL parsing
- `gui/dialogs/claude_login.py` - Improve WebView login flow
- `gui/constants.py` - Add usage calculation constants
- Remove dependency on `browser_cookie3` and `cloudscraper`

## Out of Scope
- Admin API integration (requires org setup)
- Real-time token streaming metrics
