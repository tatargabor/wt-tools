## Why

The usage monitor's Claude.ai API calls are blocked by Cloudflare since the `cloudscraper` dependency was removed (commit 440bcd08). Plain `urllib` and `curl` cannot pass Cloudflare's JS challenge + TLS fingerprint checks, so the API path always fails and users only see "--/5h" (local fallback). We need a Cloudflare bypass that works without a full browser engine.

## What Changes

- Add `curl-impersonate` as the HTTP client for claude.ai API calls — it uses Chrome's TLS fingerprint (JA3/JA4) so Cloudflare treats it as a real browser
- Update the `UsageWorker._api_get()` method to try `curl_chrome131` (or latest available variant) before falling back to plain `curl`
- Add install-time detection/guidance for `curl-impersonate` (brew install on macOS, package on Linux)
- Keep plain `curl` and `urllib` as final fallbacks (in case Cloudflare relaxes checks in the future)

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `usage-display`: The "Cloudflare fallback" requirement changes from plain `curl` to `curl-impersonate` as the primary bypass strategy

## Impact

- `gui/workers/usage.py` — `_api_get()` method gains `curl-impersonate` path
- `install.sh` / `install.ps1` — detect or suggest `curl-impersonate` installation
- No new Python dependencies (curl-impersonate is an external binary, like `curl` itself)
