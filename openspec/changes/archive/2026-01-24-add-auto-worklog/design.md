# Design: Automatic JIRA Worklog Generation

## Context

Developers work on multiple projects, on multiple machines, sometimes with multiple AI agents in parallel. Manual JIRA worklog entry is time-consuming and inaccurate. Automatic worklog generation infers work time from git activity and file modifications.

## Goals / Non-Goals

### Goals
- Identifying work intervals based on git commit history
- Retroactive worklog generation for any date
- Merging activity from multiple machines
- Proportional distribution of parallel work (multiple worktrees)
- Configurable fixed deductions (standup, lunch)
- Dry-run mode for preview
- JIRA workspace auto-detection from project config

### Non-Goals
- Real-time tracking (not a daemon/service)
- IDE integration
- Automatic standup/meeting detection (fixed config instead)
- File-level granularity (commit-level only)

## Decisions

### Decision 1: Git-based activity detection
**What:** Using git commit timestamps for activity reconstruction.

**Why:**
- Every commit contains an exact timestamp (AuthorDate)
- Multi-machine: remote branches available after fetch
- Retroactively queryable (`git log --since --until`)

**Alternatives considered:**
- File mtime: Only good for uncommitted work, not persistent
- Shell history: Different per machine, unreliable
- Claude Code logs: Not standardized, not always available

### Decision 2: Work interval calculation
**What:** Breaking activity into "work blocks" with maximum N minute gaps between blocks.

**Algorithm:**
```
1. Collect all commits for the given day (all worktrees, all remotes)
2. Sort chronologically
3. Group into blocks (maxGap = 30m default)
4. Each block: start = first commit - buffer, end = last commit + buffer
5. Sum block durations
6. Subtract fixed time periods (standup, lunch)
```

**Why:** Commits are sparse, but work between them counts too. Gap-based grouping gives a more realistic picture.

### Decision 3: Parallel work handling
**What:** When multiple worktrees have overlapping activity, time is distributed proportionally.

**Algorithm:**
```
1. Calculate work intervals for each worktree
2. Find overlaps
3. At overlaps: divide proportionally among participating tasks
4. Non-overlapping parts: 100% to that task
```

**Example:**
```
Task A: 09:00-12:00 (3h)
Task B: 10:00-14:00 (4h)
Overlap: 10:00-12:00 (2h)

Result:
- Task A: 09:00-10:00 (1h) + 10:00-12:00 / 2 (1h) = 2h
- Task B: 10:00-12:00 / 2 (1h) + 12:00-14:00 (2h) = 3h
```

### Decision 4: Multi-machine support
**What:** Fetching remote branches and aggregating activity from all branches.

**How:**
```bash
git fetch --all
git log --all --since="2024-01-15" --until="2024-01-16" --format="%ai %H"
```

**Why:** The `--all` flag considers every branch (local and remote). After fetch, commits pushed from other machines are also visible.

### Decision 5: Gap Analysis (No Automatic Deductions)
**What:** The system does NOT automatically deduct fixed times, instead it shows gap analysis compared to target hours.

**Why:**
- Meetings vary daily (standup skipped, ad-hoc meetings)
- The user knows better what to log for meetings
- Simpler and more transparent approach

**Config:**
```json
{
  "autoWorklog": {
    "dailyTarget": "8h"
  }
}
```

**Output:**
```
=== Daily Summary for 2024-01-15 ===

Git activity: 5h 30m (across 3 tasks)
Daily target: 8h
Gap: 2h 30m

Tip: The gap might be meetings, lunch, or other non-git work.
     Use 'wt-jira log <ticket> <duration>' to add manually.
```

**Logic:**
- Calculate git-based activity
- Display gap compared to target
- User decides what else to log (meetings, code review, etc.)

### Decision 6: Structured Worklog Comments
**What:** Storing structured metadata in worklog comments for later tracking and updates.

**Format:**
```
---wt-auto---
change: add-auto-worklog
source: git-commits
sessions:
  #1: 09:15-12:30 (3h 15m) @ office [abc1234, def5678]
  #2: 14:00-16:45 (2h 45m) @ home [jkl3456]
total: 6h
---/wt-auto---
```

**Block delimiters:**
- `---wt-auto---` and `---/wt-auto---` mark the block start and end
- The worklog comment can also contain other text (user notes, etc.)
- On update, only the content within the block is modified
- If no such block exists, it's appended to the end of the comment

**Fields:**
- `change` - The worktree/change identifier
- `source` - How it was calculated (git-commits, manual, mixed)
- `sessions` - List of work blocks, per session:
  - Time interval (start-end)
  - Duration in parentheses
  - Location hint (after @)
  - Commit hashes in square brackets
- `total` - Aggregated time

**Use Cases:**

1. **Incremental update**: If I logged 3 hours from the office in the morning, then worked 2 more hours from home in the evening:
   - The system detects the existing `[wt-auto]` worklog
   - Adds a new session to the existing ones
   - Updates the `timeSpent` value

2. **Audit trail**: Later reviewable where the time came from

3. **Duplicate detection**: Recognizes existing worklog based on `[wt-auto]` marker and date

**Location hints:**
- Estimated from git remote URL or hostname
- If the remote origin differs (e.g., office-git vs home-git), it may indicate location change
- Fallback: "session-1", "session-2", etc.

### Decision 7: CLI Interface
**What:** New `wt-jira auto` subcommand.

**Usage:**
```bash
# Today's worklogs
wt-jira auto

# For a specific date
wt-jira auto --date 2024-01-15
wt-jira auto --date yesterday
wt-jira auto --date "2 days ago"

# Dry-run (preview)
wt-jira auto --dry-run

# For a specific project only
wt-jira auto --project EXAMPLE

# Remote sync beforehand
wt-jira auto --fetch

# Interactive mode (asks for each task)
wt-jira auto --interactive
```

**Output (dry-run):**
```
=== Worklog Summary for 2024-01-15 ===

Activity detected: 09:15 - 17:45 (8h 30m)
Fixed deductions:
  - standup (09:30): -15m
  - lunch (12:00): -1h
Net work time: 7h 15m

Worktree allocations:
  [EXAMPLE-509] add-jira-integration
    Commits: 5 (09:15, 10:30, 11:45, 14:00, 16:30)
    Active: 09:15-11:45, 14:00-16:30
    Overlap with other tasks: 10:00-11:00
    Allocated: 4h 30m

  [OPENSPEC-123] add-openspec-feature
    Commits: 3 (10:00, 11:00, 17:45)
    Active: 10:00-11:00, 17:45
    Overlap with other tasks: 10:00-11:00
    Allocated: 2h 45m

Would log:
  EXAMPLE-509: 4h 30m
  OPENSPEC-123: 2h 45m

Use --yes to submit these worklogs.
```

## Risks / Trade-offs

### Risk 1: Inaccurate time estimation
- **Problem:** Commits don't precisely represent work time
- **Mitigation:** Buffer time addition, configurable settings
- **Fallback:** `--interactive` mode for manual override

### Risk 2: Complex overlap handling
- **Problem:** Many parallel tasks make fair distribution complex
- **Mitigation:** Simple proportional distribution, user can override

### Risk 3: Remote sync delay
- **Problem:** If we don't push on time, the other machine won't see the activity
- **Mitigation:** `--fetch` flag, warning if no push

### Risk 4: Fixed deductions not always relevant
- **Problem:** No standup in home office, or at different time
- **Mitigation:** Profile-based configuration (office/home)

## Migration Plan

1. Add new `auto` subcommand to `wt-jira`
2. Extend config schema with `autoWorklog` section
3. Documentation and examples

No breaking changes, the existing `wt-jira log` command remains unchanged.

## Open Questions

1. **Minimum activity threshold?** - How many commits needed to log? (Default: 1)
2. **Rounding?** - Round to 15 minutes or 30 minutes? (Default: 15m)
3. **Daily maximum?** - Should there be a cap on daily hours? (Default: none, but warning above 10h)
4. **Worklog started time?** - Should the worklog start time be the beginning of the day or the beginning of the block?
