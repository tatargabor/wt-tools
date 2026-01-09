## Context

When a terminal tab is closed in Zed (or other editors), the shell (zsh/bash) is terminated but the child `claude` process survives. macOS re-parents it directly to the editor process. These orphan agents:
- Still appear in `ps -e` output as `claude`
- Pass `kill -0` checks (they're alive)
- Show as "waiting" in the GUI, indistinguishable from real agents
- Waste memory (~150MB each)

Current detection flow: `ps -e | claude PIDs` → `get_proc_cwd` → match to worktree. No parent-process validation exists.

## Goals / Non-Goals

**Goals:**
- Detect orphan `claude` processes using PPID inspection
- Display orphans distinctly in the GUI (gray row, ⚠ icon)
- Allow users to kill orphans via right-click context menu

**Non-Goals:**
- Auto-killing orphans (user should decide)
- Preventing orphans in the first place (that's an editor/shell concern)
- Handling orphans on Windows (not a supported platform for window management)

## Decisions

### Decision 1: PPID-based orphan detection in wt-status

**Choice:** Check each detected `claude` process's PPID. If the parent is not a known shell (`zsh`, `bash`, `fish`, `sh`, `dash`), classify as orphan.

**Alternatives considered:**
- *TTY-based detection*: Check if the process's TTY is still active. Rejected because macOS doesn't always invalidate the TTY immediately, and the process may retain a valid TTY reference even after the terminal tab closes.
- *Session file staleness*: Mark agents as orphan if their session file hasn't been updated in N minutes. Rejected because "waiting" agents legitimately have stale session files — they're waiting for user input.
- *Allowlist editors as known bad parents*: Match PPID against Zed/VSCode/etc. Rejected because it's fragile (new editors, version changes) — it's simpler and more correct to allowlist the small set of valid shells.

**Implementation in `detect_agents()`:**
```bash
# After finding matching PIDs, check each one's parent
local ppid
ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
local parent_comm
parent_comm=$(ps -o comm= -p "$ppid" 2>/dev/null)

# Known shells that legitimately parent claude processes
case "$parent_comm" in
    zsh|bash|fish|sh|dash|-zsh|-bash|-fish|-sh|-dash) ;; # valid
    *) status="orphan" ;;
esac
```

Note: Shell names may have a `-` prefix (login shells: `-zsh`), so both forms are matched.

### Decision 2: Orphan status in JSON output

**Choice:** Add `"orphan"` as a new agent status value in the `wt-status --json` output, alongside existing `running`, `compacting`, `waiting`.

The GUI already switches on status for colors/icons, so adding a new status value is the minimal-impact approach.

### Decision 3: GUI orphan row styling

**Choice:**
- Row background: use new `row_orphan` / `row_orphan_text` color constants (gray tones, similar to idle but distinguishable)
- PID column: prepend `⚠ ` to the PID number
- Status column: show `⚠ orphan` with gray color
- Add `status_orphan` color constant and `ICON_ORPHAN = "⚠"` constant

### Decision 4: Kill action via context menu

**Choice:** Add "⚠ Kill Orphan Process" menu item in `show_row_context_menu()` when the agent for the clicked row has `status == "orphan"`. Sends `SIGTERM` via `os.kill(pid, signal.SIGTERM)`. The agent disappears on next status refresh (2s).

No confirmation dialog — the action is clearly labeled and the orphan is already dead weight. This keeps the UX snappy.

## Risks / Trade-offs

- **[False positive]** A legitimate `claude` process might be started outside a shell (e.g., from a script via `exec`). → Mitigation: The shell allowlist covers all common interactive scenarios. Non-shell parents are rare and would indicate unusual usage.
- **[Kill race condition]** User clicks kill, but process already died between refresh cycles. → Mitigation: `os.kill()` wrapped in try/except for `ProcessLookupError`. No-op if already dead.
- **[Platform differences]** `ps -o ppid=` and `ps -o comm=` formats may vary. → Mitigation: Already using `ps` for PID detection; PPID and comm are POSIX-standard fields. Works on macOS and Linux.
