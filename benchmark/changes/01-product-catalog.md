# Change 01: Product Catalog with Variants

## Agent Input

### Overview

Build the product catalog — the foundation of CraftBazaar. Products have variants (size, color, material combinations), each with their own price and stock level.

### Requirements

1. **Product model**: Create a Prisma schema for products with fields: `id`, `name`, `description`, `basePrice` (Float), `images` (String — store as JSON string, e.g. `JSON.stringify(["url1","url2"])`), `createdAt`, `updatedAt`

2. **Variant model**: Each product has one or more variants. A variant has: `id`, `productId`, `sku`, `attributes` (the combination, e.g. `{size: "Large", color: "Blue"}`), `price`, `stockQuantity`

3. **API routes** (Next.js App Router API routes):
   - `GET /api/products` — List all products with their variants
   - `GET /api/products/[id]` — Get a single product with variants
   - `POST /api/products` — Create a product
   - `PUT /api/products/[id]` — Update a product
   - `DELETE /api/products/[id]` — Delete a product and its variants
   - `POST /api/products/[id]/variants` — Add a variant to a product
   - `PUT /api/variants/[id]` — Update a variant
   - `DELETE /api/variants/[id]` — Delete a variant

4. **Product browsing page**: A simple page at `/products` that lists all products with images, and a detail page at `/products/[id]` showing variants with their prices and stock

5. **Seed data**: Create a Prisma seed script with at least 5 products, each having 2-4 variants. Use realistic artisan products (ceramic mugs, leather wallets, woven scarves, etc.)

6. **Error format**: All API error responses must use the format `{ "error": "<message>" }` with appropriate HTTP status codes (400, 404, 500). Keep it simple — just the error message string.

### Acceptance Criteria

- [ ] Prisma schema defines Product and Variant models with proper relations
- [ ] All CRUD API routes work and return appropriate status codes
- [ ] Product listing page renders products from the database
- [ ] Product detail page shows variants with prices and stock levels
- [ ] Seed script populates the database with sample data
- [ ] `npm run dev` starts without errors
- [ ] Basic error handling on API routes (404 for missing products, validation errors)

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

### Scoring Focus

- Did the agent use a separate Variant table or JSON? (Critical for later changes)
- How many iterations to get Prisma working? (Generate sequence issue)
- Quality of seed data (realistic? diverse variants?)

### Expected Memory Interactions (Run B)

- **Save**: Prisma generate requirement (if encountered as error)
- **Save**: Variant modeling decision and rationale
- **Save**: Image storage approach chosen
- **Recall**: None (first change, no prior context)
