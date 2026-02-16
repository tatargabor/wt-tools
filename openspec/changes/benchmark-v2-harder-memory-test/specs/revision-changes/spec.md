## ADDED Requirements

### Requirement: Change 07 — Stock reservation rethink
Create `benchmark/changes/07-stock-rethink.md` that reverses C02's stock decrement-on-cart-add.

Agent input section must specify:
- Cart add NO LONGER decrements stock immediately
- Instead: create a `CartReservation` model with `expiresAt` (15 min TTL)
- Checkout validates reservations are still live, THEN decrements stock
- Background cleanup: expired reservations release stock (cron or on-access)
- All existing cart tests must still pass after refactoring

Evaluator notes section must specify:
- **Memory prediction**: Agent should recall C02's `UPDATE Variant SET stockQuantity = stockQuantity - N WHERE stockQuantity >= N` pattern and know exactly what to refactor
- **Expected difference**: Memory agent targets the specific stock update code. No-memory agent must rediscover the implementation by reading files.
- **Measurable**: After C07, `POST /api/cart/items` does NOT decrease `Variant.stockQuantity`. Only `POST /api/checkout/confirm` does.

#### Scenario: Cart add with soft reservation
- **WHEN** user adds item to cart
- **THEN** a CartReservation record is created with 15-min expiry, stock is NOT decremented

#### Scenario: Checkout validates reservation
- **WHEN** user checks out with an expired reservation
- **THEN** checkout fails with "reservation expired" error, stock unchanged

#### Scenario: Reservation cleanup
- **WHEN** a reservation expires
- **THEN** the reservation is deleted (on next access or background task)

---

### Requirement: Change 08 — Images table migration
Create `benchmark/changes/08-images-table.md` that migrates C01's JSON-string images to a separate table.

Agent input section must specify:
- Create `Image` model: `id`, `productId`, `url`, `altText`, `sortOrder`, `createdAt`
- Migrate existing `Product.images` (JSON string) data to new `Image` records
- Write a Prisma migration that: (a) creates Image table, (b) migrates data via raw SQL, (c) drops Product.images column
- Update all API endpoints to return `product.images` as array of Image objects
- Update product detail page to show images with alt text

Evaluator notes section must specify:
- **Memory prediction**: Agent should recall C01's design decision "images stored as JSON string in Product.images" and know the exact data format to migrate from
- **Expected difference**: Memory agent knows the source format without reading. No-memory agent must inspect the schema and existing data.
- **Measurable**: After C08, `Product` model has no `images` field. `Image` table exists with FK to Product. API returns `images: [{url, altText, sortOrder}]`.

#### Scenario: Data migration preserves existing images
- **WHEN** migration runs on a database with products that have JSON images
- **THEN** all existing image URLs appear in the Image table with correct productId

#### Scenario: API returns new format
- **WHEN** GET /api/products/[id] is called
- **THEN** response includes `images` array with `{id, url, altText, sortOrder}` objects

---

### Requirement: Change 09 — Integer cents everywhere
Create `benchmark/changes/09-integer-cents.md` that replaces all Decimal/Float money fields with integer cents.

Agent input section must specify:
- ALL money-related fields switch from Decimal/Float to Int (cents): Product.basePrice, Variant.price, SubOrder.subtotal, Order.totalAmount, Payment.amount, VendorPayout.grossAmount/platformFee/netAmount, Coupon.value, Coupon.minOrderValue
- Write Prisma migration that converts existing data: `UPDATE table SET field = CAST(field * 100 AS INTEGER)`
- Update ALL calculations: tax, discount, payout split — all in cents, divide by 100 only for display
- Update ALL API responses: add `_cents` suffix or document that amounts are in cents
- Update UI: format cents to dollars with 2 decimal places

Evaluator notes section must specify:
- **Memory prediction**: Agent should recall the complete list of money fields from C01, C03, C04, C05 schemas. Missing even one field breaks arithmetic.
- **Expected difference**: Memory agent has a mental map of all money fields. No-memory agent must grep/search exhaustively.
- **Measurable**: After C09, ALL money columns in Prisma schema are `Int`. No `Decimal` or `Float` money fields remain. Payout math: `sum(netAmount) + sum(platformFee) == payment.amount` (exact integer equality, no rounding).

#### Scenario: All money fields are integer
- **WHEN** evaluator inspects Prisma schema after C09
- **THEN** every field that stores money is type `Int` with comment "// cents"

#### Scenario: Payout arithmetic is exact
- **WHEN** an order with discount is placed and payouts calculated
- **THEN** `sum(vendor_net) + sum(platform_fee) == payment_amount` with zero rounding error

#### Scenario: API displays correctly
- **WHEN** GET /api/products returns prices
- **THEN** prices are returned as integers (cents) or formatted strings, consistently across all endpoints
