"""Memory metrics collection, persistence, and reporting.

SQLite-backed storage for hook injection metrics. Data flows:
1. Hooks append per-injection records to session cache (_metrics array)
2. Stop hook flushes session cache to SQLite
3. CLI commands query SQLite for reports and dashboards
"""

import json
import os
import sqlite3
import time
from datetime import datetime, timedelta
from pathlib import Path

# --- Paths ---

METRICS_DIR = os.path.join(os.path.expanduser("~"), ".local", "share", "wt-tools", "metrics")
METRICS_DB = os.path.join(METRICS_DIR, "metrics.db")
ENABLED_FLAG = os.path.join(METRICS_DIR, ".enabled")


def is_enabled():
    """Check if metrics collection is enabled."""
    return os.path.exists(ENABLED_FLAG)


def enable():
    """Enable metrics collection."""
    os.makedirs(METRICS_DIR, exist_ok=True)
    Path(ENABLED_FLAG).touch()


def disable():
    """Disable metrics collection."""
    try:
        os.remove(ENABLED_FLAG)
    except FileNotFoundError:
        pass


# --- SQLite Schema ---

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    project TEXT,
    started_at TEXT,
    ended_at TEXT,
    total_injections INTEGER,
    total_tokens INTEGER,
    citation_count INTEGER,
    layers_json TEXT
);

CREATE TABLE IF NOT EXISTS injections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    ts TEXT,
    layer TEXT,
    event TEXT,
    query TEXT,
    result_count INTEGER,
    filtered_count INTEGER,
    avg_relevance REAL,
    max_relevance REAL,
    min_relevance REAL,
    duration_ms INTEGER,
    token_estimate INTEGER,
    dedup_hit INTEGER
);

CREATE TABLE IF NOT EXISTS citations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    citation_text TEXT,
    citation_type TEXT
);

CREATE INDEX IF NOT EXISTS idx_injections_session ON injections(session_id);
CREATE INDEX IF NOT EXISTS idx_injections_ts ON injections(ts);
CREATE INDEX IF NOT EXISTS idx_sessions_project ON sessions(project);
CREATE INDEX IF NOT EXISTS idx_sessions_ended ON sessions(ended_at);
"""


def _get_db():
    """Get a SQLite connection, creating schema if needed."""
    os.makedirs(METRICS_DIR, exist_ok=True)
    conn = sqlite3.connect(METRICS_DB, timeout=5)
    conn.row_factory = sqlite3.Row
    conn.executescript(SCHEMA_SQL)
    return conn


# --- Write Operations (called from Stop hook) ---

def flush_session(session_id, project, metrics_records, citations_list=None):
    """Flush a session's metrics from cache to SQLite.

    Args:
        session_id: Claude Code session ID
        project: Project name
        metrics_records: List of injection metric dicts from session cache _metrics
        citations_list: Optional list of citation dicts {text, type}
    """
    if not metrics_records:
        return

    try:
        conn = _get_db()
    except Exception:
        return

    try:
        # Insert injection records
        for rec in metrics_records:
            conn.execute(
                """INSERT INTO injections
                   (session_id, ts, layer, event, query, result_count, filtered_count,
                    avg_relevance, max_relevance, min_relevance,
                    duration_ms, token_estimate, dedup_hit)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    session_id,
                    rec.get("ts", ""),
                    rec.get("layer", ""),
                    rec.get("event", ""),
                    rec.get("query", "")[:500],
                    rec.get("result_count", 0),
                    rec.get("filtered_count", 0),
                    rec.get("avg_relevance"),
                    rec.get("max_relevance"),
                    rec.get("min_relevance"),
                    rec.get("duration_ms", 0),
                    rec.get("token_estimate", 0),
                    rec.get("dedup_hit", 0),
                ),
            )

        # Insert citations
        if citations_list:
            for cit in citations_list:
                conn.execute(
                    "INSERT INTO citations (session_id, citation_text, citation_type) VALUES (?, ?, ?)",
                    (session_id, cit.get("text", "")[:500], cit.get("type", "explicit")),
                )

        # Compute session summary
        timestamps = [r.get("ts", "") for r in metrics_records if r.get("ts")]
        started_at = min(timestamps) if timestamps else ""
        ended_at = datetime.utcnow().isoformat() + "Z"
        total_tokens = sum(r.get("token_estimate", 0) for r in metrics_records)
        citation_count = len(citations_list) if citations_list else 0

        # Per-layer summary
        layers = {}
        for rec in metrics_records:
            layer = rec.get("layer", "unknown")
            if layer not in layers:
                layers[layer] = {"count": 0, "tokens": 0, "relevance_sum": 0.0, "relevance_n": 0}
            layers[layer]["count"] += 1
            layers[layer]["tokens"] += rec.get("token_estimate", 0)
            avg_rel = rec.get("avg_relevance")
            if avg_rel is not None:
                layers[layer]["relevance_sum"] += avg_rel
                layers[layer]["relevance_n"] += 1

        conn.execute(
            """INSERT OR REPLACE INTO sessions
               (id, project, started_at, ended_at, total_injections, total_tokens, citation_count, layers_json)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                session_id,
                project,
                started_at,
                ended_at,
                len(metrics_records),
                total_tokens,
                citation_count,
                json.dumps(layers),
            ),
        )

        conn.commit()
    except Exception:
        pass
    finally:
        conn.close()


# --- Read Operations (called from CLI) ---

def _since_clause(since_days):
    """Build a date cutoff ISO string."""
    cutoff = datetime.utcnow() - timedelta(days=since_days)
    return cutoff.isoformat() + "Z"


def query_report(since_days=7):
    """Query aggregated metrics for reporting.

    Returns dict with all data needed for TUI and HTML reports.
    """
    if not os.path.exists(METRICS_DB):
        return None

    try:
        conn = _get_db()
    except Exception:
        return None

    try:
        cutoff = _since_clause(since_days)

        # Session summary
        row = conn.execute(
            """SELECT COUNT(*) as cnt, COALESCE(SUM(total_injections),0) as inj,
                      COALESCE(SUM(total_tokens),0) as tok, COALESCE(SUM(citation_count),0) as cit
               FROM sessions WHERE ended_at >= ?""",
            (cutoff,),
        ).fetchone()
        session_count = row["cnt"]
        total_injections = row["inj"]
        total_tokens = row["tok"]
        total_citations = row["cit"]

        if session_count == 0:
            conn.close()
            return None

        # Per-layer breakdown
        layers = conn.execute(
            """SELECT layer, COUNT(*) as cnt,
                      COALESCE(AVG(token_estimate),0) as avg_tok,
                      COALESCE(AVG(avg_relevance),0) as avg_rel
               FROM injections i JOIN sessions s ON i.session_id = s.id
               WHERE s.ended_at >= ?
               GROUP BY layer ORDER BY layer""",
            (cutoff,),
        ).fetchall()

        # Relevance distribution
        rel_strong = conn.execute(
            """SELECT COUNT(*) FROM injections i JOIN sessions s ON i.session_id = s.id
               WHERE s.ended_at >= ? AND avg_relevance >= 0.7 AND dedup_hit = 0""",
            (cutoff,),
        ).fetchone()[0]
        rel_partial = conn.execute(
            """SELECT COUNT(*) FROM injections i JOIN sessions s ON i.session_id = s.id
               WHERE s.ended_at >= ? AND avg_relevance >= 0.3 AND avg_relevance < 0.7 AND dedup_hit = 0""",
            (cutoff,),
        ).fetchone()[0]
        rel_weak = conn.execute(
            """SELECT COUNT(*) FROM injections i JOIN sessions s ON i.session_id = s.id
               WHERE s.ended_at >= ? AND avg_relevance < 0.3 AND avg_relevance IS NOT NULL AND dedup_hit = 0""",
            (cutoff,),
        ).fetchone()[0]

        # Dedup stats
        dedup_total = conn.execute(
            """SELECT COUNT(*) FROM injections i JOIN sessions s ON i.session_id = s.id
               WHERE s.ended_at >= ?""",
            (cutoff,),
        ).fetchone()[0]
        dedup_hits = conn.execute(
            """SELECT COUNT(*) FROM injections i JOIN sessions s ON i.session_id = s.id
               WHERE s.ended_at >= ? AND dedup_hit = 1""",
            (cutoff,),
        ).fetchone()[0]

        # Empty injections (no results, not dedup)
        empty_count = conn.execute(
            """SELECT COUNT(*) FROM injections i JOIN sessions s ON i.session_id = s.id
               WHERE s.ended_at >= ? AND filtered_count = 0 AND dedup_hit = 0""",
            (cutoff,),
        ).fetchone()[0]

        # Top cited texts
        top_citations = conn.execute(
            """SELECT citation_text, COUNT(*) as cnt
               FROM citations c JOIN sessions s ON c.session_id = s.id
               WHERE s.ended_at >= ?
               GROUP BY citation_text ORDER BY cnt DESC LIMIT 5""",
            (cutoff,),
        ).fetchall()

        # Daily token burn
        daily_tokens = conn.execute(
            """SELECT DATE(s.ended_at) as day, SUM(i.token_estimate) as tok
               FROM injections i JOIN sessions s ON i.session_id = s.id
               WHERE s.ended_at >= ?
               GROUP BY DATE(s.ended_at) ORDER BY day""",
            (cutoff,),
        ).fetchall()

        # Per-session detail
        sessions = conn.execute(
            """SELECT id, project, started_at, ended_at, total_injections, total_tokens, citation_count
               FROM sessions WHERE ended_at >= ? ORDER BY ended_at DESC""",
            (cutoff,),
        ).fetchall()

        # Daily relevance trend
        daily_relevance = conn.execute(
            """SELECT DATE(s.ended_at) as day, AVG(i.avg_relevance) as avg_rel
               FROM injections i JOIN sessions s ON i.session_id = s.id
               WHERE s.ended_at >= ? AND i.avg_relevance IS NOT NULL AND i.dedup_hit = 0
               GROUP BY DATE(s.ended_at) ORDER BY day""",
            (cutoff,),
        ).fetchall()

        conn.close()

        non_dedup = dedup_total - dedup_hits
        citation_rate = (total_citations / non_dedup * 100) if non_dedup > 0 else 0
        dedup_rate = (dedup_hits / dedup_total * 100) if dedup_total > 0 else 0
        empty_rate = (empty_count / non_dedup * 100) if non_dedup > 0 else 0

        return {
            "since_days": since_days,
            "session_count": session_count,
            "total_injections": total_injections,
            "total_tokens": total_tokens,
            "total_citations": total_citations,
            "layers": [dict(r) for r in layers],
            "relevance": {
                "strong": rel_strong,
                "partial": rel_partial,
                "weak": rel_weak,
            },
            "dedup_total": dedup_total,
            "dedup_hits": dedup_hits,
            "dedup_rate": round(dedup_rate, 1),
            "citation_rate": round(citation_rate, 1),
            "empty_count": empty_count,
            "empty_rate": round(empty_rate, 1),
            "top_citations": [{"text": r["citation_text"], "count": r["cnt"]} for r in top_citations],
            "daily_tokens": [{"day": r["day"], "tokens": r["tok"]} for r in daily_tokens],
            "daily_relevance": [{"day": r["day"], "avg_relevance": round(r["avg_rel"], 3)} for r in daily_relevance],
            "sessions": [dict(r) for r in sessions],
        }
    except Exception:
        conn.close()
        return None


def query_session_injections(session_id):
    """Get all injections for a specific session (for drill-down)."""
    if not os.path.exists(METRICS_DB):
        return []
    try:
        conn = _get_db()
        rows = conn.execute(
            """SELECT ts, layer, event, query, result_count, filtered_count,
                      avg_relevance, max_relevance, min_relevance,
                      duration_ms, token_estimate, dedup_hit
               FROM injections WHERE session_id = ? ORDER BY ts""",
            (session_id,),
        ).fetchall()
        conn.close()
        return [dict(r) for r in rows]
    except Exception:
        return []


# --- Citation Scanning ---

CITATION_PATTERNS = [
    "From memory:",
    "from past experience",
    "Based on memory",
    "a memória szerint",
    "From project memory",
    "Based on past",
    "from memory:",
    "From Memory:",
]


def scan_transcript_citations(transcript_path, session_id=None):
    """Scan a transcript JSONL for memory citations in assistant messages.

    Returns list of {text, type} dicts.
    """
    citations = []
    if not transcript_path or not os.path.exists(transcript_path):
        return citations

    try:
        with open(transcript_path) as f:
            for line in f:
                try:
                    obj = json.loads(line)
                except (json.JSONDecodeError, ValueError):
                    continue

                if obj.get("type") != "assistant":
                    continue

                content = obj.get("message", {}).get("content", [])
                if not isinstance(content, list):
                    continue

                for block in content:
                    if not isinstance(block, dict) or block.get("type") != "text":
                        continue
                    text = block.get("text", "")
                    for pattern in CITATION_PATTERNS:
                        if pattern in text:
                            # Extract a snippet around the citation
                            idx = text.find(pattern)
                            snippet = text[max(0, idx - 20) : idx + len(pattern) + 80].strip()
                            citations.append({"text": snippet, "type": "explicit"})
                            break  # one citation per text block
    except Exception:
        pass

    return citations


# --- TUI Report Formatting ---

def format_tui_report(data):
    """Format metrics data as a text report for terminal display."""
    if not data:
        return "No metrics data. Enable with: wt-memory metrics --enable"

    lines = []
    lines.append(f"Memory Metrics Report - Last {data['since_days']} days")
    lines.append("=" * 60)
    lines.append("")
    lines.append(f"  Sessions: {data['session_count']:>6}    Injections: {data['total_injections']:>6}    Tokens: {data['total_tokens']:>8}")
    lines.append("")

    # Per-layer breakdown
    lines.append("  BY LAYER")
    lines.append("  " + "-" * 56)
    for layer in data["layers"]:
        avg_rel = layer.get("avg_rel", 0)
        lines.append(
            f"  {layer['layer']:<20} {layer['cnt']:>4}x   {layer['avg_tok']:>6.0f} avg tok   {avg_rel:.2f} avg rel"
        )
    lines.append("")

    # Relevance distribution
    rel = data["relevance"]
    total_rel = rel["strong"] + rel["partial"] + rel["weak"]
    lines.append("  RELEVANCE DISTRIBUTION")
    lines.append("  " + "-" * 56)
    if total_rel > 0:
        s_pct = rel["strong"] / total_rel * 100
        p_pct = rel["partial"] / total_rel * 100
        w_pct = rel["weak"] / total_rel * 100
        s_bar = "#" * int(s_pct / 5)
        p_bar = "#" * int(p_pct / 5)
        w_bar = "#" * int(w_pct / 5)
        lines.append(f"  >0.7 (strong)  {s_bar:<20} {s_pct:>5.1f}%  ({rel['strong']})")
        lines.append(f"  0.3-0.7 (part) {p_bar:<20} {p_pct:>5.1f}%  ({rel['partial']})")
        lines.append(f"  <0.3 (weak)    {w_bar:<20} {w_pct:>5.1f}%  ({rel['weak']})")
    else:
        lines.append("  No relevance data")
    lines.append("")

    # Usage signals
    lines.append("  USAGE SIGNALS")
    lines.append("  " + "-" * 56)
    lines.append(f"  Citation rate:     {data['citation_rate']:>5.1f}% ({data['total_citations']} citations)")
    lines.append(f"  Dedup hit rate:    {data['dedup_rate']:>5.1f}% ({data['dedup_hits']} saved)")
    lines.append(f"  Empty injections:  {data['empty_rate']:>5.1f}% ({data['empty_count']} empty)")
    lines.append("")

    # Top cited
    if data["top_citations"]:
        lines.append("  TOP CITED MEMORIES")
        lines.append("  " + "-" * 56)
        for i, cit in enumerate(data["top_citations"], 1):
            text = cit["text"][:60]
            lines.append(f"  {i}. \"{text}\"  {cit['count']}x")
        lines.append("")

    return "\n".join(lines)
