## 1. Disable auto-kill in wt-status

- [x] 1.1 Comment out the `kill "$agent_pid"` line in `cleanup_orphan_agents()` in `bin/wt-status` with explanation comment: auto-kill disabled due to unreliable window detection (especially macOS osascript)
- [x] 1.2 Comment out the `continue` after the kill (so orphan agents remain in the output instead of being filtered out)
- [x] 1.3 Comment out the skill file removal (`rm -f "$skill_file"`) that follows the kill
- [x] 1.4 Comment out the marker file removal (`rm -f "$marker_dir/$agent_pid"`) after the kill

## 2. Verify orphan detection still works

- [x] 2.1 Verify that orphan agents still appear in `wt-status --json` output with "orphan" status (no code change needed — the status assignment at line ~461 is separate from cleanup)
- [x] 2.2 Verify the GUI still shows ⚠ prefix for orphan PIDs and "Kill Orphan Process" context menu still works
