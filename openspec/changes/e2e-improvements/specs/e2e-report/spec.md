## ADDED Requirements

### R1: Post-Run Report Generation
- After orchestration completes (status `done` or `failed`), a report is generated at `e2e-report.md` in the project directory
- Report reads `orchestration-state.json` for structured data
- Report includes:
  - Run summary: total duration, total tokens, total changes, pass/fail count
  - Per-change table: name, status, tokens used, duration (started_at to completed_at), test suite count, test pass count
  - Timeline: chronological list of change state transitions
  - Directives used (from state.json)
  - Comparison with previous report if `e2e-report-prev.md` exists

#### Scenario: Successful run report
- **WHEN** orchestration completes with status `done`
- **THEN** `e2e-report.md` contains all sections with accurate data from `orchestration-state.json`

### R2: Screenshot Capture
- After orchestration completes, start the app server and capture screenshots using Playwright (headless Chromium)
- Screenshots captured for each frontend page: storefront, cart (with items), orders, admin login, admin products
- Screenshots saved to `e2e-screenshots/` directory as PNG files
- Screenshots are referenced in the report as relative image links
- Server is started before screenshots and killed after

#### Scenario: Screenshot capture flow
- **WHEN** the report generator runs after a successful orchestration
- **THEN** it starts `pnpm start` (production build), waits for the server, runs the Playwright screenshot script at `tests/e2e/capture-screenshots.ts`, embeds results in report, and stops the server

### R3: Report CLI
- `bin/wt-e2e-report` is a standalone script that can be run manually
- Accepts `--project-dir <path>` to specify the project directory (defaults to CWD)
- Accepts `--screenshots` flag to enable screenshot capture (default: enabled)
- Accepts `--no-screenshots` to skip screenshot capture
- Exit code 0 on success, 1 on failure
