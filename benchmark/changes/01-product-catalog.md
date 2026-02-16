# Change 01: Product Catalog with Variants

## Agent Input

### Overview

Build the product catalog — the foundation of CraftBazaar. Products have variants (size, color, material combinations), each with their own price and stock level.

### Requirements

1. **Product model**: Create a Prisma schema for products with fields: `id`, `name`, `description`, `basePrice` (Float), `images` (String — store as JSON string, e.g. `JSON.stringify(["url1","url2"])`), `createdAt`, `updatedAt`

2. **Variant model**: Each product has one or more variants. A variant has: `id`, `productId`, `sku`, `attributes` (the combination, e.g. `{size: "Large", color: "Blue"}`), `price`, `stockQuantity`

3. **API routes** (Next.js App Router API routes):
   - `GET /api/products` — List all products with their variants. Must support pagination with `?page=1&limit=20` query params (defaults: page 1, limit 20). Response format: `{ "data": [...], "total": N, "page": N, "limit": N }`. All future list endpoints must follow this same format.
   - `GET /api/products/[id]` — Get a single product with variants
   - `POST /api/products` — Create a product
   - `PUT /api/products/[id]` — Update a product
   - `DELETE /api/products/[id]` — Delete a product and its variants
   - `POST /api/products/[id]/variants` — Add a variant to a product
   - `PUT /api/variants/[id]` — Update a variant
   - `DELETE /api/variants/[id]` — Delete a variant

4. **Product browsing page**: A simple page at `/products` that lists all products with images, and a detail page at `/products/[id]` showing variants with their prices and stock

5. **Seed data**: Create a Prisma seed script with at least 5 products, each having 2-4 variants. Use realistic artisan products (ceramic mugs, leather wallets, woven scarves, etc.)

6. **Price display utility**: Create a shared `formatPrice(cents: number): string` utility function at `src/lib/formatPrice.ts`. This function converts cents to a dollar display string (e.g., `2999` → `"$29.99"`). Use this function everywhere prices are displayed — product listing, product detail, and any future pages. Never format prices inline with `.toFixed(2)` or string concatenation; always use `formatPrice()`.

7. **Soft delete support**: Products must support soft deletion. Add a `deletedAt DateTime?` field to the Product model (nullable, default null). The `DELETE /api/products/[id]` endpoint should set `deletedAt = now()` instead of actually deleting the record. All product listing queries (API and pages) must filter `WHERE deletedAt IS NULL` to hide soft-deleted products. The `GET /api/products/[id]` endpoint should return 404 for soft-deleted products.

8. **Error format**: All API error responses must use the format `{ "error": "<message>" }` with appropriate HTTP status codes (400, 404, 500). Keep it simple — just the error message string.

### Acceptance Criteria

- [ ] Prisma schema defines Product and Variant models with proper relations
- [ ] All CRUD API routes work and return appropriate status codes
- [ ] Product listing page renders products from the database
- [ ] Product detail page shows variants with prices and stock levels
- [ ] Seed script populates the database with sample data
- [ ] `npm run dev` starts without errors
- [ ] Basic error handling on API routes (404 for missing products, validation errors)
- [ ] `GET /api/products` returns `{ data, total, page, limit }` with pagination query params
- [ ] `formatPrice()` utility exists at `src/lib/formatPrice.ts` and is used for all price display
- [ ] Product model has `deletedAt DateTime?` field; DELETE endpoint soft-deletes; listings filter `deletedAt IS NULL`

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T1.1: Variant modeling decision**
The agent must decide how to model variants. Two approaches:
- **Separate Variant table** (correct): Each variant is a row in a `Variant` table with a FK to `Product`. This supports per-variant pricing, stock, and order references cleanly.
- **JSON field on Product** (problematic): Storing variants as a JSON array on the Product model. This works for C1 but breaks in C2 (can't reference a variant from cart), C3 (can't associate variant with vendor order line), and C4 (can't apply discount at variant level).

**Memory prediction**: If the agent uses JSON variants and later discovers the problem, a memory-enabled agent would save "variants must be a separate table" — helping avoid the same mistake if the project were repeated or a similar pattern appears.

**T1.2: Prisma generate sequence**
After modifying `schema.prisma`, the agent must run `npx prisma migrate dev` (which also generates the client) or `npx prisma generate` separately. Forgetting `prisma generate` leads to TypeScript errors where the Prisma client doesn't know about new models.

**Memory prediction**: This is an environment quirk that memory should capture. In C2-C6, a memory-enabled agent should recall "run prisma generate after schema changes" and avoid the error entirely.

**T1.3: Image handling**
The spec says `images` is an array of URLs. The agent must decide: JSON array field in SQLite, or a separate Image table. JSON is simpler but has query limitations. Neither choice is wrong for this project, but the decision affects C5 (product display in checkout).

**Memory prediction**: Low-impact trap. Documenting the decision helps future changes but isn't likely to cause failures.

**T1.4: API pagination convention (TRAP-I first occurrence)**
The change def requires `GET /api/products` to return `{ data, total, page, limit }` with query params. This establishes a convention that ALL future list endpoints must follow. When C03 adds vendor/order listing, C05 adds order history, and C11 adds paginated dashboard, the agent must apply the same format. C12 sprint retro checks ALL list endpoints for consistency.

**Memory prediction**: HIGH VALUE convention save. Memory-enabled agent saves "all list endpoints use { data, total, page, limit } envelope format." When C03/C05 add new list endpoints, the agent automatically follows the convention. Without memory, each new endpoint might use a different response shape.

**T1.5: formatPrice utility creation (TRAP-H first occurrence)**

The change def requires a shared `formatPrice()` utility at `src/lib/formatPrice.ts`. If the agent creates it, all future changes can import and use it. If the agent skips it and formats prices inline (`.toFixed(2)`, template literals), then C09 (integer cents migration) becomes much harder — instead of updating one utility, the agent must find and update every inline format site.

**Memory prediction**: HIGH VALUE convention save. Memory-enabled agent saves "use formatPrice() from src/lib/formatPrice.ts for all price display" in C01. In C04/C05, the agent imports it automatically. In C09, it only updates the utility. Without memory, the agent may re-invent inline formatting each time.

**T1.6: Soft delete pattern (TRAP-K first occurrence)**
The change def requires `deletedAt DateTime?` on Product and soft-delete behavior. If implemented correctly, all future product queries must filter `WHERE deletedAt IS NULL`. This becomes a trap in C04 (coupon shouldn't apply to deleted products), C08 (images migration must handle deleted products), and C12 (sprint retro checks all queries filter correctly).

**Memory prediction**: HIGH VALUE convention save. Memory-enabled agent saves "Products use soft delete — always filter deletedAt IS NULL in queries." When C04 adds product-related queries or C08 migrates images, the agent applies the filter. Without memory, the agent may query without the filter, silently including deleted products.

### Scoring Focus

- Did the agent use a separate Variant table or JSON? (Critical for later changes)
- How many iterations to get Prisma working? (Generate sequence issue)
- Quality of seed data (realistic? diverse variants?)
- Did product listing API return `{ data, total, page, limit }` envelope? (TRAP-I)
- Did the agent create `formatPrice()` utility or use inline formatting? (TRAP-H)
- Did the agent implement soft delete with `deletedAt` filter? (TRAP-K)

### Expected Memory Interactions (Run B)

- **Save**: Prisma generate requirement (if encountered as error)
- **Save**: Variant modeling decision and rationale
- **Save**: Image storage approach chosen
- **Save**: API pagination convention { data, total, page, limit } (HIGH VALUE — reused in C03, C05, C11, C12)
- **Save**: formatPrice() utility at src/lib/formatPrice.ts (HIGH VALUE — reused in C04, C05, C09)
- **Save**: Soft delete pattern — Products filter deletedAt IS NULL (HIGH VALUE — reused in C04, C08, C12)
- **Recall**: None (first change, no prior context)
