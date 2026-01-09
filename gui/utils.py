"""
Utility functions for the GUI
"""

import subprocess
from pathlib import Path

__all__ = ["get_version", "get_main_repo_path"]


def get_version() -> str:
    """Get version from pyproject.toml"""
    try:
        pyproject = Path(__file__).parent.parent / "pyproject.toml"
        for line in pyproject.read_text().splitlines():
            if line.startswith("version"):
                return line.split('"')[1]
    except Exception:
        pass
    return "0.0.0"


def get_main_repo_path(worktree_path: str) -> str:
    """Get the main repo path from a worktree path using git worktree list"""
    try:
        result = subprocess.run(
            ["git", "-C", worktree_path, "worktree", "list", "--porcelain"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            # First "worktree" line is the main repo
            for line in result.stdout.split("\n"):
                if line.startswith("worktree "):
                    return line[9:]  # Remove "worktree " prefix
    except Exception:
        pass
    return ""
