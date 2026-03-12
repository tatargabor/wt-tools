"""REST API endpoints for the wt-web dashboard.

Read endpoints for projects, orchestration state, changes, worktrees, activity, logs.
Write endpoints for approve, stop, skip.
"""

from __future__ import annotations

import fcntl
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from .process import check_pid, safe_kill
from .state import load_state, save_state, StateCorruptionError

router = APIRouter()

# ─── Project registry ─────────────────────────────────────────────────

PROJECTS_FILE = Path.home() / ".config" / "wt-tools" / "projects.json"


def _load_projects() -> list[dict]:
    """Load registered projects from ~/.config/wt-tools/projects.json."""
    if not PROJECTS_FILE.exists():
        return []
    try:
        with open(PROJECTS_FILE) as f:
            data = json.load(f)
        return data if isinstance(data, list) else []
    except (json.JSONDecodeError, OSError):
        return []


def _resolve_project(project_name: str) -> Path:
    """Resolve project name to its path. Raises 404 if not found."""
    for p in _load_projects():
        if p.get("name") == project_name:
            path = Path(p["path"])
            if path.is_dir():
                return path
            raise HTTPException(404, f"Project path does not exist: {path}")
    raise HTTPException(404, f"Project not found: {project_name}")


def _state_path(project_path: Path) -> Path:
    return project_path / "wt" / "orchestration" / "orchestration-state.json"


def _log_path(project_path: Path) -> Path:
    return project_path / "wt" / "orchestration" / "orchestration.log"


def _quick_status(project_path: Path) -> str:
    """Get quick orchestration status without full state parse."""
    sp = _state_path(project_path)
    if not sp.exists():
        return "idle"
    try:
        with open(sp) as f:
            data = json.load(f)
        return data.get("status", "idle")
    except (json.JSONDecodeError, OSError):
        return "error"


# ─── Worktree & activity helpers ──────────────────────────────────────


def _list_worktrees(project_path: Path) -> list[dict]:
    """List git worktrees for a project with loop-state enrichment."""
    try:
        result = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            cwd=project_path,
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode != 0:
            return []
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return []

    worktrees = []
    current: dict = {}
    for line in result.stdout.splitlines():
        if line.startswith("worktree "):
            if current:
                worktrees.append(current)
            current = {"path": line[9:], "branch": "", "head": ""}
        elif line.startswith("HEAD "):
            current["head"] = line[5:]
        elif line.startswith("branch "):
            current["branch"] = line[7:].replace("refs/heads/", "")
        elif line == "bare":
            current["bare"] = True
        elif line == "" and current:
            worktrees.append(current)
            current = {}
    if current:
        worktrees.append(current)

    # Enrich with loop-state
    for wt in worktrees:
        wt_path = Path(wt["path"])
        loop_state = wt_path / ".claude" / "loop-state.json"
        if loop_state.exists():
            try:
                with open(loop_state) as f:
                    ls = json.load(f)
                wt["iteration"] = ls.get("current_iteration", 0)
                wt["max_iterations"] = ls.get("max_iterations", 0)
            except (json.JSONDecodeError, OSError):
                pass

        # Agent activity
        activity_file = wt_path / ".claude" / "activity.json"
        if activity_file.exists():
            try:
                with open(activity_file) as f:
                    act = json.load(f)
                wt["activity"] = act
            except (json.JSONDecodeError, OSError):
                pass

    return worktrees


def _read_activity(project_path: Path) -> list[dict]:
    """Read agent activity from all worktrees."""
    activities = []
    for wt in _list_worktrees(project_path):
        if "activity" in wt:
            activities.append({
                "worktree": wt["path"],
                "branch": wt.get("branch", ""),
                **wt["activity"],
            })
    return activities


# ─── State locking ────────────────────────────────────────────────────


def _with_state_lock(state_file: Path, fn):
    """Execute fn while holding flock on state lock file.

    Compatible with bash with_state_lock (same lock file convention).
    """
    lock_path = str(state_file) + ".lock"
    lock_fd = open(lock_path, "w")
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        # Try with timeout — spin for up to 10 seconds
        import time
        deadline = time.monotonic() + 10
        acquired = False
        while time.monotonic() < deadline:
            try:
                fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                acquired = True
                break
            except BlockingIOError:
                time.sleep(0.1)
        if not acquired:
            lock_fd.close()
            raise HTTPException(503, "State file locked, try again")
    try:
        return fn()
    finally:
        fcntl.flock(lock_fd, fcntl.LOCK_UN)
        lock_fd.close()


# ─── READ endpoints ──────────────────────────────────────────────────


@router.get("/api/projects")
def list_projects():
    """List all registered projects with quick status."""
    projects = _load_projects()
    result = []
    for p in projects:
        path = Path(p.get("path", ""))
        result.append({
            "name": p.get("name", path.name),
            "path": str(path),
            "has_orchestration": _state_path(path).exists() if path.is_dir() else False,
            "status": _quick_status(path) if path.is_dir() else "error",
        })
    return result


@router.get("/api/{project}/state")
def get_state(project: str):
    """Get full orchestration state for a project."""
    project_path = _resolve_project(project)
    sp = _state_path(project_path)
    if not sp.exists():
        raise HTTPException(404, "No orchestration state found")
    try:
        state = load_state(str(sp))
        return state.to_dict()
    except StateCorruptionError as e:
        raise HTTPException(500, f"Corrupt state: {e.detail}")


@router.get("/api/{project}/changes")
def list_changes(project: str, status: Optional[str] = Query(None)):
    """List orchestration changes, optionally filtered by status."""
    project_path = _resolve_project(project)
    sp = _state_path(project_path)
    if not sp.exists():
        raise HTTPException(404, "No orchestration state found")
    try:
        state = load_state(str(sp))
    except StateCorruptionError as e:
        raise HTTPException(500, f"Corrupt state: {e.detail}")

    changes = state.changes
    if status:
        changes = [c for c in changes if c.status == status]

    result = []
    for c in changes:
        d = c.to_dict()
        # Enrich with loop-state if worktree exists
        if c.worktree_path and c.status == "running":
            loop_file = Path(c.worktree_path) / ".claude" / "loop-state.json"
            if loop_file.exists():
                try:
                    with open(loop_file) as f:
                        ls = json.load(f)
                    d["iteration"] = ls.get("current_iteration", 0)
                    d["max_iterations"] = ls.get("max_iterations", 0)
                except (json.JSONDecodeError, OSError):
                    pass
        result.append(d)
    return result


@router.get("/api/{project}/changes/{name}")
def get_change(project: str, name: str):
    """Get a single change by name."""
    project_path = _resolve_project(project)
    sp = _state_path(project_path)
    if not sp.exists():
        raise HTTPException(404, "No orchestration state found")
    try:
        state = load_state(str(sp))
    except StateCorruptionError as e:
        raise HTTPException(500, f"Corrupt state: {e.detail}")

    for c in state.changes:
        if c.name == name:
            d = c.to_dict()
            # Enrich with loop-state
            if c.worktree_path:
                loop_file = Path(c.worktree_path) / ".claude" / "loop-state.json"
                if loop_file.exists():
                    try:
                        with open(loop_file) as f:
                            ls = json.load(f)
                        d["iteration"] = ls.get("current_iteration", 0)
                        d["max_iterations"] = ls.get("max_iterations", 0)
                    except (json.JSONDecodeError, OSError):
                        pass
            return d
    raise HTTPException(404, f"Change not found: {name}")


@router.get("/api/{project}/worktrees")
def list_worktrees_endpoint(project: str):
    """List git worktrees with loop-state and activity data."""
    project_path = _resolve_project(project)
    return _list_worktrees(project_path)


@router.get("/api/{project}/activity")
def get_activity(project: str):
    """Get agent activity from all worktrees."""
    project_path = _resolve_project(project)
    return _read_activity(project_path)


@router.get("/api/{project}/log")
def get_log(project: str, lines: int = Query(500, ge=1, le=10000)):
    """Get the last N lines of the orchestration log."""
    project_path = _resolve_project(project)
    lp = _log_path(project_path)
    if not lp.exists():
        return {"lines": []}

    try:
        with open(lp, "rb") as f:
            # Efficient tail read: seek to end, read backwards
            f.seek(0, 2)
            file_size = f.tell()
            if file_size == 0:
                return {"lines": []}

            # Read in chunks from the end
            chunk_size = min(file_size, lines * 200)  # estimate ~200 bytes/line
            f.seek(max(0, file_size - chunk_size))
            content = f.read().decode("utf-8", errors="replace")

        all_lines = content.splitlines()
        return {"lines": all_lines[-lines:]}
    except OSError:
        return {"lines": []}


# ─── WRITE endpoints ─────────────────────────────────────────────────


@router.post("/api/{project}/approve")
def approve_checkpoint(project: str):
    """Approve the latest checkpoint."""
    project_path = _resolve_project(project)
    sp = _state_path(project_path)
    if not sp.exists():
        raise HTTPException(404, "No orchestration state found")

    def do_approve():
        state = load_state(str(sp))
        if state.status != "checkpoint":
            raise HTTPException(409, "Not at checkpoint")

        checkpoints = state.extras.get("checkpoints", [])
        if not checkpoints:
            # Try from dataclass field
            checkpoints = state.checkpoints
        if checkpoints:
            checkpoints[-1]["approved"] = True
            checkpoints[-1]["approved_at"] = datetime.now(timezone.utc).isoformat()

        save_state(state, str(sp))
        return {"ok": True}

    return _with_state_lock(sp, do_approve)


@router.post("/api/{project}/stop")
def stop_orchestration(project: str):
    """Stop the orchestration process."""
    project_path = _resolve_project(project)
    sp = _state_path(project_path)
    if not sp.exists():
        raise HTTPException(404, "No orchestration state found")

    try:
        state = load_state(str(sp))
    except StateCorruptionError as e:
        raise HTTPException(500, f"Corrupt state: {e.detail}")

    if state.status not in ("running", "checkpoint"):
        raise HTTPException(409, f"Not running (status: {state.status})")

    # Find orchestrator PID from state extras
    orch_pid = state.extras.get("orchestrator_pid") or state.extras.get("pid")
    if orch_pid:
        result = safe_kill(int(orch_pid), "wt-orchestrate")
        kill_result = result.outcome
    else:
        kill_result = "no_pid"

    def do_stop():
        s = load_state(str(sp))
        s.status = "stopped"
        save_state(s, str(sp))

    _with_state_lock(sp, do_stop)
    return {"ok": True, "kill_result": kill_result}


@router.post("/api/{project}/changes/{name}/stop")
def stop_change(project: str, name: str):
    """Stop a specific change's Ralph process."""
    project_path = _resolve_project(project)
    sp = _state_path(project_path)
    if not sp.exists():
        raise HTTPException(404, "No orchestration state found")

    try:
        state = load_state(str(sp))
    except StateCorruptionError as e:
        raise HTTPException(500, f"Corrupt state: {e.detail}")

    target = None
    for c in state.changes:
        if c.name == name:
            target = c
            break
    if target is None:
        raise HTTPException(404, f"Change not found: {name}")
    if target.status != "running":
        raise HTTPException(409, f"Change not running (status: {target.status})")

    kill_result = "no_pid"
    if target.ralph_pid:
        result = safe_kill(target.ralph_pid, "wt-loop")
        kill_result = result.outcome

    def do_stop_change():
        s = load_state(str(sp))
        for c in s.changes:
            if c.name == name:
                c.status = "stopped"
                break
        save_state(s, str(sp))

    _with_state_lock(sp, do_stop_change)
    return {"ok": True, "kill_result": kill_result}


@router.post("/api/{project}/changes/{name}/skip")
def skip_change(project: str, name: str):
    """Mark a change as skipped."""
    project_path = _resolve_project(project)
    sp = _state_path(project_path)
    if not sp.exists():
        raise HTTPException(404, "No orchestration state found")

    def do_skip():
        state = load_state(str(sp))
        for c in state.changes:
            if c.name == name:
                if c.status not in ("pending", "failed", "verify-failed", "stalled"):
                    raise HTTPException(409, f"Cannot skip change with status: {c.status}")
                c.status = "skipped"
                save_state(state, str(sp))
                return {"ok": True}
        raise HTTPException(404, f"Change not found: {name}")

    return _with_state_lock(sp, do_skip)
