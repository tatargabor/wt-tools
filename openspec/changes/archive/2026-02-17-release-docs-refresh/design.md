## Context

The README is the project's primary external-facing document. `docs/readme-guide.md` is the authoritative structure guide with 16 mandatory sections, AI generation instructions, and an update checklist. The current README covers 16 sections in correct order but has content gaps from recent feature additions.

The Team Sync feature (`wt-control-sync`) runs git fetch+push every poll cycle. At `sync_interval_ms: 15000` (current default), this generates ~240 syncs/hour = ~480 git operations/hour per machine. For teams with multiple machines, this multiplies further. GitHub rate limits can be hit silently.

## Goals / Non-Goals

**Goals:**
- README accurate and complete for all shipped features
- Team Sync traffic risk clearly documented with safe defaults
- All user-facing CLI commands documented in CLI Reference
- readme-guide.md stays authoritative (update it with new CLI commands)

**Non-Goals:**
- Rewriting docs/developer-memory.md (already comprehensive)
- Rewriting docs/agent-messaging.md (already current)
- Adding new screenshots (current ones are fine)
- Restructuring the README beyond readme-guide.md mandates

## Decisions

**Choice: Full README refresh, not incremental patches**
- The readme-guide.md has AI generation instructions designed for full rewrites
- Multiple sections need updates — patching risks inconsistency
- Alternative: patch only changed sections → rejected, guide recommends full rewrite for major updates

**Choice: `team.sync_interval_ms` default 15000 → 120000 (2 minutes)**
- 15s generates excessive GitHub traffic for a background poller
- 2 minutes is conservative enough for most teams while still being useful
- Users can lower it in Settings if they need faster sync
- Document the trade-off: lower interval = fresher data but more GitHub API usage
- Alternative: 60000 (1 min) → rejected, user explicitly requested 2 minutes

**Choice: Remove AGENTS.md rather than populate it**
- File is 0 bytes, has been empty since creation
- No clear purpose that isn't covered by CLAUDE.md and CONTRIBUTING.md
- Alternative: write agent-specific docs → rejected, CLAUDE.md already covers this

**Choice: Add wt-openspec to user-facing CLI commands in readme-guide.md**
- Currently listed as neither user-facing nor internal in the guide
- It's a wrapper for `openspec` operations, users run it directly
- Add to CLI Documentation Rules user-facing list

## Risks / Trade-offs

- [2min sync default may feel slow for active teams] → Documented in README, users can configure lower in Settings
- [Full README rewrite may lose nuanced phrasing] → Use current README as input, preserve working sections
- [readme-guide.md changes affect future AI-generated READMEs] → Intentional, keeps the guide as source of truth
