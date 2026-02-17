# Change 12: Sprint Retrospective Fixes

## Agent Input

### Overview

The sprint retrospective identified 12 bugs across the codebase. Fix all of them.

### Bug Reports

1. **API response format inconsistency**: Some list endpoints return `{ data: [...] }`, others return `{ products: [...] }` or `{ vendors: [...] }` or just `[...]`. Standardize ALL list endpoints to return `{ data: [...], total: N, page: N, limit: N }` format with `?page=&limit=` query params. This includes: products, vendors, orders, coupons, sub-orders — any endpoint that returns a list.

2. **Payout rounding off-by-one with 3+ vendors**: When an order has items from 3 or more vendors, the sum of all vendor payouts doesn't equal the payment amount. The platform fee and payout net amounts have rounding drift. Fix: implement the largest-remainder method for integer splitting — give the remainder cent(s) to the vendor(s) with the largest fractional parts.

3. **Expired reservation checkout returns 500**: When a user tries to check out with a cart that has expired reservations (from the C07 soft-reserve system), the API returns a 500 Internal Server Error instead of a helpful 400 response. Fix: catch the reservation-related error and return `{ error: "Cart reservation expired. Please re-add items.", code: "RESERVATION_EXPIRED" }` with status 400. The error code must come from `src/lib/errors.ts`.

4. **Missing database index**: The `SubOrder` table is frequently queried by `vendorId` (for the vendor dashboard), but there's no database index. Add `@@index([vendorId])` to the SubOrder model in the Prisma schema.

5. **Seed data mixes dollars and cents**: After the C09 migration to integer cents, the seed script has some values still in dollars (e.g., `basePrice: 29.99` instead of `basePrice: 2999`) and some in cents. This causes test data to have products priced at $0.30 instead of $29.99. Fix the seed script to use cents consistently everywhere.

6. **Inconsistent price formatting**: Some pages use `formatPrice()` from `src/lib/formatPrice.ts`, others use inline `.toFixed(2)` or string concatenation. Audit ALL price display across the app and ensure they all use `formatPrice()`. No inline price formatting should remain.

7. **Error codes missing or inconsistent**: Some API error responses include `{ error, code }` using constants from `src/lib/errors.ts`, others return just `{ error: "..." }` without a code or with inline string codes. Audit ALL API error responses and ensure they use error code constants from `src/lib/errors.ts`. Add any missing constants.

8. **Soft-deleted products visible in some queries**: The product listing API correctly filters `WHERE deletedAt IS NULL`, but some other queries (vendor product lists, cart validation, coupon validation, order item display) may include soft-deleted products. Audit ALL product queries and ensure they filter `deletedAt IS NULL`.

9. **Pagination missing on some list endpoints**: Some list endpoints implemented after C01 return raw arrays instead of the `{ data, total, page, limit }` paginated format. Audit ALL list endpoints and ensure consistent pagination with `?page=&limit=` query params.

10. **Responsive layout inconsistency**: Some pages use `<ResponsiveContainer>` (established in C01) and the project's custom Tailwind breakpoints (`sm:480px`), but others may use standard Tailwind breakpoints or no responsive wrapper. Audit ALL UI pages under `src/app/` and ensure they all use `<ResponsiveContainer>` from `src/components/ResponsiveContainer.tsx`. Verify `tailwind.config.ts` has custom breakpoints (`sm: '480px'`, `md: '768px'`, `lg: '1024px'`). No `xl:` or `2xl:` Tailwind classes should exist in the codebase.

11. **Pagination UI inconsistency**: Different pages use different pagination controls — some have Prev/Next buttons, some have page numbers, some have Load More, some have nothing. Create a shared `<Pagination>` component at `src/components/Pagination.tsx` that accepts `page`, `totalPages`, and `onPageChange` props and renders consistent prev/next + page number controls. Replace all ad-hoc pagination UI across the app with this component.

12. **Inconsistent user feedback**: The cart page uses toast notifications (from C10 redesign), but other pages use `window.alert()`, inline messages, or no feedback at all. Create a shared toast/notification system at `src/components/Toast.tsx` (or extend the existing cart toast if one exists). Replace ALL `window.alert()` and `window.confirm()` calls in the app with toast notifications. No `window.alert()` or `window.confirm()` calls should remain in the source code.

### Acceptance Criteria

- [ ] All list API endpoints return `{ data: [...], total: N, page: N, limit: N }` format with query params
- [ ] Payout split for 3-vendor orders sums exactly to payment amount
- [ ] Expired reservation checkout returns 400 with `code: "RESERVATION_EXPIRED"` from errors.ts
- [ ] SubOrder model has `@@index([vendorId])` in Prisma schema
- [ ] Seed script uses integer cents for all money values
- [ ] All price displays use `formatPrice()` — no inline `.toFixed(2)` or string concatenation
- [ ] All API error responses use error code constants from `src/lib/errors.ts`
- [ ] All product queries filter `WHERE deletedAt IS NULL`
- [ ] All list endpoints have consistent `{ data, total, page, limit }` pagination
- [ ] `npx prisma migrate dev` runs without errors
- [ ] `npx prisma db seed` produces consistent data
- [ ] All UI pages use `<ResponsiveContainer>` and custom Tailwind breakpoints
- [ ] No `xl:` or `2xl:` Tailwind classes in src/
- [ ] `src/components/Pagination.tsx` exists and is rendered (`<Pagination .../>`) on all list pages — importing without rendering does not count
- [ ] No ad-hoc pagination markup outside the Pagination component
- [ ] `src/components/Toast.tsx` exists as a shared notification system, mounted once in `src/app/layout.tsx` for global availability
- [ ] No `window.alert()` or `window.confirm()` calls remain in src/

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

**T12.6: formatPrice consistency audit (TRAP-H payoff)**
Bug 6 requires auditing ALL price display for `formatPrice()` usage. The agent must find every place prices are rendered and replace inline formatting. If the agent recalls the `formatPrice()` convention from C01, they know what to search for and where the utility lives.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent knows "formatPrice() is at src/lib/formatPrice.ts" and can grep for `.toFixed(2)` and template literal price formatting. Without memory, must first discover the utility exists, then search for inconsistencies.

**T12.7: Error code consistency audit (TRAP-J payoff)**
Bug 7 requires auditing ALL API error responses for error code constant usage. The agent must find every error response and ensure it uses constants from `src/lib/errors.ts`. If the agent recalls the convention from C02, they know the file path and can grep for inline error strings.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent knows "error codes are in src/lib/errors.ts" from C02 and can systematically audit all routes.

**T12.8: Soft delete query audit (TRAP-K payoff)**
Bug 8 requires auditing ALL product queries for `deletedAt IS NULL` filtering. The agent must find every place products are queried (APIs, cart validation, coupon validation, order display) and add the filter where missing. Recall from C01 is critical.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent knows "products use soft delete — all queries must filter deletedAt" from C01. Without memory, the agent may not even know soft delete exists until they inspect the schema.

**T12.9: Pagination consistency audit (TRAP-I payoff)**
Bug 9 requires auditing ALL list endpoints for consistent `{ data, total, page, limit }` format. The agent must find endpoints that return raw arrays and wrap them. Recall from C01 identifies the convention; code maps identify the locations.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent knows the pagination convention and which endpoints they've built. Without memory, requires full codebase grep.

**T12.10: Responsive layout audit (TRAP-L payoff)**
Bug 10 requires auditing ALL pages for `ResponsiveContainer` usage and custom breakpoints. The agent must check every page under `src/app/` and ensure the wrapper is imported. The custom `sm:480px` breakpoint must be intact in `tailwind.config.ts`.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent knows which pages they built and where ResponsiveContainer is used. Without memory, must search every page file.

**T12.11: Pagination UI unification (TRAP-M payoff)**
Bug 11 requires creating a shared `<Pagination>` component and replacing all ad-hoc pagination UI. This is the IMPLEMENTATION DRIFT trap payoff — the agent must find all existing pagination implementations (which may be different on each page) and replace them with a shared component.

**Memory prediction**: HIGHEST VALUE for code-map recall. Memory-enabled agent knows "C01 /products has Prev/Next buttons, C03 /vendors has page numbers, C11 /dashboard has explicit pagination." Without memory, the agent must search each page to discover what pagination UI exists and how it's implemented. The iteration delta between runs is expected to be significant.

**Evaluator action**: Track iterations spent on Bug 11 separately. Compare: (a) how quickly the agent identified all pages with pagination, (b) how many pages were correctly migrated, (c) whether the shared component is properly parameterized.

**T12.12: Notification unification (TRAP-N payoff)**
Bug 12 requires creating a shared toast system and replacing all `window.alert()`/`window.confirm()` calls. This is the IMPLEMENTATION DRIFT trap payoff — the agent must find all feedback patterns across the app (which vary by page) and standardize them.

**Memory prediction**: HIGHEST VALUE for code-map recall. Memory-enabled agent knows "C02 used alert() for cart, C05 used inline for checkout errors, C06 used alert() for status changes, C10 introduced toast for cart." Without memory, the agent must grep for `window.alert` and search each page for feedback patterns.

**Evaluator action**: Track iterations spent on Bug 12 separately. Compare: (a) how quickly the agent found all alert/confirm calls, (b) whether the toast system extends C10's cart toast or creates a new one, (c) whether all feedback points were migrated.

### Scoring Focus

This is the HARDEST memory test in the benchmark. Now with 12 bugs (5 original + 4 convention audits + 3 new: responsive, pagination UI, toast).

- **Expected time difference**: Memory agent should fix all 12 bugs in ~2-3 iterations (knows all locations, conventions, and implementation details). No-memory agent may need 4-6 iterations searching for each convention's origin, implementation patterns, and all violation sites.
- How many list endpoints were found and standardized?
- Was the largest-remainder algorithm implemented correctly?
- Was the reservation error handled with a 400 and proper error code?
- Were ALL seed values fixed to cents?
- Were ALL price displays migrated to formatPrice()? (TRAP-H)
- Were ALL error responses using errors.ts constants? (TRAP-J)
- Were ALL product queries filtering deletedAt? (TRAP-K)
- Were ALL list endpoints paginated consistently? (TRAP-I)

### Expected Memory Interactions (Run B)

- **Recall**: All API route files and their response formats (HIGHEST VALUE)
- **Recall**: Payout calculation location from C05 (HIGH VALUE)
- **Recall**: Checkout/reservation validation from C07 (HIGH VALUE)
- **Recall**: SubOrder model from C03 (medium value)
- **Recall**: Seed script location and money values from C01/C09 (medium value)
- **Recall**: formatPrice() utility at src/lib/formatPrice.ts (from C01, TRAP-H)
- **Recall**: Error codes convention in src/lib/errors.ts (from C02, TRAP-J)
- **Recall**: Soft delete convention with deletedAt (from C01, TRAP-K)
- **Recall**: Pagination convention { data, total, page, limit } (from C01, TRAP-I)
- **Recall**: Code maps from C01-C11 (all file locations)
- **Save**: "All list endpoints use { data, total, page, limit }" standard
- **Save**: "Largest-remainder method for integer splitting" pattern
- **Recall**: ResponsiveContainer convention from C01, usage across pages (TRAP-L)
- **Recall**: Pagination UI implementations on each page — C01, C03, C11 (TRAP-M — HIGHEST VALUE)
- **Recall**: Notification/feedback patterns per page — C02, C05, C06, C10 (TRAP-N — HIGHEST VALUE)
- **Recall**: Whether C10 toast is reusable or cart-specific (TRAP-N)
