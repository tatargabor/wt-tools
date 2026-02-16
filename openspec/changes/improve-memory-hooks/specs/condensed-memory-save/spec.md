## ADDED Requirements

### Requirement: Condensed choice extraction
The save hook extracts only `**Choice**:` lines from `openspec/changes/<name>/design.md`, strips markdown formatting, and joins them with `. ` separator.

#### Scenario: Design.md with 4 decisions
- **WHEN** a new commit is detected for change "shopping-cart" and design.md contains 4 `**Choice**:` entries
- **THEN** one memory is saved with content like: `shopping-cart: Session-based cart (sessionId cookie). Stock reservation on add-to-cart (decrement variant stock). Prisma $transaction for all stock ops. Cart total computed server-side (not stored).`

### Requirement: Single memory per change
The save hook saves exactly one Decision-type memory per change, tagged with `change:<name>,phase:apply,source:hook,decisions`.

#### Scenario: First commit for a change
- **WHEN** a commit with message "shopping-cart: Cart system with stock reservation" is detected AND design.md exists for "shopping-cart" AND no memory has been saved for this change yet
- **THEN** exactly one memory is saved (not three)

#### Scenario: Second commit for same change
- **WHEN** another commit for "shopping-cart" is detected AND the design marker already includes "shopping-cart"
- **THEN** no additional memory is saved (idempotent)

#### Scenario: No design.md exists
- **WHEN** a commit is detected but no design.md exists for the change
- **THEN** a fallback memory is saved with just the commit message

### Requirement: Memory size target
Each saved memory should be under 300 characters to fit within recall truncation limits.

#### Scenario: Long design with many decisions
- **WHEN** design.md has 6+ decisions generating >300 chars of choices
- **THEN** the content is truncated to 300 chars with `...` suffix
