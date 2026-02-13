"""
Logging setup for the Control Center GUI.

Configures a rotating file logger at the platform temp directory.
All GUI modules use child loggers under the 'wt-control' root.
"""

import logging
import sys
import tempfile
from functools import wraps
from logging.handlers import RotatingFileHandler
from pathlib import Path


def setup_logging():
    """Initialize GUI logging with rotating file handler.

    Log file: /tmp/wt-control.log (macOS/Linux) or %TEMP%/wt-control.log (Windows)
    Rotation: 5 MB max, 3 backup files.
    """
    if sys.platform == "win32":
        log_path = Path(tempfile.gettempdir()) / "wt-control.log"
    else:
        log_path = Path("/tmp") / "wt-control.log"

    root_logger = logging.getLogger("wt-control")
    root_logger.setLevel(logging.DEBUG)

    # Avoid duplicate handlers on restart
    if root_logger.handlers:
        return

    handler = RotatingFileHandler(
        str(log_path),
        maxBytes=5 * 1024 * 1024,
        backupCount=3,
        encoding="utf-8",
    )
    handler.setLevel(logging.DEBUG)

    formatter = logging.Formatter(
        "%(asctime)s %(levelname)s %(name)s:%(funcName)s %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    handler.setFormatter(formatter)
    root_logger.addHandler(handler)

    root_logger.info(
        "GUI starting — Python %s, %s",
        sys.version.split()[0],
        sys.platform,
    )


def log_exceptions(func):
    """Decorator that logs exceptions in Qt signal handlers.

    Qt swallows exceptions in signal-connected slots. This decorator
    catches, logs, and re-raises them so they appear in the log file.
    """
    logger = logging.getLogger("wt-control.handlers")

    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception:
            logger.exception("Exception in %s", func.__name__)
            raise

    return wrapper
