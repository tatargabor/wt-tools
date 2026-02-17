## 1. L1 — SessionStart Warmstart Hook

- [ ] 1.1 Create `bin/wt-hook-memory-warmstart` script: health check → recall cheat-sheet tagged memories → proactive context from project name + recent git files → output JSON with `hookSpecificOutput.additionalContext`
- [ ] 1.2 Add `wt-hook-memory-warmstart` to symlink list in `install.sh`

## 2. L2 — Rewrite UserPromptSubmit Recall Hook

- [ ] 2.1 Rewrite `bin/wt-hook-memory-recall`: remove change-boundary detection and debounce; extract topic from prompt text; detect opsx/openspec skill names and change names; always recall using `wt-memory proactive` or `wt-memory recall`
- [ ] 2.2 Switch output from plain text stdout to JSON `hookSpecificOutput.additionalContext` format with `hookEventName: "UserPromptSubmit"`
- [ ] 2.3 Keep `=== PROJECT MEMORY ===` prefix in the additionalContext text for compatibility with skill prompts that reference it

## 3. L3 — PreToolUse Hot-Topic Hook

- [ ] 3.1 Create `bin/wt-hook-memory-pretool` script: parse `tool_input.command` from stdin JSON; single regex check against hot-topic patterns (database, api, deploy, auth, python, node); exit 0 immediately on no match
- [ ] 3.2 On hot-topic match: determine category → build recall query (category + specific tool name) → `wt-memory recall` → output JSON `hookSpecificOutput.additionalContext` with max 2 memories
- [ ] 3.3 Add `wt-hook-memory-pretool` to symlink list in `install.sh`

## 4. L4 — PostToolUseFailure Error Recovery Hook

- [ ] 4.1 Create `bin/wt-hook-memory-posttool` script: parse `error` and `is_interrupt` from stdin JSON; skip if `is_interrupt` is true; skip if error text < 10 chars
- [ ] 4.2 Use first 300 chars of error text as recall query → `wt-memory recall` with limit 3 → output JSON `hookSpecificOutput.additionalContext` prefixed with `=== MEMORY: Past fix for this error ===`
- [ ] 4.3 Add `wt-hook-memory-posttool` to symlink list in `install.sh`

## 5. L5 — Enhanced Stop Hook (Cheat Sheet Curation)

- [ ] 5.1 Update haiku extraction prompt in `bin/wt-hook-memory-save`: add `CheatSheet` type alongside existing `Learning|Decision|Context|Convention`; instruct haiku to use CheatSheet for reusable operational patterns (DB connection methods, auth patterns, deploy procedures)
- [ ] 5.2 In the commit-staged-files parsing loop: map `CheatSheet` type to `Learning` with `cheat-sheet` tag; auto-add `cheat-sheet` tag to `Convention` entries too; cap CheatSheet entries at 2 per session

## 6. Deploy Script Update

- [ ] 6.1 Update `bin/wt-deploy-hooks`: add `SessionStart` entry with `wt-hook-memory-warmstart` (timeout 10), `PreToolUse` entry matching `"Bash"` with `wt-hook-memory-pretool` (timeout 5), `PostToolUseFailure` entry matching `"Bash"` with `wt-hook-memory-posttool` (timeout 5)
- [ ] 6.2 Add upgrade path: detect existing configs with old 2-hook memory setup → add new 3 hooks while preserving existing entries
- [ ] 6.3 Ensure `--no-memory` flag skips all 5 memory hooks (not just the original 2)

## 7. Documentation

- [ ] 7.1 Update `docs/developer-memory.md`: add section describing all 5 hook layers (L1–L5) with diagram showing when each fires
- [ ] 7.2 Update hook layer descriptions with latency expectations and hot-topic pattern list

## 8. Integration Testing

- [ ] 8.1 Test L1: verify SessionStart hook loads cheat-sheet memories and outputs valid JSON
- [ ] 8.2 Test L2: verify recall fires on plain prompts, opsx:explore topics, and opsx:ff change names; verify additionalContext JSON format
- [ ] 8.3 Test L3: verify hot-topic matching (psql→match, ls→skip); verify additionalContext injection; measure latency for non-matching commands
- [ ] 8.4 Test L4: verify PostToolUseFailure recall on error text; verify is_interrupt skip; verify additionalContext format
- [ ] 8.5 Test L5: verify CheatSheet type extraction and cheat-sheet tag promotion
- [ ] 8.6 Test deploy: verify fresh deploy creates all 5 hook entries; verify upgrade from old 2-hook config; verify --no-memory skips all
