## Why

Milestone checkpoints currently start a dev server and send an email with text-only stats (change count, tokens, server URL). The human must manually open the localhost URL and click through pages to verify the build looks correct. For complex orchestrations (1-2 hours, 8+ changes), this friction means visual regressions, missing features, or design drift go unnoticed until the end.

Adding automatic screenshots to milestone emails lets the human glance at the email (3 seconds) and see whether the phase produced the expected result — without opening a browser.

## What Changes

- Add `capture_milestone_screenshots()` function that uses a headless browser to screenshot configured URLs from the milestone dev server
- Extend `_send_milestone_email()` to embed screenshots as base64 inline images in the HTML email
- Add `milestones.screenshots.*` directives for URL list, viewport size, and optional custom capture command
- Parse new screenshot directives through the existing config resolution pipeline

## Capabilities

### New Capabilities
- `milestone-screenshots`: Automatic screenshot capture of milestone dev server pages and inline embedding in milestone notification emails

### Modified Capabilities
<!-- No existing spec-level requirements change — this is additive to the milestone checkpoint flow -->

## Modular Architecture Note

The milestone system is now Python-based (`lib/wt_orch/milestone.py`), not bash. The orchestration engine runs in Python and directives are parsed through `wt/orchestration/config.yaml`. Implementation must target:

- **wt-tools** (`lib/wt_orch/milestone.py`): capture function, email embedding, directive parsing — all in Python
- **wt-project-web** (optional): web-specific default screenshot URLs (e.g., `/`, `/admin`) could be provided via a new profile method, but core capture logic stays in wt-tools
- Bash files (`lib/orchestration/milestone.sh`, `utils.sh`, `config.sh`) are legacy — do NOT add new functionality there

## Impact

- `lib/wt_orch/milestone.py` — new `capture_milestone_screenshots()`, extended `_send_milestone_email()`
- `wt/orchestration/config.yaml` — new `milestones.screenshots.*` directives
- No new runtime dependencies — uses `npx playwright screenshot` (already available in JS projects) with graceful fallback (skip if unavailable)
