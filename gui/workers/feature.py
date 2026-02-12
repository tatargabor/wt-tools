"""
Feature Worker - Background thread for polling per-project feature status
(memory + openspec) to avoid blocking the UI thread.
"""

import json
import subprocess
import threading

from PySide6.QtCore import QThread, Signal

from ..constants import SCRIPT_DIR

__all__ = ["FeatureWorker"]

POLL_INTERVAL_MS = 15000  # 15 seconds


class FeatureWorker(QThread):
    """Background thread polling memory and openspec status per project."""
    features_updated = Signal(dict)

    def __init__(self):
        super().__init__()
        self._running = True
        self._projects = {}  # {project_name: main_repo_path}
        self._projects_lock = threading.Lock()
        self._refresh_event = threading.Event()

    def set_projects(self, projects: dict):
        """Update the project list. Called from UI thread.
        projects: {project_name: main_repo_path}"""
        with self._projects_lock:
            self._projects = dict(projects)

    def refresh_now(self):
        """Wake the worker for an immediate poll cycle."""
        self._refresh_event.set()

    def stop(self):
        self._running = False
        self._refresh_event.set()  # Wake from sleep

    def run(self):
        # First poll runs immediately
        self._poll_all()

        while self._running:
            # Sleep for interval, but wake early on refresh_now() or stop()
            self._refresh_event.wait(timeout=POLL_INTERVAL_MS / 1000.0)
            self._refresh_event.clear()

            if not self._running:
                break

            self._poll_all()

    def _poll_all(self):
        """Poll all projects and emit results."""
        with self._projects_lock:
            projects = dict(self._projects)

        if not projects:
            return

        result = {}
        for project, main_repo_path in projects.items():
            if not self._running:
                return
            result[project] = self._poll_project(project, main_repo_path)

        if self._running:
            self.features_updated.emit(result)

    def _poll_project(self, project: str, main_repo_path: str) -> dict:
        """Poll memory and openspec status for a single project."""
        memory = self._poll_memory(project)
        openspec = self._poll_openspec(main_repo_path)
        # Check memory hooks status if openspec is installed
        if openspec.get("installed") and openspec.get("skills_present"):
            hooks = self._poll_memory_hooks(main_repo_path)
            memory["hooks_installed"] = hooks.get("installed", False)
        return {"memory": memory, "openspec": openspec}

    def _poll_memory(self, project: str) -> dict:
        """Run wt-memory status --json --project X"""
        try:
            result = subprocess.run(
                [str(SCRIPT_DIR / "wt-memory"), "--project", project, "status", "--json"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0 and result.stdout.strip():
                data = json.loads(result.stdout.strip())
                return {"available": data.get("available", False), "count": data.get("count", 0)}
        except Exception:
            pass
        return {"available": False, "count": 0}

    def _poll_memory_hooks(self, main_repo_path: str) -> dict:
        """Run wt-memory-hooks check --json with cwd=main_repo"""
        if not main_repo_path:
            return {"installed": False, "files_total": 0, "files_patched": 0}
        try:
            result = subprocess.run(
                [str(SCRIPT_DIR / "wt-memory-hooks"), "check", "--json"],
                capture_output=True, text=True, timeout=5,
                cwd=main_repo_path
            )
            if result.returncode == 0 and result.stdout.strip():
                return json.loads(result.stdout.strip())
        except Exception:
            pass
        return {"installed": False, "files_total": 0, "files_patched": 0}

    def _poll_openspec(self, main_repo_path: str) -> dict:
        """Run wt-openspec status --json with cwd=main_repo"""
        if not main_repo_path:
            return {"installed": False, "changes_active": 0, "skills_present": False, "cli_available": False}
        try:
            result = subprocess.run(
                [str(SCRIPT_DIR / "wt-openspec"), "status", "--json"],
                capture_output=True, text=True, timeout=5,
                cwd=main_repo_path
            )
            if result.returncode == 0 and result.stdout.strip():
                return json.loads(result.stdout.strip())
        except Exception:
            pass
        return {"installed": False, "changes_active": 0, "skills_present": False, "cli_available": False}
