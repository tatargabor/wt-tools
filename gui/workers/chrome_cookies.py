"""
Chrome Cookie Scanner - Extract Claude session cookies from Chrome profiles

Discovers all local Chrome profiles, resolves profile names,
and extracts sessionKey cookies for claude.ai using pycookiecheat.
"""

import json
import logging
import sys
from pathlib import Path

__all__ = ["scan_chrome_sessions", "is_pycookiecheat_available"]

logger = logging.getLogger("wt-control.chrome-cookies")


def is_pycookiecheat_available() -> bool:
    """Check if pycookiecheat is installed."""
    try:
        import pycookiecheat  # noqa: F401
        return True
    except ImportError:
        return False


def _get_chrome_data_dir() -> Path | None:
    """Get the platform-specific Chrome user data directory."""
    if sys.platform == "linux":
        path = Path.home() / ".config" / "google-chrome"
    elif sys.platform == "darwin":
        path = Path.home() / "Library" / "Application Support" / "Google" / "Chrome"
    else:
        return None

    return path if path.is_dir() else None


def _discover_profiles(chrome_dir: Path) -> list[Path]:
    """Discover Chrome profile directories containing a Preferences file."""
    profiles = []
    for entry in sorted(chrome_dir.iterdir()):
        if not entry.is_dir():
            continue
        # Chrome profiles are "Default", "Profile 1", "Profile 2", etc.
        if entry.name == "Default" or entry.name.startswith("Profile "):
            if (entry / "Preferences").exists():
                profiles.append(entry)
    return profiles


def _resolve_profile_name(profile_dir: Path) -> str:
    """Resolve a human-readable name from a Chrome profile's Preferences."""
    try:
        with open(profile_dir / "Preferences") as f:
            prefs = json.load(f)
    except Exception:
        return profile_dir.name

    # Try Google account name first
    account_info = prefs.get("account_info")
    if isinstance(account_info, list) and account_info:
        full_name = account_info[0].get("full_name", "")
        if full_name:
            return f"{full_name} ({profile_dir.name})"

    # Fallback to Chrome profile display name
    profile_name = prefs.get("profile", {}).get("name", "")
    if profile_name:
        return profile_name

    # Last resort: directory name
    return profile_dir.name


def _extract_session_cookie(profile_dir: Path) -> str | None:
    """Extract the sessionKey cookie for claude.ai from a Chrome profile."""
    try:
        from pycookiecheat import get_cookies
    except ImportError:
        return None

    cookie_file = profile_dir / "Cookies"
    if not cookie_file.exists():
        return None

    try:
        cookies = get_cookies(
            "https://claude.ai",
            cookie_file=str(cookie_file),
        )
        return cookies.get("sessionKey") or None
    except Exception as e:
        logger.debug("Failed to extract cookie from %s: %s", profile_dir.name, e)
        return None


def scan_chrome_sessions() -> list[dict]:
    """Scan all Chrome profiles for Claude session cookies.

    Returns a list of {"name": str, "sessionKey": str} dicts,
    one per profile that has a valid sessionKey cookie.
    Returns empty list if Chrome is not found or no sessions exist.
    Raises ImportError if pycookiecheat is not installed.
    """
    if not is_pycookiecheat_available():
        raise ImportError("pycookiecheat is not installed")

    chrome_dir = _get_chrome_data_dir()
    if not chrome_dir:
        logger.info("Chrome data directory not found")
        return []

    profiles = _discover_profiles(chrome_dir)
    if not profiles:
        logger.info("No Chrome profiles found in %s", chrome_dir)
        return []

    results = []
    for profile_dir in profiles:
        session_key = _extract_session_cookie(profile_dir)
        if session_key:
            name = _resolve_profile_name(profile_dir)
            results.append({"name": name, "sessionKey": session_key})
            logger.info("Found session for profile: %s", name)
        else:
            logger.debug("No Claude session in profile: %s", profile_dir.name)

    return results
