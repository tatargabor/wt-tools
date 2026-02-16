# Change 12: Sprint Retrospective Fixes

## Agent Input

### Overview

The sprint retrospective identified 5 bugs across the codebase. Fix all of them.

### Bug Reports

1. **API response format inconsistency**: Some list endpoints return `{ data: [...] }`, others return `{ products: [...] }` or `{ vendors: [...] }` or just `[...]`. Standardize ALL list endpoints to return `{ data: [...], total: N }` format. This includes: products, vendors, orders, coupons, sub-orders — any endpoint that returns a list.

2. **Payout rounding off-by-one with 3+ vendors**: When an order has items from 3 or more vendors, the sum of all vendor payouts doesn't equal the payment amount. The platform fee and payout net amounts have rounding drift. Fix: implement the largest-remainder method for integer splitting — give the remainder cent(s) to the vendor(s) with the largest fractional parts.

3. **Expired reservation checkout returns 500**: When a user tries to check out with a cart that has expired reservations (from the C07 soft-reserve system), the API returns a 500 Internal Server Error instead of a helpful 400 response. Fix: catch the reservation-related error and return `{ error: "Cart reservation expired. Please re-add items." }` with status 400.

4. **Missing database index**: The `SubOrder` table is frequently queried by `vendorId` (for the vendor dashboard), but there's no database index. Add `@@index([vendorId])` to the SubOrder model in the Prisma schema.

5. **Seed data mixes dollars and cents**: After the C09 migration to integer cents, the seed script has some values still in dollars (e.g., `basePrice: 29.99` instead of `basePrice: 2999`) and some in cents. This causes test data to have products priced at $0.30 instead of $29.99. Fix the seed script to use cents consistently everywhere.

### Acceptance Criteria

- [ ] All list API endpoints return `{ data: [...], total: N }` format
- [ ] Payout split for 3-vendor orders sums exactly to payment amount
- [ ] Expired reservation checkout returns 400 with helpful message
- [ ] SubOrder model has `@@index([vendorId])` in Prisma schema
- [ ] Seed script uses integer cents for all money values
- [ ] `npx prisma migrate dev` runs without errors
- [ ] `npx prisma db seed` produces consistent data

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T12.1: Finding ALL list endpoints (cross-cutting search)**
The agent must identify every API route that returns a list. These are spread across multiple files from C01 (products), C03 (vendors, orders), C04 (coupons), C06 (sub-orders). Without memory of the API structure, this requires a full codebase search.

**Memory prediction**: HIGHEST VALUE recall. Memory-enabled agent knows exactly which files contain list endpoints and what format each currently uses. No-memory agent must `grep -r` for route handlers and check each one.

**T12.2: Largest-remainder payout splitting**
This is an algorithmic challenge. The naive approach (round each payout individually) creates the off-by-one problem. The correct approach:
1. Calculate each vendor's exact share as a fraction
2. Floor each share to get integer cents
3. Distribute remaining cents to vendors with largest remainders

Without knowing WHERE the payout calculation lives (C05's checkout flow), the agent must search for it.

**Memory prediction**: HIGH VALUE recall for location. The algorithm itself is a pure coding task, but finding the payout calculation code requires memory of C05's implementation.

**T12.3: Reservation error handling location**
The expired reservation error happens in the checkout flow (C07 modifications to C05). The agent must find where reservation validation happens and add a try/catch or conditional check with proper error response.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent knows exactly where cart reservation is validated during checkout.

**T12.4: SubOrder model location**
The `@@index` must be added to the correct model in schema.prisma. Simple if you know the file, but requires finding the SubOrder definition.

**Memory prediction**: Medium value — schema.prisma is a single file, but knowing the model is there from C03 helps.

**T12.5: Seed script dollar/cent mixup**
The seed script was originally written with dollar values (C01) and should have been fully migrated in C09. If C09 missed some values, those are the bugs. The agent must find the seed file and check ALL money values.

**Memory prediction**: Medium value. Knowing the seed script path and what changed in C09 helps.

### Scoring Focus

This is the HARDEST memory test in the benchmark.

- **Expected time difference**: Memory agent should fix all 5 bugs in ~1 iteration (knows all locations). No-memory agent may need 2-3 iterations searching for each bug's location.
- How many list endpoints were found and standardized?
- Was the largest-remainder algorithm implemented correctly?
- Was the reservation error handled with a 400 (not just suppressed)?
- Were ALL seed values fixed to cents?

### Expected Memory Interactions (Run B)

- **Recall**: All API route files and their response formats (HIGHEST VALUE)
- **Recall**: Payout calculation location from C05 (HIGH VALUE)
- **Recall**: Checkout/reservation validation from C07 (HIGH VALUE)
- **Recall**: SubOrder model from C03 (medium value)
- **Recall**: Seed script location and money values from C01/C09 (medium value)
- **Save**: "All list endpoints use { data: [...], total: N }" standard
- **Save**: "Largest-remainder method for integer splitting" pattern
