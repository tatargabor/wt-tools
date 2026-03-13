## Status: REVERTED

Feature was implemented, E2E tested (Run #5), and reverted.

**Reason**: Claude Code Agent tool subagents cannot access skills, MCP tools,
or context calculation. This is a fundamental platform limitation, not a bug.
Run #5 showed 3 manual interventions vs Run #4's 0, and 4 replan cascades —
complexity explosion for marginal time gain (~10 min).

**Commit**: `aae737ff9` — revert: remove parallel subagent execution mode

All code removed from: bin/wt-loop, lib/loop/{state,prompt,engine}.sh,
lib/orchestration/{dispatcher,utils}.sh (151 lines deleted).
