#!/usr/bin/env python3
"""wt-memory MCP server — exposes full wt-memory CLI as MCP tools.

Registered via: claude mcp add wt-memory -- python <path>/wt-memory-mcp-server.py
Uses stdio transport (standard MCP protocol).
All tools shell out to `wt-memory` CLI, ensuring branch boosting,
auto-tagging, dedup, and all custom logic applies equally to MCP calls.
"""

import json
import subprocess
import sys

from mcp.server import FastMCP

mcp = FastMCP("wt-memory", instructions=(
    "Memory tools for persistent project memory. "
    "Use these for deeper memory interactions when automatic hook-injected context isn't enough."
))


def _run(args: list[str], input_text: str | None = None, timeout: int = 30) -> str:
    """Run a wt-memory CLI command and return stdout."""
    try:
        result = subprocess.run(
            ["wt-memory"] + args,
            input=input_text,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        output = result.stdout.strip()
        if result.returncode != 0 and result.stderr:
            return f"Error: {result.stderr.strip()}"
        return output or "(no output)"
    except FileNotFoundError:
        return "Error: wt-memory not found in PATH"
    except subprocess.TimeoutExpired:
        return f"Error: command timed out after {timeout}s"


def _run_json(args: list[str], input_text: str | None = None) -> str:
    """Run a wt-memory CLI command and return parsed JSON or raw output."""
    raw = _run(args, input_text)
    try:
        parsed = json.loads(raw)
        return json.dumps(parsed, indent=2)
    except (json.JSONDecodeError, TypeError):
        return raw


# ============================================================
# Core tools
# ============================================================

@mcp.tool()
def remember(content: str, type: str = "Learning", tags: str = "") -> str:
    """Save a memory. Types: Decision, Learning, Context. Tags: comma-separated."""
    args = ["remember", "--type", type]
    if tags:
        args.extend(["--tags", tags])
    return _run(args, input_text=content)


@mcp.tool()
def recall(query: str, limit: int = 5, mode: str = "hybrid", tags: str = "") -> str:
    """Semantic search for memories. Modes: semantic, temporal, hybrid, causal, associative."""
    args = ["recall", query, "--limit", str(limit), "--mode", mode]
    if tags:
        args.extend(["--tags", tags])
    return _run_json(args)


@mcp.tool()
def proactive_context(context: str, limit: int = 5) -> str:
    """Context-aware retrieval with relevance scores. Richer than recall."""
    return _run_json(["proactive", context, "--limit", str(limit)])


@mcp.tool()
def forget(id: str) -> str:
    """Delete a single memory by ID."""
    return _run(["forget", id])


@mcp.tool()
def forget_by_tags(tags: str) -> str:
    """Delete all memories matching the given tags (comma-separated)."""
    return _run(["forget", "--tags", tags])


@mcp.tool()
def list_memories(type: str = "", limit: int = 20) -> str:
    """List memories. Optionally filter by type (Decision, Learning, Context)."""
    args = ["list", "--limit", str(limit)]
    if type:
        args.extend(["--type", type])
    return _run_json(args)


@mcp.tool()
def get_memory(id: str) -> str:
    """Get a single memory by ID (full details)."""
    return _run_json(["get", id])


@mcp.tool()
def context_summary(topic: str = "") -> str:
    """Condensed memory summary by category. Optionally filter by topic."""
    args = ["context"]
    if topic:
        args.append(topic)
    return _run(args)


@mcp.tool()
def brain() -> str:
    """3-tier memory visualization (core/active/peripheral)."""
    return _run(["brain"])


@mcp.tool()
def memory_stats() -> str:
    """Memory quality diagnostics: types, tags, importance distribution."""
    return _run_json(["stats", "--json"])


# ============================================================
# Maintenance tools
# ============================================================

@mcp.tool()
def health() -> str:
    """Check if shodh-memory is available and healthy."""
    return _run(["health"])


@mcp.tool()
def audit(threshold: float = 0.75) -> str:
    """Duplicate detection report. Lower threshold = stricter matching."""
    return _run_json(["audit", "--threshold", str(threshold), "--json"])


@mcp.tool()
def cleanup(threshold: float = 0.2, dry_run: bool = True) -> str:
    """Remove low-value memories. Set dry_run=False to actually delete."""
    args = ["cleanup", "--threshold", str(threshold)]
    if dry_run:
        args.append("--dry-run")
    return _run(args)


@mcp.tool()
def dedup(threshold: float = 0.75, dry_run: bool = True) -> str:
    """Remove duplicate memories. Set dry_run=False to actually delete."""
    args = ["dedup", "--threshold", str(threshold)]
    if dry_run:
        args.append("--dry-run")
    return _run(args)


# ============================================================
# Sync tools
# ============================================================

@mcp.tool()
def sync() -> str:
    """Push + pull memory sync in one step (git-based)."""
    return _run(["sync"], timeout=60)


@mcp.tool()
def sync_push() -> str:
    """Export and push memories to git remote."""
    return _run(["sync", "push"], timeout=60)


@mcp.tool()
def sync_pull(from_source: str = "") -> str:
    """Pull and import memories from git remote."""
    args = ["sync", "pull"]
    if from_source:
        args.extend(["--from", from_source])
    return _run(args, timeout=60)


@mcp.tool()
def sync_status() -> str:
    """Show memory sync state and remote sources."""
    return _run(["sync", "status"])


# ============================================================
# Export/Import tools
# ============================================================

@mcp.tool()
def export_memories() -> str:
    """Export all memories to JSON."""
    return _run_json(["export"])


@mcp.tool()
def import_memories(file_path: str, dry_run: bool = True) -> str:
    """Import memories from a JSON file. Set dry_run=False to actually import."""
    args = ["import", file_path]
    if dry_run:
        args.append("--dry-run")
    return _run(args, timeout=60)


# ============================================================
# Todo tools
# ============================================================

@mcp.tool()
def add_todo(content: str, tags: str = "") -> str:
    """Save a todo/idea for later. Fire-and-forget capture."""
    args = ["todo", "add"]
    if tags:
        args.extend(["--tags", tags])
    return _run(args, input_text=content)


@mcp.tool()
def list_todos() -> str:
    """List all open todos."""
    return _run_json(["todo", "list", "--json"])


@mcp.tool()
def complete_todo(id: str) -> str:
    """Mark a todo as done (deletes it). Supports ID prefix matching."""
    return _run(["todo", "done", id])


# ============================================================
# API parity tools (shodh-memory 0.1.81+)
# ============================================================

@mcp.tool()
def verify_index() -> str:
    """Verify index integrity — find orphaned memories not in vector index."""
    return _run_json(["verify"])


@mcp.tool()
def consolidation_report(since: str = "") -> str:
    """Memory consolidation report — strengthening/decay events."""
    args = ["consolidation"]
    if since:
        args.extend(["--since", since])
    return _run_json(args)


@mcp.tool()
def graph_stats() -> str:
    """Knowledge graph statistics (node count, edge count, etc.)."""
    return _run_json(["graph-stats"])


@mcp.tool()
def recall_by_date(since: str = "", until: str = "", limit: int = 20) -> str:
    """Recall memories within a date range. ISO 8601 dates."""
    args = ["recall", "--limit", str(limit)]
    if since:
        args.extend(["--since", since])
    if until:
        args.extend(["--until", until])
    return _run_json(args)


# ============================================================
# Entry point
# ============================================================

if __name__ == "__main__":
    mcp.run(transport="stdio")
