## MODIFIED Requirements

### R1: Token Tracking Resilience (MODIFIED)
- `get_current_tokens()` in `lib/loop/state.sh` must not silently return 0 when `wt-usage` fails
- When `wt-usage` is unavailable or crashes, fall back to JSONL session file size estimation using the existing `estimate_tokens_from_files()` function in `lib/loop/state.sh`
- The fallback reads Claude session JSONL files from `~/.claude/projects/` for the current project
- Estimates tokens at ~4 tokens per byte of JSONL

### R2: Recursive JSONL Scanning (ADDED)
- `UsageCalculator.iter_jsonl_files()` must use recursive glob (`rglob('*.jsonl')`) instead of single-level `glob('*.jsonl')` to include subagent session files stored in subdirectories

### R3: Project-Scoped Token Counting (ADDED)
- `UsageCalculator.iter_jsonl_files()` accepts an optional `project_dir` parameter
- When `project_dir` is provided, only JSONL files under `~/.claude/projects/<project_dir>/` are scanned (including subdirectories for subagent sessions)
- When `project_dir` is omitted, all project directories are scanned (backward compatible)
- `bin/wt-usage` accepts `--project-dir <name>` CLI flag that passes through to `UsageCalculator`
- `get_current_tokens()` derives the project dir name from `$PWD`: encode path by replacing `/` with `-` and stripping the leading `-` (reverse-engineered from Claude's observed naming convention — may not cover edge cases like spaces or Unicode)
- If the derived project dir does not exist under `~/.claude/projects/`, fall back to unfiltered scanning with a stderr warning

#### Scenario: Parallel worktree token isolation
- **WHEN** two changes run in parallel worktrees (`/tmp/minishop-e2e-wt-cart` and `/tmp/minishop-e2e-wt-orders`)
- **THEN** each change's `get_current_tokens()` only counts tokens from its own JSONL files, not the other's

#### Scenario: User session exclusion
- **WHEN** the user has an active Claude session on a different project while orchestration runs
- **THEN** the orchestrated changes do not include the user's session tokens in their counts
