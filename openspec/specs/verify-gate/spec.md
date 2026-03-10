### Requirement: Verify gate step order
The verify gate SHALL execute quality checks in a fixed order with fail-fast semantics.

#### Scenario: Full gate pipeline
- **WHEN** a change completes (Ralph done)
- **THEN** the verify gate SHALL execute in this order:
  1. **Test execution** — run `test_command` if configured. Fail → retry agent with test output.
  2. **Build verification** — run `build` or `build:ci` from package.json. Fail → retry agent with build output.
  3. **Test file existence check** — check if diff contains `.test.` or `.spec.` files. Missing → WARNING notification only (non-blocking).
  4. **LLM code review** — if `review_before_merge: true`, run review via configurable model (default: sonnet). CRITICAL severity → retry agent with review feedback.
  5. **OpenSpec verify** — run `/opsx:verify {change_name}` via Claude with max 5 turns. Fail → retry agent with verify output.

#### Scenario: Build failure skips review and verify
- **WHEN** build verification fails
- **THEN** the gate SHALL NOT proceed to LLM review or OpenSpec verify
- **AND** SHALL retry the agent with build error context (saving LLM tokens)

#### Scenario: Test failure skips all subsequent gates
- **WHEN** test execution fails
- **THEN** the gate SHALL NOT proceed to build, review, or verify

### Requirement: Test execution in worktree
The verify gate SHALL run the configured test command in the change worktree with timeout.

#### Scenario: Test execution with timeout
- **WHEN** `test_command` is configured (non-empty)
- **THEN** the gate SHALL run `timeout {test_timeout} bash -c "{test_command}"` in the worktree
- **AND** capture exit code and output (truncated to 2000 chars)
- **AND** default `test_timeout` is 300 seconds (configurable via directive)

#### Scenario: No test command configured
- **WHEN** `test_command` is empty or unset
- **THEN** the gate SHALL skip test execution entirely

### Requirement: Build verification before merge
The verify gate SHALL detect and run the project build command.

#### Scenario: Build command detection
- **WHEN** `package.json` exists in the worktree
- **THEN** the gate SHALL check for `build:ci` script first, then `build`
- **AND** detect package manager from lockfile (pnpm > yarn > bun > npm)

#### Scenario: Base build health check
- **WHEN** the worktree build fails
- **THEN** the gate SHALL check if the main branch also fails
- **AND** if main fails: attempt `fix_base_build_with_llm()`, sync worktree, re-run build (no retry consumed)
- **AND** if main passes: sync worktree with main, re-run build to see if inherited fixes help
- **AND** if still failing after sync: attribute to agent code, proceed with normal retry

### Requirement: Test failure retry with context
The verify gate SHALL retry Ralph with test/build/review failure context.

#### Scenario: Test failure retry
- **WHEN** tests fail and `verify_retry_count` < `max_verify_retries` (default: 2)
- **THEN** the gate SHALL increment `verify_retry_count`, set status to `verify-failed`
- **AND** create `retry_context` with: test command, test output, original scope, and relevant memories
- **AND** call `resume_change()` which launches Ralph with the retry context

#### Scenario: Retry exhausted
- **WHEN** `verify_retry_count` >= `max_verify_retries`
- **THEN** the gate SHALL mark status `failed` and send a critical notification

### Requirement: LLM code review gate
The verify gate SHALL run an LLM code review that includes both security/quality checks AND requirement coverage verification.

#### Scenario: Review enabled
- **WHEN** `review_before_merge: true` directive is set
- **THEN** the gate SHALL generate a git diff (change branch vs merge-base, max 30000 chars)
- **AND** send to Claude (configurable via `review_model`, default: sonnet) with security-focused review criteria
- **AND** parse for CRITICAL severity — if found, treat as failure and retry

#### Scenario: Requirement-aware review in digest mode
- **WHEN** `review_before_merge: true` is set
- **AND** `wt/orchestration/digest/requirements.json` exists (digest mode proxy)
- **THEN** the review prompt SHALL include the current change's assigned REQ-* IDs (from `requirements[]` in `orchestration-state.json`) with titles and briefs looked up from `wt/orchestration/digest/requirements.json`
- **AND** the review prompt SHALL include `also_affects_reqs[]` with a note that these are secondary (awareness only, do not flag as missing)
- **AND** the prompt SHALL explicitly ask: "For each ASSIGNED requirement, verify the diff contains implementation evidence. Report any REQ-* ID with no implementation as CRITICAL."
- **AND** the injected list SHALL be per-change only (typically 3-15 REQs), NOT the full digest requirement set

#### Scenario: Requirement data lookup for review
- **WHEN** building the requirement-aware review prompt
- **THEN** the gate SHALL call `build_req_review_section(change_name)` which:
  1. Reads `requirements[]` and `also_affects_reqs[]` from `$STATE_FILENAME` for the given change via jq
  2. Looks up each REQ-ID's title and brief from `$DIGEST_DIR/requirements.json`
  3. Returns a formatted prompt section with "Assigned Requirements" and "Cross-Cutting Requirements" subsections
  4. Returns empty string if no requirements found or digest file missing

#### Scenario: Change with zero requirements in digest mode
- **WHEN** building the requirement-aware review prompt
- **AND** the change has an empty `requirements[]` array in state (possible for cleanup/schema type changes)
- **THEN** `build_req_review_section()` SHALL return empty string
- **AND** the review SHALL proceed with the existing scope-based prompt only

#### Scenario: REQ-ID not found in digest requirements.json
- **WHEN** building the requirement-aware review prompt
- **AND** a REQ-ID from the change's `requirements[]` is not found in `wt/orchestration/digest/requirements.json`
- **THEN** the function SHALL include the REQ-ID with "(not found in digest)" as brief
- **AND** SHALL log a warning but NOT fail

#### Scenario: Missing requirement triggers retry with structured context
- **WHEN** the LLM review identifies a REQ-* ID as having no implementation in the diff
- **AND** reports it as CRITICAL
- **THEN** the gate SHALL treat this as a review failure
- **AND** retry the agent with enriched retry context that includes: the specific unimplemented REQ-IDs extracted from the review output, not just a truncated review snippet
- **AND** the retry prompt SHALL say: "The code review found these requirements have no implementation evidence: {REQ-IDs}. Implement them or explain why they are already covered."

#### Scenario: Non-digest mode falls back to existing behavior
- **WHEN** `review_before_merge: true` is set
- **AND** `wt/orchestration/digest/requirements.json` does NOT exist (brief/spec mode)
- **THEN** the review SHALL use only the existing scope-based prompt without requirement injection

#### Scenario: Review escalation preserves requirement section
- **WHEN** the initial review model fails and the review escalates to opus
- **THEN** the escalated review prompt SHALL include the same requirement section as the initial prompt

#### Scenario: Review disabled
- **WHEN** `review_before_merge` is false or unset
- **THEN** the gate SHALL skip LLM review entirely

### Requirement: Merge-rebase fast path
Changes returning from agent-assisted merge rebase SHALL skip the full verify gate.

#### Scenario: Merge rebase pending flag
- **WHEN** `handle_change_done()` detects `merge_rebase_pending = true`
- **THEN** it SHALL clear the flag, skip all verify gates, and proceed directly to merge test

### Requirement: Verify gate state tracking
The verify gate SHALL track detailed state for each quality check.

#### Scenario: State fields after verification
- **WHEN** a change passes through the verify gate
- **THEN** the change state SHALL include: `test_result` (pass/fail/skip), `test_output`, `build_result` (pass/fail), `review_result` (pass/critical), `has_tests` (boolean), `gate_test_ms`, `gate_build_ms`, `gate_review_ms`, `gate_verify_ms`, `gate_total_ms`, `gate_retry_tokens`, `gate_retry_count`

### Requirement: Model tiering
The orchestrator SHALL use different Claude models for different tasks to optimize cost.

#### Scenario: Model assignment
- **WHEN** invoking Claude for different purposes
- **THEN** the orchestrator SHALL use:
  - **Opus**: plan decomposition (hardcoded, non-configurable)
  - **Haiku**: spec summarization (configurable via `summarize_model` directive)
  - **Sonnet**: code review and fix retry (configurable via `review_model` directive)
  - **Opus**: Ralph loop implementation (via `--model opus` flag)

### Requirement: Auto-merge pipeline
The orchestrator SHALL support three merge policies.

#### Scenario: Eager merge
- **WHEN** `merge_policy: eager`
- **THEN** the orchestrator SHALL call `wt-merge {name} --no-push --llm-resolve` immediately after verification
- **AND** on conflict, add to merge queue for retry

#### Scenario: Checkpoint merge
- **WHEN** `merge_policy: checkpoint`
- **THEN** the orchestrator SHALL add completed changes to `merge_queue`
- **AND** execute the queue on `wt-orchestrate approve --merge`

#### Scenario: Manual merge
- **WHEN** `merge_policy: manual`
- **THEN** the orchestrator SHALL NOT merge automatically
## Requirements
### Requirement: Verify gate step order
The verify gate SHALL execute quality checks in a fixed order, with fail-fast semantics to avoid wasting resources on code that fails earlier gates.

#### Scenario: Full gate pipeline execution order
- **WHEN** a change completes (Ralph done)
- **THEN** the verify gate SHALL execute in this order:
  1. **Test execution** — run `test_command` if configured. Fail → retry agent with test output
  2. **Build verification** — run `build` or `build:ci` from package.json. Fail → retry agent with build output
  3. **Test file existence check** — check if diff contains `.test.` or `.spec.` files. Missing → WARNING notification only (non-blocking)
  4. **LLM code review** — if `review_before_merge: true`, run Sonnet review. CRITICAL → retry agent with review feedback
  5. **OpenSpec verify** — run `/opsx:verify {change_name}`. Fail → retry agent with verify output

#### Scenario: Build failure skips review and verify
- **WHEN** build verification fails
- **THEN** the gate SHALL NOT proceed to LLM review or OpenSpec verify
- **AND** SHALL retry the agent with build error context (saving LLM tokens)

#### Scenario: Test failure skips all subsequent gates
- **WHEN** test execution fails
- **THEN** the gate SHALL NOT proceed to build, review, or verify
- **AND** SHALL retry the agent with test failure context

### Requirement: Base build health check before agent retry
When a worktree build fails, the orchestrator SHALL check if the main branch also fails before blaming the agent.

#### Scenario: Main branch also broken
- **WHEN** worktree build fails
- **AND** main branch build also fails
- **THEN** the orchestrator SHALL attempt `fix_base_build_with_llm()` on main
- **AND** if main is fixed, sync the worktree and re-run build without consuming a retry

#### Scenario: Main branch builds OK
- **WHEN** worktree build fails
- **AND** main branch builds successfully
- **THEN** the orchestrator SHALL sync the worktree with latest main
- **AND** re-run the build to see if inherited fixes resolve it
- **AND** if still failing, attribute to agent code and proceed with normal retry

### Requirement: Merge-rebase fast path in verify gate
Changes returning from agent-assisted merge rebase SHALL skip the full verify gate.

#### Scenario: Merge rebase pending flag
- **WHEN** `handle_change_done()` detects `merge_rebase_pending = true`
- **THEN** it SHALL clear the flag
- **AND** skip test/build/review/verify gates
- **AND** perform a dry-run merge test directly
- **AND** proceed to merge or enter merge-blocked queue

### Requirement: State initialization includes requirement assignments
The `init_state()` function SHALL copy requirement assignments from the plan to the state for each change.

#### Scenario: Plan with requirements and also_affects_reqs
- **WHEN** `init_state()` creates orchestration state from a digest-mode plan
- **AND** a change in the plan has `requirements[]` and/or `also_affects_reqs[]` arrays
- **THEN** the state change object SHALL include those arrays verbatim

#### Scenario: Plan without requirement fields
- **WHEN** `init_state()` creates state from a non-digest plan (brief/spec mode)
- **AND** a change does not have `requirements[]` or `also_affects_reqs[]`
- **THEN** the state change object SHALL omit those fields (no empty arrays added)

### Requirement: Digest prompt granularity instructions
The digest prompt SHALL include explicit granularity rules to produce finer-grained requirements.

#### Scenario: Granularity rules in digest prompt
- **WHEN** `build_digest_prompt()` constructs the prompt for requirement extraction
- **THEN** the prompt SHALL extend the existing granularity section with additional rules:
  - Each requirement MUST describe exactly ONE testable behavior
  - CRUD operations on an entity produce at minimum 4 separate requirements
  - Multiple distinct user actions in a single spec section produce one REQ per action
  - Edge cases and error handling explicitly mentioned in the spec produce separate requirements
  - Compound descriptions produce TWO requirements
  - A requirement is too coarse if testing it requires covering multiple independent behaviors

#### Scenario: Granularity rules extend existing prompt text
- **WHEN** granularity rules are added
- **THEN** they SHALL be appended to the existing granularity paragraph in Section 2 of the digest prompt
- **AND** SHALL NOT duplicate or contradict existing examples

#### Scenario: Granularity rules do not affect existing digest structure
- **WHEN** granularity rules are added to the prompt
- **THEN** the digest output format (requirements.json, domains/*.md, etc.) SHALL remain unchanged
- **AND** only the number and specificity of extracted requirements SHALL increase

