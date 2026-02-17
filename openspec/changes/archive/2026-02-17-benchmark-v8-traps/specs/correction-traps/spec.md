## ADDED Requirements

### Requirement: C02 Developer Notes section
The C02 change file (`02-tags-filtering.md`) SHALL include a "Developer Notes (from code review of C01)" section containing 4 corrections that simulate human feedback. These corrections MUST be stripped from the agent-visible file along with evaluator notes (init.sh already strips `<!-- EVALUATOR NOTES BELOW`).

**Wait — correction**: The Developer Notes are agent-visible (they simulate what a human would tell the agent). Only the Evaluator Notes section is stripped. The Developer Notes MUST remain in the agent-visible change file.

#### Scenario: C02 change file contains Developer Notes
- **WHEN** the agent reads `docs/changes/02-tags-filtering.md`
- **THEN** the file contains a "Developer Notes" section with corrections T7, T8, T9, T10

### Requirement: T7 — Error code format override
C02 Developer Notes SHALL instruct: "We're switching error codes from SCREAMING_SNAKE (e.g., `EVT_NOT_FOUND`) to dot.notation (e.g., `event.not_found`). Update C02 code and all future code MUST use dot.notation."

The project-spec.md SHALL keep the old SCREAMING_SNAKE convention (intentionally stale). C01 code SHALL retain SCREAMING_SNAKE codes.

#### Scenario: T7 probe passes in C03
- **WHEN** score.sh checks C03 route files for error codes
- **THEN** `grep -E '[a-z]+\.[a-z_]+' <file>` finds dot.notation error codes (e.g., `comment.not_found`)
- **AND** `grep -E '[A-Z]{2,}_[A-Z]{2,}' <file>` does NOT find SCREAMING_SNAKE codes in C03-C05 route files

#### Scenario: T7 probe passes in C05
- **WHEN** score.sh checks C05 route files for error codes
- **THEN** dot.notation codes are present (e.g., `bulk.empty_ids`, `bulk.purge_too_recent`)

### Requirement: T8 — Response nesting with result key
C02 Developer Notes SHALL instruct: "Wrap entity data in a `result` key. List responses become `{ok: true, result: {entries: [...], paging: {...}}}`. Single-item responses become `{ok: true, result: {event: {...}}}`. This helps frontend distinguish data from metadata."

C01 code SHALL retain the flat format (no `result` key). project-spec.md SHALL document the flat format (intentionally stale).

#### Scenario: T8 probe passes in C03
- **WHEN** score.sh checks C03 route files
- **THEN** response objects include a `result` key wrapping the entity data

#### Scenario: T8 probe passes in C05
- **WHEN** score.sh checks C05 route files
- **THEN** response objects include a `result` key wrapping the entity data

### Requirement: T9 — Forward-looking batch POST advice
C02 Developer Notes SHALL include: "When we add bulk endpoints later, use POST with body `{ids: [...]}` for operations on multiple items. Express doesn't parse array query params reliably. Don't use GET with `?ids=1,2,3`."

This advice has NO corresponding code in C01 or C02. Only memory carries it to C05.

#### Scenario: T9 probe passes in C05
- **WHEN** score.sh checks C05 bulk route file
- **THEN** batch operations use `req.body.ids` or `req.body.*Ids` (POST body)
- **AND** batch operations do NOT use `req.query.ids` (query params)

### Requirement: T10 — Sort parameter convention
C02 Developer Notes SHALL include: "For ordered lists, support `?order=newest|oldest` parameter, not `?sort=desc|asc`. Our frontend expects `order`."

No code in C01 or C02 implements sorting (C01 uses hardcoded `ORDER BY createdAt DESC`). C03-C05 endpoints that support sorting MUST use the `order` parameter.

#### Scenario: T10 probe passes in C04
- **WHEN** score.sh checks C04 dashboard/activity route files
- **THEN** `grep -E 'req\.query\.order|order.*newest|order.*oldest' <file>` matches
- **AND** `grep -E 'req\.query\.sort|sort.*desc|sort.*asc' <file>` does NOT match

### Requirement: Existing traps preserved
The existing 6 traps (T1-T6) SHALL remain unchanged. T7-T10 are additive.

#### Scenario: All 10 traps scored
- **WHEN** score.sh runs on a project
- **THEN** it reports scores for T1 through T10

### Requirement: project-spec.md intentional staleness
The project-spec.md conventions section SHALL retain C01-era conventions:
- Error codes: SCREAMING_SNAKE (overridden by T7 to dot.notation)
- Response format: flat `{ok, entries, paging}` (overridden by T8 to result-wrapped)

This creates the intended conflict: spec says X, C02 human said Y.

#### Scenario: Stale spec conflict
- **WHEN** an agent reads project-spec.md in C03-C05
- **THEN** it sees SCREAMING_SNAKE error codes and flat response format
- **BUT** if memory contains C02 corrections, the agent follows dot.notation and result-wrapped format
