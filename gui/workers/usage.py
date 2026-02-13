"""
Usage Worker - Background thread for fetching Claude usage data

Primary: Local JSONL parsing (cross-platform, no auth needed)
Secondary: Claude.ai API with session key (optional, for exact data)
"""

import json
import logging
import subprocess
import urllib.request
import urllib.error
from datetime import datetime, timezone

from PySide6.QtCore import QThread, Signal

from ..constants import CONFIG_DIR, CLAUDE_SESSION_FILE
from ..usage_calculator import UsageCalculator

try:
    from curl_cffi import requests as cffi_requests
except ImportError:
    cffi_requests = None

__all__ = ["UsageWorker"]

logger = logging.getLogger("wt-control.workers.usage")

_API_BASE = "https://claude.ai/api"
_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) wt-tools/1.0",
    "Accept": "application/json",
}


class UsageWorker(QThread):
    """Background thread for fetching Claude usage data"""
    usage_updated = Signal(dict)
    error_occurred = Signal(str)

    def __init__(self, config=None):
        super().__init__()
        self._running = True
        self._config = config
        self._calculator = UsageCalculator()
        self._cffi_warned = False

    def _get_limit(self, key: str, default: int) -> int:
        """Get usage limit from config"""
        if self._config:
            return self._config.get("usage", key, default)
        return default

    def _api_get(self, url: str, session_key: str):
        """Make an API GET request with session key cookie.

        Tries curl-cffi first (Chrome TLS fingerprint, bypasses Cloudflare),
        falls back to curl subprocess, then urllib.
        Returns parsed JSON or None on failure.
        """
        # Try curl-cffi first (impersonates Chrome TLS fingerprint)
        if cffi_requests is not None:
            try:
                resp = cffi_requests.get(
                    url,
                    headers={"Accept": "application/json"},
                    cookies={"sessionKey": session_key},
                    impersonate="chrome",
                    timeout=15,
                )
                if resp.status_code == 200:
                    return resp.json()
            except Exception:
                pass
        elif not self._cffi_warned:
            self._cffi_warned = True
            print("curl-cffi not installed — usage API may be blocked by Cloudflare. "
                  "Install with: pip install curl-cffi")

        # Fallback: try curl subprocess
        try:
            result = subprocess.run(
                ["curl", "-s", "-H", f"Cookie: sessionKey={session_key}",
                 "-H", "Accept: application/json",
                 "-H", f"User-Agent: {_HEADERS['User-Agent']}",
                 "--max-time", "15", url],
                capture_output=True, text=True, timeout=20
            )
            if result.returncode == 0 and result.stdout.strip():
                return json.loads(result.stdout)
        except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
            pass

        # Fallback: try urllib
        try:
            req = urllib.request.Request(url, headers=_HEADERS)
            req.add_header("Cookie", f"sessionKey={session_key}")
            with urllib.request.urlopen(req, timeout=15) as resp:
                if resp.status == 200:
                    return json.loads(resp.read().decode())
        except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError, OSError):
            pass

        return None

    def fetch_claude_api_usage(self, session_key):
        """Fetch usage from Claude.ai API using session key"""
        try:
            orgs = self._api_get(f"{_API_BASE}/organizations", session_key)
            if not orgs or not isinstance(orgs, list):
                return None

            # Find the claude_max org (not api org)
            org_id = None
            for org in orgs:
                if 'claude_max' in org.get('capabilities', []):
                    org_id = org.get('uuid')
                    break
            if not org_id:
                org_id = orgs[0].get('uuid')

            if not org_id:
                return None

            return self._fetch_org_usage(session_key, org_id)
        except Exception:
            return None

    def _fetch_org_usage(self, session_key, org_id):
        """Fetch usage for specific organization"""
        try:
            data = self._api_get(f"{_API_BASE}/organizations/{org_id}/usage", session_key)
            if not data:
                return None

            session_pct = data.get("five_hour", {}).get("utilization", 0) or 0
            session_reset = data.get("five_hour", {}).get("resets_at")
            weekly_pct = data.get("seven_day", {}).get("utilization", 0) or 0
            weekly_reset = data.get("seven_day", {}).get("resets_at")

            session_burn = self._calculate_burn_rate(session_pct, session_reset, 5)
            weekly_burn = self._calculate_burn_rate(weekly_pct, weekly_reset, 7 * 24)

            return {
                "available": True,
                "session_pct": session_pct,
                "session_reset": session_reset,
                "session_burn": session_burn,
                "weekly_pct": weekly_pct,
                "weekly_reset": weekly_reset,
                "weekly_burn": weekly_burn,
                "source": "api",
                "is_estimated": False,
            }
        except Exception:
            return None

    def _calculate_burn_rate(self, usage_pct, reset_time_str, window_hours):
        """Calculate burn rate based on time elapsed in window"""
        try:
            if not reset_time_str:
                return None

            reset_time = datetime.fromisoformat(reset_time_str.replace('Z', '+00:00'))
            now = datetime.now(timezone.utc)

            time_remaining = (reset_time - now).total_seconds() / 3600
            time_elapsed = window_hours - time_remaining

            if time_elapsed <= 0:
                return None

            expected_pct = (time_elapsed / window_hours) * 100
            if expected_pct <= 0:
                return None

            return (usage_pct / expected_pct) * 100
        except Exception:
            return None

    def fetch_local_usage(self):
        """Fetch usage from local JSONL files"""
        try:
            limit_5h = self._get_limit("estimated_5h_limit", 500_000)
            limit_weekly = self._get_limit("estimated_weekly_limit", 5_000_000)
            return self._calculator.get_usage_summary(
                limit_5h=limit_5h,
                limit_weekly=limit_weekly
            )
        except Exception as e:
            logger.error("local usage calculation error: %s", e)
            return None

    def _interruptible_sleep(self, ms):
        """Sleep in small increments so stop() takes effect quickly"""
        remaining = ms
        while remaining > 0 and self._running:
            chunk = min(remaining, 500)
            self.msleep(chunk)
            remaining -= chunk

    def run(self):
        while self._running:
            api_data = None

            # Try saved session first for accurate API data
            session_key = self._load_session()
            if session_key:
                api_data = self.fetch_claude_api_usage(session_key)

            if api_data:
                self.usage_updated.emit(api_data)
                self._interruptible_sleep(30000)
                continue

            # Fall back to local JSONL parsing (no auth needed)
            local_data = self.fetch_local_usage()
            if local_data:
                self.usage_updated.emit(local_data)
                self._interruptible_sleep(30000)
                continue

            # No data available
            self.usage_updated.emit({"available": False, "source": "none"})
            self._interruptible_sleep(30000)

    def _load_session(self):
        """Load saved session key from file"""
        try:
            if CLAUDE_SESSION_FILE.exists():
                with open(CLAUDE_SESSION_FILE) as f:
                    data = json.load(f)
                    key = data.get("sessionKey")
                    if key:
                        return key
        except Exception:
            pass
        return None

    def stop(self):
        self._running = False
