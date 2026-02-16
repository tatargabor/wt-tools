# Change 07: Stock Reservation Rethink

## Agent Input

### Overview

The product team has reconsidered the stock management approach from Change 02. Instead of decrementing stock when items are added to the cart, stock should only decrease at checkout. The cart uses a soft-reservation system with a 15-minute TTL to prevent overselling.

### Background

In C02, we implemented stock tracking where `Variant.stockQuantity` decreases when an item is added to the cart and increases when removed. The product team has decided this is too aggressive — it blocks stock for users who may never check out.

### Requirements

1. **Remove stock-on-add behavior**: `POST /api/cart/items` should NO LONGER decrement `Variant.stockQuantity`. The cart just records the intent to purchase.

2. **Cart reservation model**: Add a soft-reservation system:
   - `CartReservation`: `id`, `cartId`, `variantId`, `quantity`, `expiresAt`, `createdAt`
   - When an item is added to cart, create a reservation with `expiresAt = now + 15 minutes`
   - Reservation is advisory — it doesn't change actual stock numbers

3. **Stock decrement at checkout only**: Move stock decrementation to `POST /api/checkout/confirm`:
   - Before creating the order, check that `Variant.stockQuantity >= sum(cart item quantities)`
   - Decrement stock in a transaction with order creation
   - If stock is insufficient at checkout, return 400 with details about which items are unavailable

4. **Expired reservation handling**:
   - If a cart has items with expired reservations, the checkout should still attempt to process (stock-permitting)
   - Add a `GET /api/cart` enhancement: include a `reservationExpired: boolean` flag per item
   - Optionally: show a warning on the cart page for expired reservations

5. **Clean up old cart logic**:
   - Remove stock increment from `DELETE /api/cart/items/[id]` (no longer needed since stock isn't decremented)
   - Remove stock increment from `DELETE /api/cart` (clear cart)
   - Keep stock validation on add-to-cart as a WARNING (stock available?), not a hard block

### Acceptance Criteria

- [ ] Adding item to cart does NOT change `Variant.stockQuantity`
- [ ] CartReservation model exists with TTL field
- [ ] Checkout decrements stock in a transaction
- [ ] Insufficient stock at checkout returns 400 with item details
- [ ] Removing items from cart does NOT change stock
- [ ] Cart API shows reservation expiry status per item
- [ ] Previously passing tests for product CRUD (test-01.sh) still pass

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T7.1: Finding the stock decrement code**
The agent must find WHERE in the C02 implementation stock is decremented (likely in `POST /api/cart/items` route handler) and WHERE it's incremented (in `DELETE /api/cart/items/[id]`). Without memory of C02's implementation, the agent must search the codebase.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent knows the exact file path and function where stock operations happen. No-memory agent must grep through the codebase to find all stock mutation points.

**T7.2: Moving stock logic to checkout**
The checkout flow (from C05) already does several things in a transaction. The agent must add stock decrementation to this existing transaction, not create a separate one. This requires knowing the checkout's transaction structure.

**Memory prediction**: HIGH VALUE recall. The agent needs to recall C05's checkout transaction to know where to insert stock logic. Without memory, must re-read and understand the entire checkout flow.

**T7.3: Forgetting to remove old stock logic**
The agent might add the new checkout-time stock check but forget to remove the old cart-time stock decrement. If both exist, stock decreases TWICE — once on cart add (old) and once on checkout (new).

**Memory prediction**: Medium value. This is a comprehensiveness test — does the agent understand all the places where stock is mutated?

### Scoring Focus

- Did the agent find ALL stock mutation points (add, remove, clear)?
- Was the checkout transaction correctly extended?
- Did the agent create CartReservation model?
- Was old stock logic fully removed?

### Expected Memory Interactions (Run B)

- **Recall**: C02 cart implementation — where stock is decremented/incremented (HIGH VALUE)
- **Recall**: C05 checkout transaction structure — where to add stock logic (HIGH VALUE)
- **Recall**: Prisma transaction pattern from C02 (medium value)
- **Save**: Cart reservation pattern with TTL
- **Save**: "Stock only at checkout" architectural decision
