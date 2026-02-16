## ADDED Requirements

### Requirement: Schema consistency evaluator
Create `benchmark/evaluator/eval-schema.sh` that inspects the Prisma schema in a benchmark repo.

Checks:
- After C08: `Image` model exists with `productId` FK; `Product` has no `images` field
- After C09: All money fields are `Int` type (grep for known field names)
- After C07: `CartReservation` model exists with `expiresAt` field
- `Variant` is a separate model (not JSON in Product)
- All FK relations are defined

Output: JSON with `{check, passed, details}` per check.

#### Scenario: Run against completed repo
- **WHEN** `eval-schema.sh ~/benchmark/run-a/craftbazaar` is executed
- **THEN** outputs JSON array of check results with pass/fail per check

---

### Requirement: API consistency evaluator
Create `benchmark/evaluator/eval-api.sh` that inspects API route files for consistent patterns.

Checks:
- All list endpoints use same response format (detect the pattern from the first endpoint, verify others match)
- Error responses follow consistent structure
- Money amounts in responses use consistent format (all cents or all dollars, not mixed)

Output: JSON with check results.

#### Scenario: Detect mixed response formats
- **WHEN** `/api/products` returns `{data: [...]}` but `/api/vendors` returns `{vendors: [...]}`
- **THEN** API consistency check fails with details about the mismatch

---

### Requirement: Behavioral correctness evaluator
Create `benchmark/evaluator/eval-behavior.sh` that inspects implementation code for correctness.

Checks:
- After C07: Cart add handler does NOT contain stock decrement logic
- After C07: Checkout handler DOES contain stock decrement logic
- After C05: Checkout is wrapped in transaction (`$transaction` or similar)
- Payout calculation: verify formula accounts for discounts (grep for discount subtraction in payout code)

Output: JSON with check results.

#### Scenario: Stock logic moved correctly
- **WHEN** eval checks cart add handler after C07
- **THEN** no `stockQuantity` decrement found in cart add, but found in checkout confirm

---

### Requirement: Cross-change coherence evaluator
Create `benchmark/evaluator/eval-coherence.sh` that checks overall project health.

Checks:
- `npx prisma validate` passes (schema is valid)
- No TypeScript compilation errors (`npx tsc --noEmit`)
- Seed script runs without error
- No orphaned imports (files importing from deleted modules)

Output: JSON with check results.

#### Scenario: Schema validates
- **WHEN** `npx prisma validate` is run in the benchmark repo
- **THEN** exits 0 with no errors
