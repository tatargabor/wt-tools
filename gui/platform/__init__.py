"""Platform abstraction layer for cross-platform support.

This module provides platform-specific implementations for operations that
differ between Linux, macOS, and Windows.

Usage:
    from gui.platform import get_platform

    plat = get_platform()
    if plat.is_process_running(pid):
        print("Process is running")
"""

import importlib.util
import os
import sys
from typing import Optional

from .base import PlatformInterface

# Import the real stdlib 'platform' module, not this gui/platform package.
# This package shadows the stdlib name, so we load it directly from the stdlib path.
def _load_stdlib_platform():
    # Find stdlib directory (where os.py lives)
    stdlib_dir = os.path.dirname(os.__file__)
    stdlib_platform_path = os.path.join(stdlib_dir, "platform.py")
    spec = importlib.util.spec_from_file_location("_stdlib_platform", stdlib_platform_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

_stdlib_platform = _load_stdlib_platform()

# Detect current platform
PLATFORM_NAME = _stdlib_platform.system().lower()
if PLATFORM_NAME == "darwin":
    PLATFORM_NAME = "darwin"  # macOS
elif PLATFORM_NAME == "windows":
    PLATFORM_NAME = "windows"
else:
    PLATFORM_NAME = "linux"  # Default to Linux for other Unix-like systems

# Singleton instance
_platform_instance: Optional[PlatformInterface] = None


def get_platform() -> PlatformInterface:
    """Get the platform implementation for the current OS.

    Returns a singleton instance of the appropriate platform class.
    """
    global _platform_instance

    if _platform_instance is None:
        _platform_instance = _create_platform()

    return _platform_instance


def platform_instance() -> PlatformInterface:
    """Alias for get_platform() for compatibility."""
    return get_platform()


def _create_platform() -> PlatformInterface:
    """Create the appropriate platform implementation."""
    if PLATFORM_NAME == "linux":
        from .linux import LinuxPlatform
        return LinuxPlatform()
    elif PLATFORM_NAME == "darwin":
        from .macos import MacOSPlatform
        return MacOSPlatform()
    elif PLATFORM_NAME == "windows":
        from .windows import WindowsPlatform
        return WindowsPlatform()
    else:
        # Fallback to Linux for unknown platforms
        from .linux import LinuxPlatform
        return LinuxPlatform()


__all__ = [
    "PlatformInterface",
    "PLATFORM_NAME",
    "get_platform",
    "platform_instance",
]
