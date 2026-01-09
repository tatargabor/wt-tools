# Tasks: Add Usage Display

## Implementation Tasks

- [x] Add UsageWorker class to fetch usage data in background
  - Parse Claude Settings API for usage data
  - Run periodically (30s interval)
  - Extract 5h block and weekly capacity percentages

- [x] Add usage data model
  - 5h block: percentage used (short-term burst limit)
  - Weekly: percentage used (long-term limit)
  - No USD - only capacity percentage from subscription

- [x] Implement usage progress bars
  - 5h block progress bar
  - Weekly progress bar
  - Color coding: green (<70%), yellow (70-90%), red (>90%)

- [x] Add to GUI
  - Progress bars in header/footer area
  - Percentage labels
  - Tooltip with details

- [x] Graceful fallback
  - Show "N/A" if data unavailable
  - Don't crash if API changes

- [x] Test and validate
  - Verify percentage accuracy
  - Check performance impact of background polling

## Notes

**Decision:** Custom implementation, not ccusage
- Advantage: no external dependency
- Advantage: percentage-based (not USD)
- Advantage: real-time, not log parsing
- Advantage: integrable with Ralph loop capacity limit
