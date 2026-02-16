## MODIFIED Requirements

### Requirement: OpenSpec-aware query building
The recall hook detects completed changes from git commit history and builds recall queries from those change names rather than from the raw prompt text.

#### Scenario: 4 of 6 changes completed
- **WHEN** git log contains commits with messages like `product-catalog: ...`, `shopping-cart: ...`, `multi-vendor: ...`, `discounts: ...`
- **AND** no commits exist for `checkout` or `order-workflow`
- **THEN** the recall query SHALL search for memories matching the completed change names extracted from commit messages

#### Scenario: No openspec directory
- **WHEN** the project has no `openspec/` directory
- **THEN** the hook falls back to prompt-based recall (first 200 chars of prompt text)

#### Scenario: No committed changes found
- **WHEN** git log contains no commits matching the `change-name: description` format
- **THEN** the hook falls back to prompt-based recall
