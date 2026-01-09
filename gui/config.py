"""
Configuration manager for the GUI
"""

import json
from pathlib import Path

from .constants import CONFIG_FILE, CONFIG_DIR, DEFAULT_CONFIG

__all__ = ["Config"]


class Config:
    """Configuration manager for the GUI"""

    def __init__(self):
        self._config = self._deep_copy(DEFAULT_CONFIG)
        self.load()

    def _deep_copy(self, d):
        """Deep copy a nested dict"""
        if isinstance(d, dict):
            return {k: self._deep_copy(v) for k, v in d.items()}
        return d

    def _merge(self, base, override):
        """Merge override into base, adding new keys from override"""
        for key, value in override.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._merge(base[key], value)
            else:
                base[key] = value

    def load(self):
        """Load config from file, merging with defaults"""
        if CONFIG_FILE.exists():
            try:
                with open(CONFIG_FILE) as f:
                    loaded = json.load(f)
                    self._merge(self._config, loaded)
            except (json.JSONDecodeError, IOError):
                pass  # Use defaults on error

    def save(self):
        """Save config to file"""
        try:
            CONFIG_DIR.mkdir(parents=True, exist_ok=True)
            with open(CONFIG_FILE, "w") as f:
                json.dump(self._config, f, indent=2)
        except IOError:
            pass

    def get(self, section, key, default=None):
        """Get a config value"""
        return self._config.get(section, {}).get(key, default)

    def set(self, section, key, value):
        """Set a config value"""
        if section not in self._config:
            self._config[section] = {}
        self._config[section][key] = value

    @property
    def control_center(self):
        return self._config["control_center"]

    @property
    def git(self):
        return self._config["git"]

    @property
    def notifications(self):
        return self._config["notifications"]

    @property
    def team(self):
        return self._config.get("team", DEFAULT_CONFIG["team"])
