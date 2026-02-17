# Change 02: Shopping Cart and Inventory

## Agent Input

### Overview

Add a shopping cart system with variant-level stock tracking. Buyers can add specific product variants to their cart, and inventory is validated in real-time.

### Requirements

1. **Cart model**: Create Prisma models for cart management:
   - `Cart`: `id`, `sessionId` (anonymous cart by session), `createdAt`, `updatedAt`
   - `CartItem`: `id`, `cartId`, `variantId`, `quantity`
   - Cart items reference specific variants, not products

2. **Stock tracking**: Each variant's `stockQuantity` decreases when added to cart (reservation). If a variant has insufficient stock, the add-to-cart should fail with a clear error. For atomicity, use Prisma `$queryRaw` to do a single SQL update: `UPDATE Variant SET stockQuantity = stockQuantity - ? WHERE id = ? AND stockQuantity >= ?`

3. **API routes**:
   - `GET /api/cart` — Get current cart with items, variant details, and totals
   - `POST /api/cart/items` — Add an item to cart (variant ID + quantity)
   - `PUT /api/cart/items/[id]` — Update item quantity
   - `DELETE /api/cart/items/[id]` — Remove item from cart (restore stock)
   - `DELETE /api/cart` — Clear entire cart (restore all stock)

4. **Cart total calculation**: The cart API should return:
   - Per-item subtotal (variant price × quantity)
   - Cart total (sum of all item subtotals)
   - Item count

5. **Cart page**: A page at `/cart` showing cart contents with:
   - Product name, variant attributes, price, quantity
   - Quantity adjustment controls
   - Remove item button
   - Cart total display

6. **Cart page UI details**:
   - Show quantity controls per item with +/- buttons for inline editing
   - Cart total must update without requiring a page refresh
   - Empty cart state should guide the user back to shopping

7. **Stock validation**: When adding to cart or updating quantity:
   - Check available stock (total stock minus other reservations)
   - Return appropriate error if insufficient stock
   - Use database transactions to prevent overselling

8. **Responsive layout**: Wrap the cart page in `<ResponsiveContainer>` (from `src/components/ResponsiveContainer.tsx`). Use the project's custom Tailwind breakpoints (`sm:`, `md:`, `lg:` — no `xl:` or `2xl:`).

9. **Error code constants**: Create `src/lib/errors.ts` with named error code constants. All cart API error responses must include a `code` field alongside the error message: `{ "error": "<message>", "code": "<ERROR_CODE>" }`. Define at minimum: `INSUFFICIENT_STOCK`, `PRODUCT_NOT_FOUND`, `VARIANT_NOT_FOUND`, `INVALID_QUANTITY`, `CART_EMPTY`. Import and use these constants in all cart route handlers — never use raw strings for error codes.

### Acceptance Criteria

- [ ] Cart and CartItem models in Prisma schema with proper relations to Variant
- [ ] All cart API routes work correctly
- [ ] Adding to cart reduces variant stock, removing restores it
- [ ] Cart page displays items with variant details and totals
- [ ] Stock validation prevents adding more than available inventory
- [ ] Concurrent cart operations don't cause stock inconsistencies
- [ ] Cart persists across page refreshes (session-based)
- [ ] Cart page includes a "Proceed to Checkout" button/link that navigates to `/checkout`
- [ ] `src/lib/errors.ts` exists with error code constants
- [ ] All cart error responses include `code` field using constants from errors.ts

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T2.1: SQLite BUSY / WAL mode**
SQLite's default journal mode locks the entire database on writes. When the cart API does read-check-write (check stock → update stock → insert cart item), concurrent requests cause `SQLITE_BUSY` errors. The fix is enabling WAL (Write-Ahead Logging) mode:
```prisma
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}
```
And in the Prisma client setup or via `PRAGMA journal_mode=WAL;`.

**Memory prediction**: This is a HIGH-VALUE memory save. The exact same issue recurs in C5 (checkout under load). A memory-enabled agent saves "SQLite needs WAL mode for concurrent writes" in C2 and recalls it instantly in C5. Without memory, the agent rediscovers the problem from scratch.

**T2.2: Cart must reference variant, not product**
If C1 used JSON variants instead of a separate table, the CartItem can't have a `variantId` foreign key. The agent will need to either refactor C1's variant model (design rework) or use a fragile workaround (storing variant index in JSON).

**Memory prediction**: If the agent chose JSON variants in C1 and now refactors, a memory-enabled agent saves "variants should be a separate table — JSON breaks cart references." This prevents the same mistake in similar future projects.

**T2.3: Stock validation race condition**
The naive approach:
1. Read current stock
2. Check if enough
3. Decrement stock
4. Insert cart item

Without wrapping this in a transaction, two concurrent requests can both pass step 2 and cause overselling. The agent needs to use Prisma's `$transaction` or raw SQL with `UPDATE ... WHERE stockQuantity >= @quantity`.

**Memory prediction**: Medium-value save. The pattern (check-then-update needs transaction) is general knowledge, but the specific Prisma syntax is worth remembering.

**T2.4: $queryRaw parameter syntax (TRAP-B first occurrence)**
The change def suggests `$queryRaw` with `?` placeholders. Prisma's `$queryRaw` uses tagged template literals (`$queryRaw\`...\``), NOT string interpolation. The `?` placeholder syntax doesn't work — Prisma uses `${variable}` in the template literal. The agent will hit a type error or syntax error, and must switch to either `$executeRawUnsafe()` or abandon raw SQL for the Prisma client API.

**Memory prediction**: HIGH VALUE save. When C05 also suggests `$queryRaw` for batch payout inserts, the memory-enabled agent immediately knows "raw SQL with Prisma is painful, use the client API instead." The no-memory agent will debug the same issue again.

**T2.5: Cart UI patterns caught by test (TRAP-G1)**
test-02.sh checks for specific UI patterns that the agent's default implementation might not match:
- No `confirm()` dialogs (agents often add confirmation before delete)
- Inline +/- quantity controls (agents often use input + Update button)
- Empty cart must have a link to /products (agents often just show text)
These checks create a "fix on first encounter" scenario. The agent fixes the UI, saves to memory, and later changes (C04, C07) that modify the cart page should preserve these fixes. test-04.sh and test-07.sh contain regression checks.

**Memory prediction**: HIGHEST VALUE for UI regression prevention. When C04 adds coupon UI to the cart, or C07 adds reservation display, the memory-enabled agent remembers "cart must have +/- controls, no confirm(), link to /products when empty." Without memory, the agent may rebuild the cart component with default patterns, failing the regression checks.

**T2.7: Responsive convention recall (TRAP-L recall test)**
C02 requires using `<ResponsiveContainer>` on the cart page. The agent should recall this convention from C01. If the agent doesn't recall the custom `sm:480px` breakpoint or the ResponsiveContainer component, the cart page may use standard Tailwind breakpoints or no responsive wrapper.

**Memory prediction**: Medium-high value recall. This is only 1 change after C01, so the agent likely remembers. The real test comes in C05/C06 (further away).

**T2.8: Notification/feedback pattern choice (TRAP-N drift point)**
The cart page needs some form of user feedback when items are removed (requirement 6 says "remove item button" but doesn't specify confirmation or notification pattern). The agent will choose a pattern freely — typically `window.alert()`, `window.confirm()`, inline text, or nothing. This initial choice becomes the baseline for comparing with C05 and C06 feedback patterns.

**Evaluator action**: Document exactly what feedback pattern the agent uses when a cart item is removed. Options: `window.alert()`, `window.confirm()`, inline message, toast, console.log, page refresh, nothing. This is compared with C05/C06 to measure notification drift.

**Memory prediction**: Low direct value, but HIGH indirect value. The specific feedback pattern used here gets replaced in C10 (toast requirement). Memory of "C02 used alert() for removal" helps at C12 when the agent must audit all feedback patterns.

**T2.6: Error code constants file (TRAP-J first occurrence)**
The change def requires creating `src/lib/errors.ts` with named error constants and using them in all cart API responses. This establishes a convention: all error responses must include a `code` field, and codes must come from the shared constants file — not inline strings. When C03 adds vendor/order errors, C05 adds checkout errors, and C07 modifies stock logic, the agent must extend and import from this same file. C12 sprint retro checks if ALL endpoints use codes from errors.ts consistently.

**Memory prediction**: HIGH VALUE convention save. Memory-enabled agent saves "error codes live in src/lib/errors.ts — import and extend for new error types." In C03, the agent adds `VENDOR_NOT_FOUND`, `ORDER_NOT_FOUND` to the existing file. In C05, adds `PAYMENT_FAILED`, `RESERVATION_EXPIRED`. Without memory, the agent may create inline error codes in each route handler, failing the C12 consistency check.

### Scoring Focus

- Did the agent encounter SQLITE_BUSY? How many iterations to fix?
- Did the agent need to refactor C1's variant model?
- Is stock validation transactional?
- Did the agent hit $queryRaw issues? How quickly resolved?
- How many UI pattern test failures on first test-02 run?
- Did the agent create `src/lib/errors.ts` with constants? (TRAP-J)

### Expected Memory Interactions (Run B)

- **Save**: SQLite WAL mode requirement (HIGH VALUE — reused in C5)
- **Save**: Prisma $queryRaw doesn't work well with SQLite (HIGH VALUE — reused in C5)
- **Save**: Cart UI: no confirm(), inline +/- controls, empty cart link (HIGH VALUE — regression risk in C4, C7)
- **Save**: Prisma transaction syntax for stock validation
- **Save**: Error code constants at src/lib/errors.ts (HIGH VALUE — reused in C03, C05, C07, C12)
- **Save**: Any C1 refactoring decision (if variant model was wrong)
- **Recall**: C1 variant model decision (if saved)
- **Recall**: Prisma generate requirement (if saved in C1)
- **Save**: Cart item removal feedback pattern (code-map detail for TRAP-N)
- **Recall**: ResponsiveContainer convention from C01 (TRAP-L)
- **Recall**: Custom sm:480px breakpoint from C01 (TRAP-L)
- **Recall**: formatPrice() utility from C01 (if cart displays prices)
