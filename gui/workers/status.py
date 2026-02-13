"""
Status Worker - Background thread for polling wt-status
"""

import json
import logging
import subprocess

from PySide6.QtCore import QThread, Signal

from ..constants import SCRIPT_DIR
from ..config import Config

__all__ = ["StatusWorker"]

logger = logging.getLogger("wt-control.workers.status")


class StatusWorker(QThread):
    """Background thread for polling wt-status"""
    status_updated = Signal(dict)
    error_occurred = Signal(str)

    def __init__(self, config: Config):
        super().__init__()
        self._running = True
        self.config = config

    def run(self):
        while self._running:
            try:
                result = subprocess.run(
                    [str(SCRIPT_DIR / "wt-status"), "--json"],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                if result.returncode == 0:
                    data = json.loads(result.stdout)
                    self.status_updated.emit(data)
                else:
                    self.error_occurred.emit(result.stderr)
            except subprocess.TimeoutExpired:
                logger.error("wt-status timed out")
                self.error_occurred.emit("Status check timed out")
            except json.JSONDecodeError as e:
                logger.error("wt-status invalid JSON: %s", e)
                self.error_occurred.emit(f"Invalid JSON: {e}")
            except Exception as e:
                logger.error("wt-status error: %s", e)
                self.error_occurred.emit(str(e))

            # Sleep for configured interval
            self.msleep(self.config.control_center["refresh_interval_ms"])

    def stop(self):
        self._running = False
