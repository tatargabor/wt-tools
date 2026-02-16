# Change 03: Multi-Vendor Order Splitting

## Agent Input

### Overview

Transform CraftBazaar from a single-seller store into a multi-vendor marketplace. Add vendors, associate products with vendors, and implement order creation that splits a cart into per-vendor sub-orders.

### Requirements

1. **Vendor model**: Add to Prisma schema:
   - `Vendor`: `id`, `name`, `email`, `description`, `createdAt`
   - Each product belongs to exactly one vendor (add `vendorId` to Product)

2. **Vendor CRUD API**:
   - `GET /api/vendors` — List all vendors
   - `GET /api/vendors/[id]` — Get vendor with their products
   - `POST /api/vendors` — Create a vendor
   - `PUT /api/vendors/[id]` — Update a vendor

3. **Product-vendor association**:
   - Update product creation to require a `vendorId`
   - Update product listing to show vendor name
   - Add vendor profile page at `/vendors/[id]` showing their products

4. **Error format**: API error responses should include an error code for programmatic handling. Use the format `{ "error": "<message>", "code": "<ERROR_CODE>" }` (e.g., `{ "error": "Insufficient stock", "code": "ORDER_STOCK_INSUFFICIENT" }`). Use uppercase snake_case for error codes. Add new error code constants to the existing `src/lib/errors.ts` file: `VENDOR_NOT_FOUND`, `ORDER_NOT_FOUND`, `ORDER_CREATION_FAILED`, `CART_EMPTY`.

4b. **API list format**: All list endpoints in this change (vendors, orders) must return the paginated envelope format: `{ data: [...], total: N, page: N, limit: N }` with `?page=1&limit=20` query params (default: page 1, limit 20). This must be consistent with the product listing endpoint from C01.

5. **Order creation from cart**:
   - `POST /api/orders` — Create an order from the current cart
   - The order process must:
     a. Validate all cart items are still in stock
     b. Create an order record
     c. Split cart items by vendor into per-vendor sub-orders
     d. Each sub-order has its own items, subtotal, and status
     e. Clear the cart after successful order creation

6. **Order models**:
   - `Order`: `id`, `buyerSessionId`, `totalAmount`, `status`, `createdAt`
   - `SubOrder`: `id`, `orderId`, `vendorId`, `subtotal`, `status`, `createdAt`
   - `OrderItem`: `id`, `subOrderId`, `variantId`, `quantity`, `unitPrice`

7. **Order viewing**:
   - `GET /api/orders` — List buyer's orders
   - `GET /api/orders/[id]` — Get order details with sub-orders and items
   - Orders page at `/orders` showing order history
   - Order detail page at `/orders/[id]` showing sub-orders grouped by vendor

8. **Seed data update**: Add 3-4 vendors and reassign existing products to them

### Acceptance Criteria

- [ ] Vendor model with CRUD API
- [ ] Products associated with vendors (migration adds vendorId)
- [ ] Order creation splits cart items by vendor into sub-orders
- [ ] Each sub-order tracks its own items and subtotal
- [ ] Order API returns orders with nested sub-orders and items
- [ ] Order pages display vendor-grouped sub-orders
- [ ] Prisma migration runs cleanly on existing data
- [ ] Seed data includes vendors
- [ ] New error codes added to `src/lib/errors.ts` and used in vendor/order routes
- [ ] Vendor and order list endpoints return `{ data, total, page, limit }` format

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T3.1: Order architecture — flat vs nested (THE pivotal decision)**
This is the single most impactful design decision in the entire benchmark. Two approaches:

- **Nested (correct)**: Parent `Order` → child `SubOrder`s (one per vendor) → `OrderItem`s. This cleanly supports C6's per-vendor status tracking (each sub-order has its own state machine).
- **Flat (problematic)**: Single `Order` table with `vendorId` per order (one order per vendor, no parent grouping). This seems simpler but:
  - C4: Discounts that span multiple vendors have no parent order to attach to
  - C5: Payment is one Stripe charge per buyer, but flat orders can't group them
  - C6: Status workflow per vendor needs per-vendor records — flat orders have this, but there's no way to show "your order" (spanning vendors) to the buyer

**Memory prediction**: HIGHEST-VALUE memory save in the entire benchmark. If the agent chooses nested orders, a memory-enabled agent saves the decision and rationale. In C4-C6, recalling "we used parent Order → SubOrder architecture" prevents confusion about where to attach discounts, payments, and status. If the agent chooses flat orders and has to rework in C6, the memory save becomes "flat orders don't work for multi-vendor — need parent+sub-order pattern."

**T3.2: Prisma migration on existing data**
Adding `vendorId` (required FK) to existing products requires either:
- A default vendor for existing products (migration step)
- Making vendorId optional initially and backfilling

Prisma will refuse to add a required column without a default if data exists. The agent must handle this migration carefully.

**Memory prediction**: Medium-value save. The pattern "adding required FK to existing data needs a default or two-step migration" is useful for C4 (adding orderId to discounts).

**T3.3: API redesign cascade**
With vendors added, the product API should include vendor info, the cart should show vendor per item, and existing pages need vendor attribution. The scope of changes is larger than it appears.

**Memory prediction**: Low-value save. This is more about task estimation than a reusable pattern.

**T3.4: Error code constants extension (TRAP-J test)**
C02 established `src/lib/errors.ts` with cart-related error codes. C03 must EXTEND this file with vendor/order codes — not create a separate error file or use inline strings. This tests whether the agent recalls the convention from C02.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent recalls "error codes are in src/lib/errors.ts" and extends the file. Without memory, the agent may create inline error codes or a separate file, breaking the consistency convention.

**T3.5: API pagination convention (TRAP-I test)**
C01 establishes the `{ data, total, page, limit }` envelope format. C03 adds new list endpoints (vendors, orders). The agent must apply the same pagination format — not return raw arrays or different envelope shapes. C12 sprint retro checks consistency across ALL list endpoints.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent recalls "all list endpoints use { data, total, page, limit }" from C01 and applies it naturally. Without memory, the agent may use different response shapes per endpoint.

### Scoring Focus

- **Critical**: What order architecture was chosen? (Flat vs nested — this determines C4-C6 difficulty)
- Did the migration handle existing data correctly?
- How many files needed updating? (Cascade awareness)
- Did the agent extend `src/lib/errors.ts` or create new error codes inline? (TRAP-J)
- Do vendor/order list endpoints use the same pagination format as products? (TRAP-I)

### Expected Memory Interactions (Run B)

- **Save**: Order architecture decision and rationale (HIGHEST VALUE)
- **Save**: Prisma migration strategy for adding required FK to existing data
- **Save**: API cascade scope observation
- **Recall**: Prisma generate requirement (from C1)
- **Recall**: Variant model design (from C1)
- **Recall**: SQLite WAL mode (from C2, if migration triggers concurrent access)
- **Recall**: Error codes convention in src/lib/errors.ts (from C2, TRAP-J)
- **Recall**: Pagination format { data, total, page, limit } (from C01, TRAP-I)
- **Recall**: Soft delete — vendor product queries should filter deletedAt (from C01, TRAP-K)
