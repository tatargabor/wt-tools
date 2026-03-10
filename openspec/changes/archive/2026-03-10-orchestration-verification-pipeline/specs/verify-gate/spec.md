## MODIFIED Requirements

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

## ADDED Requirements

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
- **THEN** the prompt SHALL extend the existing granularity section (near "One requirement = one independently testable behavior") with additional rules:
  - Each requirement MUST describe exactly ONE testable behavior
  - CRUD operations on an entity produce at minimum 4 separate requirements
  - Multiple distinct user actions in a single spec section produce one REQ per action
  - Edge cases and error handling explicitly mentioned in the spec produce separate requirements
  - Compound descriptions like "Users can X and Y" produce TWO requirements
  - A requirement is too coarse if testing it requires covering multiple independent behaviors

#### Scenario: Granularity rules extend existing prompt text
- **WHEN** granularity rules are added
- **THEN** they SHALL be appended to the existing granularity paragraph in Section 2 of the digest prompt
- **AND** SHALL NOT duplicate or contradict the existing example ("Cart supports coupons" → too broad)

#### Scenario: Granularity rules do not affect existing digest structure
- **WHEN** granularity rules are added to the prompt
- **THEN** the digest output format (requirements.json, domains/*.md, etc.) SHALL remain unchanged
- **AND** only the number and specificity of extracted requirements SHALL increase
