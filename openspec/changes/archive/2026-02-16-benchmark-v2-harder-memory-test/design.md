## Context

The shodh-memory benchmark v1 measures whether persistent memory helps autonomous agents build a multi-change project (CraftBazaar). After running v1, we found:

- Memory-enabled agent (Run B) was NOT faster — actually ~1 iteration behind baseline (Run A)
- Token usage was nearly identical (~2M/iteration for apply, ~200-400K for ff)
- Memory hooks added overhead (recall on every prompt, verbose saves) without proportional benefit
- The 6 changes are sequential but each is self-contained enough that memory of prior changes rarely matters
- The "traps" are organic (IF the agent hits an error) rather than forced (MUST deal with a contradiction)

The benchmark needs to test what memory is actually good at: **remembering decisions and mistakes across context boundaries when requirements change, designs are corrected, and bugs recur**.

## Goals / Non-Goals

**Goals:**
- Add forced requirement reversals that REQUIRE remembering what was built
- Add "not what I meant" design corrections that test whether the agent repeats mistakes
- Add a sprint retro that requires cross-cutting knowledge of the entire codebase
- Create per-change acceptance tests that objectively measure correctness DURING the run
- Reduce memory hook overhead so it doesn't penalize Run B
- Make the benchmark hard enough that the difference between A and B is measurable

**Non-Goals:**
- Changing the CraftBazaar domain or tech stack
- Modifying the existing 6 change PROPOSALS (they stay as-is; evaluator notes may be updated)
- Building a general-purpose benchmark framework

## Decisions

### D1: Three revision changes (07-09) — "Stakeholder changed their mind"

**Choice**: Add changes 07-09 that explicitly reverse or modify decisions from earlier changes.

**The three revisions:**

1. **Change 07: "Stock reservation rethink"** (revises C02)
   - C02 says: stock decreases when item is added to cart
   - C07 says: "Product team decided stock should only decrease at checkout. Cart uses soft-reserve with 15-min TTL."
   - **Acceptance test**: `test-07.sh` curls POST /api/cart/items, then checks Variant.stockQuantity is UNCHANGED. Curls POST /api/checkout/confirm, then checks stock DID decrease.
   - Memory value: agent knows WHERE the stock decrement code is without searching

2. **Change 08: "Product images need their own table"** (revises C01)
   - C01 stores images as JSON string in Product model
   - C08 says: "Migrate to separate Image table with alt-text and sort order."
   - **Acceptance test**: `test-08.sh` runs `npx prisma validate`, checks Image table exists, checks Product has no `images` column, hits GET /api/products/[id] and verifies images array has `{url, altText, sortOrder}` shape.
   - Memory value: agent knows the current data format to migrate FROM

3. **Change 09: "Switch to integer cents everywhere"** (revises C04+C05)
   - C04/C05 use Decimal/Float for money
   - C09 says: "Rounding errors. Switch ALL money to integer cents."
   - **Acceptance test**: `test-09.sh` greps Prisma schema for known money fields, asserts all are `Int`. Creates a test order and verifies `sum(payout_net) + sum(platform_fee) == payment_amount` (exact equality, no rounding).
   - Memory value: agent knows the COMPLETE list of money fields without exhaustive search

### D2: Two feedback changes (10-11) — "That's not what I meant"

**Choice**: Add changes that simulate stakeholder design corrections with specific UI/behavioral requirements, plus tests that catch if the agent gets it wrong. These are designed so the agent might fail the test MULTIPLE TIMES if it doesn't remember the exact correction.

4. **Change 10: "Cart page UX correction"** (corrects C02 UI)
   - Proposal says: "The cart page you built in C02 has problems. The design team reviewed and wants these specific changes:
     - Item quantities must be editable INLINE (not via a modal or separate page)
     - Removing an item must show a confirmation toast, not a confirm dialog
     - Cart total must update in real-time as quantities change (no 'Update cart' button)
     - Empty cart must show a CTA button linking to /products, not just text"
   - **Acceptance test**: `test-10.sh` uses a simple puppeteer/playwright script (or curl + grep for SSR) to verify:
     - No `confirm()` calls in cart page JS
     - No 'Update cart' submit button in cart page HTML
     - A link to /products exists when cart is empty
   - **Why this is hard without memory**: The agent might fix one thing but reintroduce the "Update cart" button pattern (because that's the typical cart pattern). Without remembering "they specifically said NO update button, real-time updates only," the agent defaults to common patterns.
   - **Evaluator trap**: Run the test AFTER implementation. If it fails, the agent gets a follow-up iteration with "test-10.sh failed: found 'Update cart' button." Memory agent recalls the specific requirements. No-memory agent might fix the button but break the inline editing.

5. **Change 11: "Vendor dashboard redesign"** (corrects C06 UI)
   - Proposal says: "The vendor dashboard from C06 groups sub-orders by status (pending/active/completed tabs). The business team wants a SINGLE flat list sorted by date, with status as a colored badge. No tabs. Also:
     - Each row must show buyer email (not just buyer session ID)
     - Action buttons (confirm/ship/deliver/cancel) must be in a dropdown menu, not individual buttons
     - The list must support pagination (10 items per page)"
   - **Acceptance test**: `test-11.sh` checks:
     - No tab/panel component in vendor dashboard HTML
     - Presence of pagination (page buttons or next/prev)
     - Status rendered as badge (CSS class contains 'badge')
   - **Why this needs memory**: The agent built the tabbed layout in C06. Without memory, it might rebuild tabs and just add badges to each tab, failing the "no tabs" requirement. The correction is counter to the common pattern.

### D3: Sprint retro change (12) — "Fix all these bugs in one go"

**Choice**: A single change that lists 5 bugs from different earlier changes. This is the hardest memory test because the agent needs cross-cutting knowledge.

6. **Change 12: "Sprint retrospective fixes"**
   - Proposal says: "Sprint retro identified these issues. Fix them all:"
     1. **API inconsistency** (from C01+C03): `GET /api/products` returns `{ data: [...] }` but `GET /api/vendors` returns `{ vendors: [...] }`. Standardize ALL list endpoints to `{ data: [...], total: N }` format.
     2. **Payout rounding** (from C05+C09): After switching to integer cents, the payout split for 3-vendor orders has off-by-one errors. The platform fee cents don't add up. Fix: use largest-remainder method for splitting.
     3. **Expired reservation checkout** (from C07): If a user starts checkout with an expired cart reservation, the API returns 500 instead of a helpful 400 error with message "Cart reservation expired. Please re-add items."
     4. **Missing database index** (from C03): The `SubOrder` table is queried by `vendorId` for the vendor dashboard but has no index. Add `@@index([vendorId])`.
     5. **Seed data inconsistency** (from C01+C04): The seed script creates products with prices in dollars but coupons with values in cents (after C09 migration). Fix seed to use cents everywhere.
   - **Acceptance test**: `test-12.sh` verifies all 5:
     - Curls 3 list endpoints, all return `{ data: [...], total: N }`
     - Creates 3-vendor order, checks `sum(payouts) == payment_amount`
     - Attempts checkout with expired reservation, gets 400 not 500
     - Checks Prisma schema for `@@index` on SubOrder.vendorId
     - Runs seed script, checks no mixed dollar/cent values
   - **Why this needs memory**: Each fix touches a different part of the codebase built in a different iteration. Memory agent: knows exactly where each endpoint/model/function lives. No-memory agent: must search for each, spending more tokens and time.

### D4: Per-change acceptance tests

**Choice**: Each change (including 01-06) gets a test script in `benchmark/tests/test-NN.sh` that the agent is told to run and make pass. The CLAUDE.md instructs: "After implementing each change, run `bash tests/test-NN.sh` and fix any failures."

**Test design principles:**
- Tests use `curl` against the running dev server (localhost:3000 or 3001)
- Tests check API response shapes, status codes, and basic data integrity
- Tests are intentionally specific enough to catch common mistakes but not so brittle they break on style differences
- Failed tests produce a clear message: "FAIL: expected X, got Y"
- Tests are idempotent — can be run multiple times

**Why this creates memory signal:**
- When a test fails, the agent debugs and fixes. That fix is a LEARNING.
- If the same pattern causes a failure in a later test, memory-enabled agent recalls the fix.
- Without memory, the agent re-debugs from scratch.

### D5: Targeted recall hook (change-boundary only)

**Choice**: Modify `wt-hook-memory-recall` to only fire when starting a NEW change (detected via `detect_next_change_action` returning a different change than last time), not on every prompt. For revision/feedback changes, also recall the original change being revised.

### D6: Automated evaluator scripts

**Choice**: Shell scripts in `benchmark/evaluator/` for post-benchmark scoring. Same as before: eval-schema.sh, eval-api.sh, eval-behavior.sh, eval-coherence.sh, collect-results.sh, compare.sh.

## Risks / Trade-offs

1. **12 changes = longer benchmark**: 12 changes × 2 iterations (ff+apply) = 24 iterations minimum. Set --max 30.
2. **Acceptance tests need running server**: Tests assume `npm run dev` is running. The CLAUDE.md must instruct the agent to start the dev server before running tests. This adds complexity.
3. **Puppeteer/Playwright tests are heavy**: For UI checks (C10, C11), simple grep-based HTML checks are more reliable than browser automation. Use HTML inspection (curl + grep) rather than full browser tests.
4. **Agent might ignore test failures**: The prompt must strongly emphasize "DO NOT mark task complete until tests pass."
5. **More changes might dilute the per-change memory signal**: Counter: the revision changes (07-09) and sprint retro (12) are specifically designed to AMPLIFY memory signal, not dilute it.
