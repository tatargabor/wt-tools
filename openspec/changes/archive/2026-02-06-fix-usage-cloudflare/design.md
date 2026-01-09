## Context

The usage worker (`gui/workers/usage.py`) fetches Claude usage data from `claude.ai/api`. After removing `cloudscraper` (commit 440bcd08), plain `urllib` and `curl` get Cloudflare 403 responses because:
1. No `cf_clearance` cookie (requires JS challenge)
2. TLS fingerprint (JA3/JA4) identifies them as non-browser clients
3. Missing Client Hints headers (`Sec-CH-UA-*`)

`curl-cffi` is a Python binding for the curl-impersonate fork that can impersonate Chrome's TLS fingerprint. Tested and confirmed working against `claude.ai/api` — returns HTTP 200 where urllib and curl both get 403.

## Goals / Non-Goals

**Goals:**
- Restore working Claude.ai API usage fetching via `curl-cffi`
- Graceful degradation when `curl-cffi` is not installed
- Add `curl-cffi` to GUI requirements

**Non-Goals:**
- Using the standalone `curl-impersonate` binary (no arm64 macOS build available)
- Bringing back `cloudscraper` (unreliable, Cloudflare keeps breaking it)
- Headless browser approach (too heavy)

## Decisions

### Use `curl-cffi` Python package

**Decision**: Use `curl-cffi` (pip package) with `impersonate='chrome'` as the primary HTTP client for claude.ai API calls.

**Rationale**: pip install, pre-built arm64 macOS wheel, Python-native API. Tested: HTTP 200 against `claude.ai/api` where urllib/curl get 403. Same underlying tech as `curl-impersonate` binary but much easier to distribute.

**Alternatives considered**:
- `curl-impersonate` binary — No arm64 macOS release, brew formula broken (cmake compat issue)
- `cloudscraper` (Python) — Already removed, Cloudflare keeps breaking it
- `playwright` / headless Chrome — 150MB+ dependency, overkill for 2 API calls

### Fallback chain: curl-cffi → curl → urllib → local JSONL

**Decision**: Try `curl-cffi` first, then fall through existing chain. If `curl-cffi` is not installed, skip gracefully.

**Rationale**: `curl-cffi` is most likely to succeed. Optional import means no hard dependency — users who don't install it still get local JSONL fallback.

## Risks / Trade-offs

- **[Risk] `curl-cffi` not installed** → Falls back to existing chain (curl, urllib, local JSONL). No regression.
- **[Risk] Cloudflare starts fingerprinting curl-cffi** → Unlikely soon (uses real Chrome BoringSSL), but curl-cffi tracks Chrome versions. pip upgrade would fix.
- **[Risk] New pip dependency** → Small package (~5MB wheel), already installed successfully on target system.
