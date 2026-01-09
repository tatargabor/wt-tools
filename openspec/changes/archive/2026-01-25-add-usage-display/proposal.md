# Change: Add Usage Display

JIRA Key: TBD
Story: EXAMPLE-466

## Why
The Control Center currently doesn't show Claude usage statistics. The user doesn't know whether they're over- or under-utilizing their available quota.

## What Changes
- Add usage panel to the GUI with custom implementation
- Display: 5h block %, daily/weekly capacity
- Progress bar visual indicator
- Reads data from Settings API

## Data Source
**Custom implementation** (not ccusage):
- Usage data read from Claude Settings API
- 5-hour block limit - rolling window
- Daily/weekly aggregation

**Advantages over ccusage:**
- No external NPM dependency
- Percentage-based (not USD)
- Real-time, not log file parsing
- Directly integrable with Ralph loop

## UI Design Options

### Option A: Rotating Status Label (Recommended)
The top status label rotates every 5 seconds:
1. "4 worktrees | 2 running" (current)
2. "Usage: $45.20/week | Burn: 87%" (new)

Advantage: Takes no extra space, simple implementation

### Option B: Collapsible Panel
Clickable "Usage" row above the table that shows detailed data when expanded.

Advantage: More data fits, but more complex

### Option C: Status Bar Bottom
Permanent row below the button row with usage data.

Advantage: Always visible, but increases window size

## Usage Model

The subscription provides two limits:
- **5h block**: Rolling 5-hour window - short-term burst limit
- **Weekly**: Weekly window - long-term limit

Both are measured in real-time by the GUI and warn when approaching the limit.
The Ralph loop also uses these as capacity limits.

## Impact
- Affected specs: control-center
- Affected code: gui/main.py
- New dependency: None (custom implementation)
