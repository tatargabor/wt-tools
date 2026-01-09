## 1. API client update

- [x] 1.1 Add `_api_get_cffi()` method to `UsageWorker` that uses `curl_cffi.requests` with `impersonate='chrome'` to make API calls
- [x] 1.2 Update `_api_get()` fallback chain: try curl-cffi first, then curl subprocess, then urllib
- [x] 1.3 Handle missing `curl-cffi` gracefully (optional import, log once if not available)

## 2. Dependencies

- [x] 2.1 Add `curl-cffi` to `gui/requirements.txt`
- [x] 2.2 Add `curl-cffi` install to `install.sh` and `install.ps1` (both already install from requirements.txt)
