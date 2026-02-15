# Change 05: Checkout and Payment

## Agent Input

### Overview

Add a complete checkout flow with Stripe payment integration (test mode). The checkout creates a payment intent, processes payment, calculates tax, and handles multi-vendor payout splitting.

### Requirements

1. **Stripe setup**:
   - Install `stripe` npm package
   - Configure Stripe test mode with environment variables
   - Create a Stripe payment intent for the cart total

2. **Checkout API**:
   - `POST /api/checkout` — Initiate checkout:
     a. Validate cart (items in stock, prices current)
     b. Apply any active coupon/discount
     c. Calculate tax (flat 10% for simplicity)
     d. Create Stripe payment intent for final amount
     e. Return client secret for frontend payment form
   - `POST /api/checkout/confirm` — After Stripe payment succeeds:
     a. Verify payment status with Stripe
     b. Create the order with sub-orders (per vendor)
     c. Record payment details
     d. Clear the cart
     e. Return order confirmation

3. **Payment model**: Add to Prisma schema:
   - `Payment`: `id`, `orderId`, `stripePaymentIntentId`, `amount`, `currency`, `status`, `createdAt`

4. **Payout split calculation**:
   - After payment, calculate how much each vendor is owed
   - Payout per vendor = vendor's sub-order total (after applicable discounts)
   - Platform fee: 10% of each vendor's sub-order total
   - Store payout info: `VendorPayout`: `id`, `orderId`, `vendorId`, `grossAmount`, `platformFee`, `netAmount`
   - Note: actual Stripe Connect payouts are out of scope — just calculate and store

5. **Tax calculation**:
   - Apply flat 10% tax to the post-discount cart total
   - Display tax as a separate line item
   - Tax applies to the full order, not per-vendor

6. **Checkout UI**:
   - Checkout page at `/checkout` with:
     - Order summary (items, quantities, prices)
     - Discount display (if coupon applied)
     - Tax line
     - Total amount
     - Stripe payment element (card input)
     - Pay button
   - Order confirmation page after successful payment

7. **Error handling**:
   - Payment failure → show error, don't create order
   - Stock changed during checkout → show error, return to cart
   - Stripe API errors → graceful error display

### Acceptance Criteria

- [ ] Stripe test mode integration works (using `STRIPE_SECRET_KEY` and `STRIPE_PUBLISHABLE_KEY`)
- [ ] Checkout validates cart and creates payment intent
- [ ] Payment confirmation creates order with sub-orders
- [ ] Tax calculated correctly (10% of post-discount total)
- [ ] Vendor payout split calculated and stored
- [ ] Platform fee (10%) deducted from each vendor's payout
- [ ] Checkout page renders with Stripe payment element
- [ ] Order confirmation page shows after successful payment
- [ ] Error cases handled gracefully (payment failure, stock issues)

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T5.1: Stripe environment setup — .env.local for Next.js**
Next.js requires environment variables to be in `.env.local` (not `.env`) for local development. Server-side vars need no prefix; client-side vars need `NEXT_PUBLIC_` prefix. The agent must:
- Put `STRIPE_SECRET_KEY` in `.env.local` (server-side only)
- Put `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` in `.env.local` (client-side)
- Use Stripe test keys (prefixed with `sk_test_` and `pk_test_`)

If the agent puts keys in `.env` instead of `.env.local`, Next.js won't pick them up (depending on the setup). This is a common Next.js gotcha.

**Memory prediction**: Medium-value save. "Next.js uses .env.local for local dev, NEXT_PUBLIC_ prefix for client-side env vars" is worth saving. It's general Next.js knowledge but agents often get it wrong.

**T5.2: Payout + discount interaction**
When a global coupon is applied and the order has items from multiple vendors, the payout calculation must account for the proportional discount per vendor. If the agent calculates payout from gross sub-order totals without discounts, the math doesn't add up (total payouts > payment amount).

**Memory prediction**: HIGH VALUE recall opportunity. If the agent saved the discount split approach from C4, they should recall how discounts are distributed across vendors and apply the same logic to payouts. Without memory, the agent might compute payouts from pre-discount amounts.

**T5.3: SQLite BUSY redux under checkout**
The checkout flow does multiple writes: update stock, create order, create sub-orders, create order items, create payment record, create payout records, clear cart. Without WAL mode (or if the agent didn't set it up in C2), this concentrated write burst hits SQLITE_BUSY again.

**Memory prediction**: HIGHEST VALUE recall opportunity for environment knowledge. If C2's "enable WAL mode for SQLite" was saved, the agent recalls it and either verifies it's already set or adds it. Without memory, the agent may debug the same SQLITE_BUSY error from scratch — potentially the clearest demonstration of memory value.

### Scoring Focus

- Did the agent set up .env.local correctly? (Common Next.js gotcha)
- Did the payout calculation account for discounts?
- Did SQLITE_BUSY recur? How quickly was it resolved?
- Is the checkout transactional (all-or-nothing)?

### Expected Memory Interactions (Run B)

- **Recall**: SQLite WAL mode (from C2) — avoids SQLITE_BUSY in checkout (HIGHEST VALUE)
- **Recall**: Discount split approach (from C4) — informs payout calculation
- **Recall**: Order architecture (from C3) — knows parent order + sub-orders structure
- **Recall**: Prisma Decimal/money handling (from C4)
- **Save**: Stripe .env.local setup for Next.js
- **Save**: Payout calculation formula with discount interaction
- **Save**: Checkout transactional pattern
