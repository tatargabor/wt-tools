# Change 09: Integer Cents for All Money Fields

## Agent Input

### Overview

All monetary values in CraftBazaar must switch from Decimal/Float representation to integer cents. This eliminates floating-point rounding errors that have been causing subtle bugs in discount calculations and payout splits.

### Background

Changes C01, C03, C04, and C05 introduced money fields using Decimal or Float types (e.g., `basePrice Decimal`, `price Float`, `value Decimal`). Floating-point arithmetic causes rounding errors — for example, splitting a $10.00 discount across 3 vendors gives $3.3333... per vendor, which doesn't sum back to $10.00.

### Requirements

1. **Schema migration**: Change ALL money-related fields in `schema.prisma` to `Int` type. Fields to find and update include (but may not be limited to):
   - Product: `basePrice`
   - Variant: `price`
   - Coupon: `value`, `minOrderValue`
   - Order: `totalAmount`
   - SubOrder: `subtotal`
   - OrderItem: `unitPrice`
   - Payment: `amount`
   - VendorPayout: `grossAmount`, `platformFee`, `netAmount`
   - CartItem or Cart: any total/subtotal fields
   - All values stored in CENTS (e.g., $29.99 → 2999)

2. **API format**: All API responses that include money values must return integers (cents). Update:
   - Product/variant endpoints (prices in cents)
   - Cart endpoints (totals in cents)
   - Order endpoints (amounts in cents)
   - Checkout endpoints (payment amounts in cents)

3. **Calculation updates**: Review and update all arithmetic:
   - Percentage discounts: `Math.round(subtotal * percentage / 100)` (round to nearest cent)
   - Platform fee: `Math.round(vendorSubtotal * 0.10)` (10% rounded)
   - Tax: `Math.round(subtotal * 0.10)` (10% rounded)
   - Payout net: `grossAmount - platformFee` (exact subtraction, no rounding)

4. **Display formatting**: Frontend pages that show prices must format cents as dollars:
   - `2999` → `$29.99`
   - Use a utility function: `formatPrice(cents: number): string`

5. **Seed data update**: Update the seed script to use cent values:
   - `basePrice: 29.99` → `basePrice: 2999`
   - All coupon values, product prices, etc.

### Acceptance Criteria

- [ ] All money fields in schema.prisma are `Int` type
- [ ] `npx prisma migrate dev` runs successfully
- [ ] API responses return money as integer cents
- [ ] Discount calculations use integer arithmetic (no floating-point)
- [ ] Payout split is exact: `sum(netAmount) + sum(platformFee) == payment amount`
- [ ] Seed data uses cent values
- [ ] Frontend displays formatted dollar amounts

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T9.1: Finding ALL money fields**
The agent must find every field in the Prisma schema that represents money. Missing even one field creates a mix of dollars and cents in the database, causing calculation errors. The complete list spans C01 (Product.basePrice, Variant.price), C04 (Coupon.value, Coupon.minOrderValue), C05 (Order.totalAmount, SubOrder.subtotal, OrderItem.unitPrice, Payment.amount, VendorPayout fields).

**Memory prediction**: HIGHEST VALUE recall. Memory-enabled agent knows the complete list of money fields across all models because it built them. No-memory agent must scan the entire schema and may miss fields in models from early changes.

**T9.2: Updating all calculation sites**
Money arithmetic happens in: cart total calculation, discount application, tax calculation, payout splitting, Stripe payment intent creation. Each must be reviewed and updated for integer arithmetic. Missing one site creates subtle bugs.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent knows where discount, tax, and payout calculations happen from C04 and C05.

**T9.3: Seed data consistency**
If the seed script is updated to cents but some values are left in dollars (or vice versa), test data is corrupted. This is checked by test-12.sh later (sprint retro).

**Memory prediction**: Medium value. The agent should recall the seed script's location and structure.

**T9.4: Stripe amount format**
Stripe already expects amounts in cents for `payment_intent.create()`. If the agent was previously converting dollars to cents for Stripe, that conversion must be removed (since values are already in cents). Getting this wrong doubles or hundredths the payment amount.

**Memory prediction**: HIGH VALUE recall. Must know the current Stripe integration code to update correctly.

### Scoring Focus

- Were ALL money fields found and migrated?
- Were ALL calculation sites updated?
- Is payout math exact (integer arithmetic)?
- Was Stripe integration updated correctly?
- Is seed data consistent (all cents)?

### Expected Memory Interactions (Run B)

- **Recall**: All money fields across models from C01, C04, C05 (HIGHEST VALUE)
- **Recall**: Where discount/tax/payout calculations happen from C04, C05 (HIGH VALUE)
- **Recall**: Stripe payment intent creation from C05 (HIGH VALUE)
- **Recall**: Seed script location and structure from C01 (medium value)
- **Save**: "All money in integer cents" decision
- **Save**: Complete list of money fields migrated
- **Save**: Calculation patterns for integer arithmetic
