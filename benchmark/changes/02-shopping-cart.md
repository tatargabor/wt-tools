# Change 02: Shopping Cart and Inventory

## Agent Input

### Overview

Add a shopping cart system with variant-level stock tracking. Buyers can add specific product variants to their cart, and inventory is validated in real-time.

### Requirements

1. **Cart model**: Create Prisma models for cart management:
   - `Cart`: `id`, `sessionId` (anonymous cart by session), `createdAt`, `updatedAt`
   - `CartItem`: `id`, `cartId`, `variantId`, `quantity`
   - Cart items reference specific variants, not products

2. **Stock tracking**: Each variant's `stockQuantity` decreases when added to cart (reservation). If a variant has insufficient stock, the add-to-cart should fail with a clear error.

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

6. **Stock validation**: When adding to cart or updating quantity:
   - Check available stock (total stock minus other reservations)
   - Return appropriate error if insufficient stock
   - Use database transactions to prevent overselling

### Acceptance Criteria

- [ ] Cart and CartItem models in Prisma schema with proper relations to Variant
- [ ] All cart API routes work correctly
- [ ] Adding to cart reduces variant stock, removing restores it
- [ ] Cart page displays items with variant details and totals
- [ ] Stock validation prevents adding more than available inventory
- [ ] Concurrent cart operations don't cause stock inconsistencies
- [ ] Cart persists across page refreshes (session-based)

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

### Scoring Focus

- Did the agent encounter SQLITE_BUSY? How many iterations to fix?
- Did the agent need to refactor C1's variant model?
- Is stock validation transactional?

### Expected Memory Interactions (Run B)

- **Save**: SQLite WAL mode requirement (HIGH VALUE — reused in C5)
- **Save**: Prisma transaction syntax for stock validation
- **Save**: Any C1 refactoring decision (if variant model was wrong)
- **Recall**: C1 variant model decision (if saved)
- **Recall**: Prisma generate requirement (if saved in C1)
