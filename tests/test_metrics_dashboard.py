"""Tests for lib/metrics.py and lib/dashboard.py.

Uses an isolated temp directory for the SQLite DB so real metrics are untouched.
No external dependencies — fully self-contained.
"""

import os
import sqlite3
import tempfile
import time
from datetime import datetime, timedelta, timezone

import pytest

# --- Isolation fixture ---


@pytest.fixture()
def metrics_db(tmp_path, monkeypatch):
    """Redirect metrics storage to a temp dir and return the module."""
    import importlib
    import lib.metrics as _m

    metrics_dir = str(tmp_path / "metrics")
    monkeypatch.setattr(_m, "METRICS_DIR", metrics_dir)
    monkeypatch.setattr(_m, "METRICS_DB", os.path.join(metrics_dir, "metrics.db"))
    monkeypatch.setattr(_m, "ENABLED_FLAG", os.path.join(metrics_dir, ".enabled"))

    # Re-import to pick up patched paths (module-level constants already set on import,
    # but functions use the module attributes so monkeypatching is enough)
    return _m


# --- Helper ---


def _make_records(n, layer="L1", avg_rel=0.8, tok=100):
    """Build a list of n injection metric dicts."""
    ts = datetime.now(timezone.utc).isoformat()
    return [
        {
            "ts": ts,
            "layer": layer,
            "event": "session_start",
            "query": f"query {i}",
            "result_count": 3,
            "filtered_count": 2,
            "avg_relevance": avg_rel,
            "max_relevance": avg_rel + 0.05,
            "min_relevance": avg_rel - 0.05,
            "duration_ms": 50,
            "token_estimate": tok,
            "dedup_hit": 0,
        }
        for i in range(n)
    ]


# ============================================================
# enable / disable
# ============================================================


def test_enable_disable(metrics_db):
    m = metrics_db
    assert not m.is_enabled()
    m.enable()
    assert m.is_enabled()
    m.disable()
    assert not m.is_enabled()
    # disable again is idempotent
    m.disable()
    assert not m.is_enabled()


# ============================================================
# flush_session
# ============================================================


def test_flush_empty_records_is_noop(metrics_db):
    m = metrics_db
    m.flush_session("sess-1", "myproject", [])
    # DB should not even exist
    assert not os.path.exists(m.METRICS_DB)


def test_flush_creates_records(metrics_db):
    m = metrics_db
    records = _make_records(5)
    m.flush_session("sess-1", "myproject", records)

    conn = sqlite3.connect(m.METRICS_DB)
    conn.row_factory = sqlite3.Row
    count = conn.execute("SELECT COUNT(*) FROM injections WHERE session_id='sess-1'").fetchone()[0]
    sess = conn.execute("SELECT * FROM sessions WHERE id='sess-1'").fetchone()
    conn.close()

    assert count == 5
    assert sess is not None
    assert sess["project"] == "myproject"
    assert sess["total_injections"] == 5


def test_flush_tokens_summed(metrics_db):
    m = metrics_db
    records = _make_records(4, tok=200)
    m.flush_session("sess-tok", "proj", records)

    conn = sqlite3.connect(m.METRICS_DB)
    tok = conn.execute("SELECT total_tokens FROM sessions WHERE id='sess-tok'").fetchone()[0]
    conn.close()
    assert tok == 800


def test_flush_citations(metrics_db):
    m = metrics_db
    records = _make_records(2)
    citations = [
        {"text": "From memory: use JWT", "type": "explicit"},
        {"text": "From memory: check logs", "type": "explicit"},
    ]
    m.flush_session("sess-cit", "proj", records, citations)

    conn = sqlite3.connect(m.METRICS_DB)
    cit_count = conn.execute(
        "SELECT COUNT(*) FROM citations WHERE session_id='sess-cit'"
    ).fetchone()[0]
    sess_cit = conn.execute(
        "SELECT citation_count FROM sessions WHERE id='sess-cit'"
    ).fetchone()[0]
    conn.close()

    assert cit_count == 2
    assert sess_cit == 2


def test_flush_dedup_hit(metrics_db):
    m = metrics_db
    records = _make_records(3)
    records[0]["dedup_hit"] = 1
    records[1]["dedup_hit"] = 1
    m.flush_session("sess-dedup", "proj", records)

    conn = sqlite3.connect(m.METRICS_DB)
    hits = conn.execute(
        "SELECT COUNT(*) FROM injections WHERE session_id='sess-dedup' AND dedup_hit=1"
    ).fetchone()[0]
    conn.close()
    assert hits == 2


def test_flush_replace_same_session(metrics_db):
    """flush_session called twice with same ID should replace, not duplicate."""
    m = metrics_db
    m.flush_session("sess-dup", "proj", _make_records(3))
    m.flush_session("sess-dup", "proj", _make_records(5))

    conn = sqlite3.connect(m.METRICS_DB)
    sess_count = conn.execute(
        "SELECT COUNT(*) FROM sessions WHERE id='sess-dup'"
    ).fetchone()[0]
    conn.close()
    assert sess_count == 1  # INSERT OR REPLACE


# ============================================================
# query_report
# ============================================================


def test_query_report_no_db_returns_none(metrics_db):
    m = metrics_db
    assert m.query_report() is None


def test_query_report_returns_data(metrics_db):
    m = metrics_db
    m.flush_session("s1", "proj", _make_records(10, avg_rel=0.8))
    data = m.query_report(since_days=7)

    assert data is not None
    assert data["session_count"] == 1
    assert data["total_injections"] == 10
    assert data["total_tokens"] == 1000
    assert data["relevance"]["strong"] > 0
    assert "layers" in data
    assert "daily_tokens" in data
    assert "daily_relevance" in data


def test_query_report_relevance_buckets(metrics_db):
    m = metrics_db
    strong = _make_records(5, avg_rel=0.9)
    partial = _make_records(3, avg_rel=0.5)
    weak = _make_records(2, avg_rel=0.1)
    all_records = strong + partial + weak
    m.flush_session("s-rel", "proj", all_records)

    data = m.query_report()
    rel = data["relevance"]
    assert rel["strong"] == 5
    assert rel["partial"] == 3
    assert rel["weak"] == 2


def test_query_report_dedup_rate(metrics_db):
    m = metrics_db
    records = _make_records(10)
    for r in records[:4]:
        r["dedup_hit"] = 1
    m.flush_session("s-dedup", "proj", records)

    data = m.query_report()
    assert data["dedup_hits"] == 4
    assert data["dedup_rate"] == 40.0


def test_query_report_empty_rate(metrics_db):
    m = metrics_db
    records = _make_records(6)
    for r in records[:2]:
        r["filtered_count"] = 0  # empty injection
    m.flush_session("s-empty", "proj", records)

    data = m.query_report()
    assert data["empty_count"] == 2


def test_query_report_multiple_layers(metrics_db):
    m = metrics_db
    m.flush_session("s-layers", "proj",
                    _make_records(4, layer="L1") + _make_records(3, layer="L2"))

    data = m.query_report()
    layer_names = {l["layer"] for l in data["layers"]}
    assert "L1" in layer_names
    assert "L2" in layer_names


def test_query_report_since_days_filter(metrics_db):
    """Sessions older than since_days should be excluded."""
    m = metrics_db
    records = _make_records(5)

    # Insert a recent session
    m.flush_session("s-recent", "proj", records)

    # Manually insert an old session (10 days ago)
    old_ts = (datetime.utcnow() - timedelta(days=10)).isoformat() + "Z"
    conn = sqlite3.connect(m.METRICS_DB)
    conn.execute(
        "INSERT OR REPLACE INTO sessions "
        "(id, project, started_at, ended_at, total_injections, total_tokens, citation_count, layers_json) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        ("s-old", "proj", old_ts, old_ts, 5, 500, 0, "{}"),
    )
    conn.commit()
    conn.close()

    data = m.query_report(since_days=7)
    session_ids = {s["id"] for s in data["sessions"]}
    assert "s-recent" in session_ids
    assert "s-old" not in session_ids


def test_query_report_top_citations(metrics_db):
    m = metrics_db
    records = _make_records(2)
    cits = [{"text": "From memory: JWT is best", "type": "explicit"}] * 3
    m.flush_session("s-cit", "proj", records, cits)

    data = m.query_report()
    assert len(data["top_citations"]) >= 1
    assert data["top_citations"][0]["count"] == 3


# ============================================================
# query_session_injections
# ============================================================


def test_query_session_injections(metrics_db):
    m = metrics_db
    m.flush_session("sinj", "proj", _make_records(7))
    rows = m.query_session_injections("sinj")
    assert len(rows) == 7
    assert "layer" in rows[0]


def test_query_session_injections_no_db(metrics_db):
    m = metrics_db
    assert m.query_session_injections("nonexistent") == []


# ============================================================
# scan_transcript_citations
# ============================================================


def test_scan_transcript_citations(tmp_path):
    from lib.metrics import scan_transcript_citations

    transcript = tmp_path / "session.jsonl"
    import json

    lines = [
        json.dumps({"type": "human", "message": {"content": [{"type": "text", "text": "help"}]}}),
        json.dumps({"type": "assistant", "message": {"content": [
            {"type": "text", "text": "From memory: use the helper function here."}
        ]}}),
        json.dumps({"type": "assistant", "message": {"content": [
            {"type": "text", "text": "No citation here."}
        ]}}),
    ]
    transcript.write_text("\n".join(lines))

    citations = scan_transcript_citations(str(transcript))
    assert len(citations) == 1
    assert "From memory:" in citations[0]["text"]


def test_scan_transcript_missing_file():
    from lib.metrics import scan_transcript_citations
    result = scan_transcript_citations("/nonexistent/path.jsonl")
    assert result == []


# ============================================================
# format_tui_report
# ============================================================


def test_format_tui_report_no_data(metrics_db):
    m = metrics_db
    out = m.format_tui_report(None)
    assert "Enable" in out


def test_format_tui_report_with_data(metrics_db):
    m = metrics_db
    records = _make_records(10, avg_rel=0.8)
    records[0]["dedup_hit"] = 1
    m.flush_session("tui-sess", "myproj", records)
    data = m.query_report()
    out = m.format_tui_report(data)

    assert "Memory Metrics Report" in out
    assert "Sessions" in out
    assert "RELEVANCE" in out
    assert "USAGE SIGNALS" in out
    # Numbers must appear
    assert "10" in out   # total_injections
    assert "L1" in out   # layer name


# ============================================================
# generate_dashboard (HTML)
# ============================================================


def test_generate_dashboard_empty():
    from lib.dashboard import generate_dashboard
    html = generate_dashboard(None)
    assert "<!DOCTYPE html>" in html
    assert "No Metrics Data" in html


def test_generate_dashboard_with_data(metrics_db):
    from lib.dashboard import generate_dashboard

    m = metrics_db
    records = _make_records(8, avg_rel=0.75)
    m.flush_session("dash-sess", "dashproj", records,
                    [{"text": "From memory: something important", "type": "explicit"}])
    data = m.query_report()
    # Enrich with injections per session (as the real CLI does)
    for sess in data["sessions"]:
        sess["injections"] = m.query_session_injections(sess["id"])

    html = generate_dashboard(data)

    # Structural checks
    assert "<!DOCTYPE html>" in html
    assert "Memory Metrics Dashboard" in html
    assert "Chart.js" in html or "chart.js" in html

    # Data should be embedded as JSON
    assert "dashproj" in html
    assert "dash-sess" in html

    # Summary stats rendered
    assert "800" in html or "tok" in html.lower()


def test_generate_dashboard_relevance_bars(metrics_db):
    from lib.dashboard import generate_dashboard

    m = metrics_db
    strong = _make_records(6, avg_rel=0.9)
    weak = _make_records(2, avg_rel=0.2)
    m.flush_session("dash-rel", "proj", strong + weak)
    data = m.query_report()

    html = generate_dashboard(data)
    assert "bar-strong" in html
    assert "bar-weak" in html


def test_generate_dashboard_citations_rendered(metrics_db):
    from lib.dashboard import generate_dashboard

    m = metrics_db
    m.flush_session("dash-cit", "proj", _make_records(3),
                    [{"text": "From memory: remember this", "type": "explicit"}] * 2)
    data = m.query_report()
    html = generate_dashboard(data)

    assert "citation-item" in html
    assert "remember this" in html


def test_generate_dashboard_no_citations():
    from lib.dashboard import generate_dashboard, _citations_html
    out = _citations_html([])
    assert "No citations" in out


def test_generate_dashboard_fmt_tokens():
    from lib.dashboard import _fmt_tokens
    assert _fmt_tokens(500) == "500"
    assert _fmt_tokens(1500) == "1.5K"
    assert _fmt_tokens(2_000_000) == "2.0M"


def test_generate_dashboard_empty_relevance():
    from lib.dashboard import _relevance_bars
    out = _relevance_bars({"strong": 0, "partial": 0, "weak": 0})
    assert "No data" in out
