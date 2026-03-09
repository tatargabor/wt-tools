# Tasks — fix-jest-playwright-coexistence

## Phase 1: Verifier — e2e_command in verify gate

### T1 — Add e2e_command to verifier.sh handle_change_done

- [x] Add `e2e_command` and `e2e_timeout` parameters to `handle_change_done()` function signature (after build check, before scope check)
- [x] Add e2e gate block: if `e2e_command` is non-empty AND `playwright.config.ts` exists in worktree, set `PW_PORT=$((3100 + RANDOM % 900))` and call `run_tests_in_worktree` with the e2e command
- [x] If `e2e_command` is set but `playwright.config.ts` missing: skip gracefully with `log_warn "Verify gate: e2e skipped for $change_name (no playwright.config.ts)"` — don't crash
- [x] On e2e fail: same retry logic as test_command — resume agent with error context, increment `verify_retry_count`, but use 4000 char truncation (not 2000) for e2e output
- [x] On e2e fail/timeout: cleanup zombie dev server with `pkill -f "pnpm dev.*--port $PW_PORT" 2>/dev/null || true`
- [x] Log: `Verify gate: e2e start/passed/failed/skipped for $change_name` (consistent with existing test/build log patterns)
- [x] Track timing: `gate_e2e_ms` field in state, same pattern as `gate_test_ms`
- [x] Store e2e results: `e2e_result` and `e2e_output` fields in change state

Files: `lib/orchestration/verifier.sh`

### T2 — Thread e2e_command through monitor.sh and poll_change

- [x] Read `e2e_command` and `e2e_timeout` from directives JSON in `monitor_loop()`
- [x] Pass `e2e_command` and `e2e_timeout` to `poll_change()` calls
- [x] Add parameters to `poll_change()` function signature, forward to `handle_change_done()`

Files: `lib/orchestration/monitor.sh`, `lib/orchestration/verifier.sh` (poll_change signature)

## Phase 2: Planner — per-change E2E ownership + bootstrap ordering

### T3 — Rewrite functional test planning section in planner.sh

- [x] Replace the "Functional test planning" block (lines ~686-700 in spec-mode, ~796-810 in brief-mode) with updated instructions:
  - The infrastructure/foundation change (first in dependency order) MUST set up Playwright alongside Jest:
    * `playwright.config.ts` with `PW_PORT` env var support and `webServer` auto-start
    * `jest.config.ts` with `testPathIgnorePatterns: ["/node_modules/", "/tests/e2e/"]`
    * `@playwright/test` in devDependencies
    * `npx playwright install chromium` (browser cache shared across worktrees)
    * `tests/e2e/global-setup.ts` with `prisma generate` + `prisma db push --force-reset` + `prisma db seed`
  - Each subsequent feature change creating a user-facing route MUST create `tests/e2e/<feature>.spec.ts` as an explicit file deliverable in scope (e.g., "Create tests/e2e/cart.spec.ts")
  - Do NOT defer all E2E tests to a consolidation change — each feature change owns its tests
  - Do NOT just list "Functional test scenarios:" as descriptions — create actual test files
- [x] Ensure both spec-mode and brief-mode get identical updated text

Files: `lib/orchestration/planner.sh`

## Phase 3: Template rules — coexistence and isolation docs (wt-project-web)

### T4 — Update testing-conventions.md with coexistence, isolation, and strategy docs

- [x] Add "## Testing Strategy — Testing Diamond" section:
  - Reference ISTQB test levels (unit, component integration, system/E2E)
  - Explain Testing Diamond: integration/E2E tests provide most business value for web apps
  - Unit tests for pure logic (utilities, validation, formatting)
  - E2E tests for runtime behavior (cookies, middleware, DB queries, user flows)
- [x] Add "## Two-Step Verification" section:
  - Step 1 (fast): `test_command` (Jest) + build — catches type/import errors
  - Step 2 (thorough): `e2e_command` (Playwright) — catches runtime bugs
  - Both run pre-merge in worktree
  - `smoke_command` (post-merge) optional for cross-feature integration
- [x] Add "## Playwright Infrastructure Bootstrap" section:
  - Must be set up in the infrastructure/foundation change, not feature changes
  - `playwright.config.ts` template with `PW_PORT` env var and `webServer` auto-start
  - `globalSetup` template: `prisma generate` → `prisma db push --force-reset` → `prisma db seed`
  - Browser install: `npx playwright install chromium` (one-time, cache shared)
- [x] Add "## Jest/Playwright Coexistence" section:
  - Jest default `testRegex` matches `.spec.ts` — crashes on Playwright imports in jsdom
  - MUST add `testPathIgnorePatterns: ["/node_modules/", "/tests/e2e/"]` to jest config
- [x] Add "## Port Isolation for Parallel E2E" section:
  - Orchestrator sets `PW_PORT` env var per worktree (random in 3100-3999)
  - Playwright config reads `PW_PORT`, default 3100
  - `webServer.reuseExistingServer: false` to detect port collisions
- [x] Add "## DB Isolation for E2E Tests" section:
  - SQLite: automatic — each worktree has its own `dev.db`, schema divergence naturally isolated
  - PostgreSQL/MySQL: per-worktree database names (future `e2e_db_setup`/`e2e_db_teardown` hooks)
  - Always run `prisma generate` before `prisma db push` to handle new models per-change

Files: `wt-project-web/wt_project_web/templates/nextjs/rules/testing-conventions.md`

### T5 — Update smoke-test.yaml directive with e2e_command

- [x] Add `e2e` section with `command: "npx playwright test"` and `timeout: 120`
- [x] Add comment documenting that `smoke_command` is optional when `e2e_command` covers per-change E2E
- [x] Document the two-step relationship: e2e = pre-merge per-change, smoke = post-merge cross-feature

Files: `wt-project-web/wt_project_web/directives/smoke-test.yaml`
