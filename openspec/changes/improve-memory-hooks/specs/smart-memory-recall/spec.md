## ADDED Requirements

### Requirement: OpenSpec-aware query building
The recall hook detects pending/incomplete OpenSpec changes and builds recall queries from completed change names rather than from the raw prompt text.

#### Scenario: 4 of 6 changes completed
- **WHEN** openspec list shows product-catalog, shopping-cart, multi-vendor, discounts as completed and checkout, order-workflow as pending
- **THEN** the recall query searches for memories tagged with the completed change names

#### Scenario: No openspec directory
- **WHEN** the project has no `openspec/` directory
- **THEN** the hook falls back to prompt-based recall (current behavior)

#### Scenario: All changes completed
- **WHEN** all OpenSpec changes are completed
- **THEN** no recall is performed (nothing pending to inform)

### Requirement: Actionable output format
The recall output is formatted as a concise bulleted list with an instruction header, not raw memory JSON.

#### Scenario: Recall returns 3 memories
- **WHEN** 3 memories are found for completed changes
- **THEN** output format is:
  ```
  === PROJECT MEMORY ===
  Previously completed changes — maintain consistency:
  • product-catalog: SQLite+Prisma, images as JSON string, auto-increment IDs
  • shopping-cart: Session-based cart, stock reservation with $transaction
  • multi-vendor: Optional vendorId migration, order split by vendor into SubOrders
  === END ===
  ```

#### Scenario: No memories found
- **WHEN** no memories match the query
- **THEN** no output is produced (silent exit)

### Requirement: Timeout safety
The recall hook must complete within its 15-second timeout even if openspec list or wt-memory recall is slow.

#### Scenario: openspec list hangs
- **WHEN** openspec list takes >5 seconds
- **THEN** the hook falls back to prompt-based recall or exits silently
