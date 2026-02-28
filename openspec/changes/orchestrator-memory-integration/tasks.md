## 1. Helper Functions

- [x] 1.1 Add `orch_remember` helper function to wt-orchestrate — wraps `wt-memory remember` with availability check, `source:orchestrator` tag prefix, and `|| true` error suppression
- [x] 1.2 Add `orch_recall` helper function to wt-orchestrate — wraps `wt-memory recall` with availability check, hybrid mode, `--tags` filtering, 2000-char limit, and `|| true` error suppression

## 2. Event Saving — Merge Outcomes

- [x] 2.1 Save successful merge as `Context` memory in `merge_change()` after successful wt-merge (tags: `phase:merge,change:<name>`)
- [x] 2.2 Save merge conflict as `Decision` memory in `merge_change()` on conflict (tags: `phase:merge,change:<name>`)
- [x] 2.3 Save permanent merge failure as `Decision` memory in `retry_merge_queue()` when max retries exhausted (tags: `phase:merge,change:<name>`)

## 3. Event Saving — Test and Review Outcomes

- [x] 3.1 Save test pass as `Context` memory in `handle_change_done()` after tests pass (tags: `phase:test,change:<name>`)
- [x] 3.2 Save test failure as `Learning` memory in `handle_change_done()` after tests fail, including truncated test output first 500 chars (tags: `phase:test,change:<name>`)
- [x] 3.3 Save review pass as `Context` memory in `handle_change_done()` after review passes (tags: `phase:review,change:<name>`)
- [x] 3.4 Save review critical issues as `Learning` memory in `handle_change_done()` after review finds CRITICAL, including truncated review output first 500 chars (tags: `phase:review,change:<name>`)

## 4. Event Saving — Stall and Failure

- [x] 4.1 Save change stall as `Learning` memory in `poll_change()` on final stall attempt (3/3) (tags: `phase:monitor,change:<name>`)
- [x] 4.2 Save change failure as `Learning` memory when status transitions to `failed` (tags: `phase:monitor,change:<name>`)

## 5. Planning Recall Enhancement

- [x] 5.1 Replace single generic recall in `cmd_plan()` with per-roadmap-item recall in brief mode — iterate items, recall per scope text with no tag filter, combine results
- [x] 5.2 In spec mode, recall using spec summary/phase hint as query plus a separate `source:orchestrator` recall for operational context
- [x] 5.3 Omit `## Project Memory` section from planning prompt when all recalls return empty

## 6. Replan Memory Integration

- [x] 6.1 Add `orch_recall` call in `auto_replan_cycle()` querying `"orchestration merge conflict test failure review"` with `source:orchestrator` tags, limit 5
- [x] 6.2 Export recalled content as `_REPLAN_MEMORY` env var for injection into the planning prompt
- [x] 6.3 Inject `_REPLAN_MEMORY` as `## Orchestration History` section in the planning prompt (after completed items), omit section if empty

## 7. Dispatch Proposal Enrichment

- [x] 7.1 Add `orch_recall` call in `dispatch_change()` using change scope text as query with no tag filter, limit 3
- [x] 7.2 Append `## Context from Memory` section to proposal.md when recall returns non-empty content, limited to 1000 chars
- [x] 7.3 Skip the section entirely when recall returns empty
