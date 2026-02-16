# Change 08: Product Images Table Migration

## Agent Input

### Overview

The product images stored as a JSON string on the Product model (from Change 01) need to be migrated to a proper `Image` table. This enables alt-text for accessibility, sort ordering, and future features like image tagging.

### Background

In C01, product images were stored as a JSON array of URL strings directly on the Product model (e.g., `images: "[\"url1.jpg\",\"url2.jpg\"]"`). This works for basic display but doesn't support per-image metadata.

### Requirements

1. **Image model**: Create a new Prisma model:
   - `Image`: `id`, `productId`, `url`, `altText` (String, default ""), `sortOrder` (Int, default 0), `createdAt`
   - Relation: Product hasMany Image

2. **Migration strategy**:
   - Create the Image table
   - Write a migration script that reads existing Product.images JSON and creates Image rows
   - Remove the `images` column from Product model after migration
   - Handle products with no images gracefully

3. **API updates**:
   - `GET /api/products` and `GET /api/products/[id]` must return images as:
     ```json
     {
       "images": [
         { "url": "...", "altText": "...", "sortOrder": 0 },
         { "url": "...", "altText": "...", "sortOrder": 1 }
       ]
     }
     ```
   - `POST /api/products` should accept images as an array of `{ url, altText?, sortOrder? }` objects
   - Existing image-related API logic must use the Image table, not JSON

4. **Product pages update**:
   - Product listing and detail pages should render images from the new relation
   - Include alt-text on `<img>` tags

5. **Seed data update**: Update the seed script to create Image records instead of JSON image arrays

### Acceptance Criteria

- [ ] Image model exists in Prisma schema with proper relations
- [ ] Product model no longer has an `images` column
- [ ] `npx prisma validate` passes
- [ ] GET /api/products/[id] returns images as `[{url, altText, sortOrder}]`
- [ ] Seed script creates Image records
- [ ] Product pages render images with alt-text

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T8.1: Knowing the current image storage format**
The agent must know HOW images are currently stored to write the migration. If C01 stored them as `String` (JSON-encoded), the migration must `JSON.parse()` each product's images field. If stored as a Prisma `Json` type, the access pattern is different.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent knows "Product.images is a String field containing JSON array of URLs" from C01's implementation. No-memory agent must examine the schema and possibly the seed data to understand the current format.

**T8.2: Migration ordering**
The agent needs to: (1) add Image table, (2) migrate data, (3) remove images column. If done in the wrong order or in a single migration, data is lost. Prisma migrations are sequential, so the agent might need a custom migration script.

**Memory prediction**: Medium value. Recalling Prisma migration patterns from earlier changes helps.

**T8.3: Updating all image references**
Images may be referenced in: product API routes, product pages, cart display, checkout summary, seed script. The agent must update ALL of these, not just the API routes.

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent knows all the places that display product images across the codebase.

### Scoring Focus

- Did the agent correctly identify the current image format?
- Was the migration done safely (no data loss)?
- Were ALL image references updated?
- Does `npx prisma validate` pass?

### Expected Memory Interactions (Run B)

- **Recall**: C01 Product model — how images are stored (HIGH VALUE)
- **Recall**: Where images are displayed (product pages, cart, checkout) (HIGH VALUE)
- **Recall**: Prisma migration patterns from C03 (medium value)
- **Save**: Image table migration approach
- **Save**: "Images as separate table with altText and sortOrder" decision
