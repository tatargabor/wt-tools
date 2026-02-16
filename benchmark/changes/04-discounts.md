# Change 04: Discount and Coupon Engine

## Agent Input

### Overview

Add a coupon and discount system to CraftBazaar. Vendors can create promotions for their products, and buyers can apply coupons at checkout.

### Requirements

1. **Coupon model**: Add to Prisma schema:
   - `Coupon`: `id`, `code` (unique string), `type` (percentage or fixed), `value` (Float — discount amount in dollars), `vendorId` (nullable — null means global), `minOrderValue` (Float, nullable), `maxUses` (nullable), `currentUses`, `startsAt`, `expiresAt`, `isActive`, `createdAt`
   - Use Prisma `Float` type for all money fields — SQLite doesn't support Decimal natively

2. **Coupon CRUD API** (vendor-facing):
   - `POST /api/vendors/[id]/coupons` — Create a vendor-specific coupon
   - `GET /api/vendors/[id]/coupons` — List vendor's coupons
   - `PUT /api/coupons/[id]` — Update a coupon
   - `DELETE /api/coupons/[id]` — Deactivate a coupon

3. **Coupon application** (buyer-facing):
   - `POST /api/cart/coupon` — Apply a coupon code to cart
   - `DELETE /api/cart/coupon` — Remove applied coupon
   - Validate: code exists, is active, not expired, not maxed out, meets minimum order value

4. **Discount calculation**:
   - **Vendor-specific coupon**: Discount applies only to items from that vendor
   - **Global coupon**: Discount applies to the entire cart
   - **Percentage discount**: Apply percentage to applicable items' subtotal
   - **Fixed discount**: Subtract fixed amount from applicable items' subtotal (don't go below 0)
   - Cart total and per-sub-order totals must reflect applied discounts

5. **Cart API updates**:
   - `GET /api/cart` should now include: applied coupon details, discount amount, pre-discount total, post-discount total
   - Per-vendor subtotals should reflect vendor-specific discounts

6. **UI updates**:
   - Cart page: coupon input field, applied coupon display, discount breakdown
   - Vendor dashboard: coupon management section

7. **Stock-aware validation**: When applying a coupon, also validate that all cart items are still in stock (`Variant.stockQuantity >= cartItem.quantity`). If any item has insufficient stock, reject the coupon with an error — the user should fix their cart before applying discounts.

8. **Seed data**: Add 2-3 sample coupons (one global percentage, one vendor-specific fixed, one expired)

### Acceptance Criteria

- [ ] Coupon model with all required fields in Prisma schema
- [ ] Vendor coupon CRUD API works
- [ ] Coupon validation (expiry, max uses, min order, active status)
- [ ] Percentage discount calculates correctly on applicable items
- [ ] Fixed discount calculates correctly (doesn't go negative)
- [ ] Vendor-specific coupon only discounts that vendor's items
- [ ] Global coupon discounts entire cart
- [ ] Cart API returns discount breakdown
- [ ] Cart page shows coupon input and discount details

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T4.1: Discount scope confusion — variant vs product level**
Discounts must be calculated at the variant level (because that's the unit of sale with its own price). If the agent applies discount at the product level, the math is wrong when variants have different prices. This tests whether the agent remembers that variants are the unit of sale (from C1/C2).

**Memory prediction**: HIGH VALUE recall opportunity. A memory-enabled agent should recall "variants are the unit of sale" from C1/C2 and apply discounts at variant level naturally. Without memory, the agent might initially compute discounts at product level and have to debug incorrect totals.

**T4.2: Coupon + multi-vendor interaction**
A global coupon applied to a multi-vendor cart raises the question: how to split the discount across sub-orders? Options:
- Proportional: each sub-order gets discount × (sub-order total / cart total)
- First-vendor-absorbs: fragile, unfair
- No split: discount applied at order level only

This interacts with C3's order architecture. With nested orders (parent + sub-orders), the discount can attach to the parent order. With flat orders, there's no parent to attach to.

**Memory prediction**: HIGH VALUE recall opportunity. Recalling C3's order architecture decision is critical. If the agent remembers "we used parent Order → SubOrder," they know discounts attach to the parent. Without memory, they might struggle with where to apply the discount.

**T4.3: Prisma Decimal precision in SQLite**
Prisma's `Decimal` type maps to `REAL` in SQLite, which is a floating-point number. Percentage calculations can produce floating-point rounding errors (e.g., 10% of $29.99 = $2.999). The agent should use proper rounding (Math.round to 2 decimal places) or integer cents.

**Memory prediction**: Medium-value save. The pattern "use integer cents or explicit rounding for money in SQLite" is worth saving for C5.

**T4.4: Stock validation in coupon apply — hidden cross-dependency (TRAP-F)**
The change def adds requirement 7: "validate stock when applying coupon." This creates a stock check OUTSIDE the cart system — in the coupon validation code. When C07 (stock-rethink) changes stock logic from cart-time to checkout-time, the agent must ALSO update this coupon stock check. Without memory of this hidden dependency, the agent will miss it and the coupon apply will still use the OLD stock checking approach.

**Memory prediction**: HIGHEST VALUE cross-dependency save. Memory-enabled agent saves "coupon validation also checks stock — update if stock logic changes." When C07 comes, the agent recalls this and updates both cart AND coupon code. Without memory, the agent only fixes the cart stock logic and the coupon validation silently breaks.

**T4.5: Float money type (TRAP-D first occurrence)**
The change def specifies `Float` for money fields. This works but produces floating-point precision issues during percentage discount calculations (10% of $29.99 = $2.9990000000000001). The agent must add rounding (typically `Math.round(amount * 100) / 100`). This same issue will recur in C05 (payout calculations) and gets properly fixed in C09 (integer cents migration).

**Memory prediction**: HIGH VALUE save. The agent saves "Float money has precision issues, need explicit rounding." In C05, this knowledge prevents debugging the same issue.

### Scoring Focus

- Did the agent apply discounts at variant level or product level?
- Did the agent correctly handle vendor-specific vs global coupons with multi-vendor carts?
- Did the agent recall the order architecture from C3?
- Any floating-point precision issues? Did the agent add rounding?
- Did the agent implement the stock-aware coupon validation?

### Expected Memory Interactions (Run B)

- **Recall**: Variant-as-unit-of-sale (from C1/C2) — guides discount scope
- **Recall**: Order architecture (from C3) — guides where to attach discounts
- **Recall**: Prisma migration patterns (from C3) — adding coupon FK
- **Recall**: $queryRaw issues (from C2) — if using raw SQL
- **Save**: Discount calculation approach (proportional split)
- **Save**: Float money needs explicit rounding (HIGH VALUE — reused in C5)
- **Save**: Coupon validation also checks stock (HIGHEST VALUE — must update in C7)
- **Save**: Coupon-to-order attachment pattern
