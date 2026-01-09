## Context

The `bin/wt-status` script detects Claude agent status by:
1. Finding `claude` processes via `pgrep -x claude`
2. Resolving each process's working directory via `readlink /proc/$pid/cwd`
3. Matching the working directory against worktree paths
4. Checking session file freshness via `stat -c %Y`

Steps 2 and 3 use Linux-only APIs (`/proc` filesystem, GNU `stat`). On macOS (Darwin), `/proc` does not exist and `stat` uses BSD syntax. Both calls fail silently, causing the function to always return "idle".

The GUI's context % display works because it reads Claude session files directly via Python's `pathlib` — no platform-specific system calls.

## Goals / Non-Goals

**Goals:**
- Make `detect_agent_status()` work correctly on macOS (Darwin)
- Keep Linux behavior unchanged
- Minimal, focused change — only fix what's broken

**Non-Goals:**
- Migrating `wt-status` from shell to Python
- Adding Windows support
- Refactoring the GUI status pipeline
- Adding unit tests for shell scripts (not in current project conventions)

## Decisions

### Decision 1: Platform detection via `uname -s` at script startup

Detect the platform once at script top-level (or in `wt-common.sh`) and set a variable (e.g., `IS_DARWIN`). Individual functions branch on this variable.

**Why**: Simple, zero-cost, already a bash idiom. Avoids calling `uname` repeatedly.

**Alternative considered**: Per-call detection — rejected because it adds overhead in a function called per-worktree.

### Decision 2: Use `lsof` on macOS for process working directory

On macOS, replace `readlink "/proc/$pid/cwd"` with:
```bash
lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | grep '^n' | cut -c2-
```

**Why**: `lsof` is pre-installed on macOS, well-documented, and reliable. The `-a -p $pid -d cwd -Fn` combo directly queries the process's current working directory.

**Alternatives considered**:
- `pwdx` — not available on macOS
- `ps -o command=` — gives the command, not the cwd
- `proc_pidpath()` via Python — would require rewriting in Python

### Decision 3: Use BSD `stat -f "%m"` on macOS for file mtime

On macOS, replace `stat -c %Y "$file"` with `stat -f "%m" "$file"`.

**Why**: Direct BSD equivalent. Returns epoch seconds, same as GNU `stat -c %Y`.

### Decision 4: Add helpers to `wt-common.sh`

Add two thin helper functions to `bin/wt-common.sh`:
- `get_proc_cwd "$pid"` — returns working directory of a process
- `get_file_mtime "$file"` — returns modification time as epoch seconds

**Why**: Other scripts in `bin/` may also need these. Centralizing them prevents future duplicate platform checks.

## Risks / Trade-offs

- **`lsof` performance** — `lsof` is slower than `/proc` readlink. For typical worktree counts (< 20) and refresh intervals (2s), this is negligible. → Mitigation: None needed; well within acceptable latency.
- **`lsof` output format changes** — Unlikely for such a fundamental tool, but possible across major macOS versions. → Mitigation: The `-Fn` flag produces machine-parseable output, which is stable.
- **`pgrep -x claude` behavior** — May differ slightly between GNU and BSD `pgrep`. → Mitigation: Already works on macOS (confirmed by user — processes are found, just cwd resolution fails).
