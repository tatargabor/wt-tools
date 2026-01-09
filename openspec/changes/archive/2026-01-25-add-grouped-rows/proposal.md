# Change: Group Worktree Rows by Project

JIRA Key: EXAMPLE-560
Story: EXAMPLE-466

## Why
When there are worktrees from multiple projects, the list is hard to overview. Grouping by project improves readability.

## What Changes

### Grouped Display

```
Project           Change            Status    PID     Ctx%  J
aitools           add-control...    ● running 414720  69%   [J]
                  add-config...     ○ idle
mediapipe         limb-rendering    ⚡ waiting 501501  47%   [J]
                  multi-model       ⚡ waiting 255557
zsolti-raktaros   email             ⚡ waiting 643035  31%
```

- Project name only appears in the first row (when multiple worktrees exist)
- No separate header row - more compact display
- Sorting: project name alphabetical, within that change-id alphabetical

## Impact
- Affected specs: control-center
- Affected code: gui/main.py (update_status method)
