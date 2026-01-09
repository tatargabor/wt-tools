## 1. Add cross-platform helpers to wt-common.sh

- [x] 1.1 Add `get_proc_cwd` helper function that uses `lsof -a -p $pid -d cwd -Fn` on macOS and `readlink /proc/$pid/cwd` on Linux, branching on the existing `$PLATFORM` variable
- [x] 1.2 Add `get_file_mtime` helper function that uses `stat -f "%m"` on macOS and `stat -c %Y` on Linux, branching on `$PLATFORM`

## 2. Update wt-status to use new helpers

- [x] 2.1 Replace `readlink "/proc/$pid/cwd"` (line 56) with a call to `get_proc_cwd "$pid"` in `detect_agent_status()`
- [x] 2.2 Replace `stat -c %Y "$newest"` (line 72) with a call to `get_file_mtime "$newest"` in `detect_agent_status()`

## 3. Verify on macOS

- [x] 3.1 Run `wt-status --json` and confirm non-idle status is returned when a Claude process is active in a worktree
- [x] 3.2 Run `wt-status` (terminal format) and confirm correct icons and status labels
