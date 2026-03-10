# Product Catalog Feature

## Product List Pages

Four main catalog pages:
- Coffees — 8 coffees
- Equipment — 7 equipment items
- Merch — 5 merch/promo items
- Bundles — 4 bundles

Each page uses a responsive grid: 1 column mobile (< 640px), 2 columns tablet (640-1023px), 3 columns desktop (>= 1024px).

## Product Card

Each card contains:
- Product image (placeholder)
- Name (by language HU/EN)
- Price (lowest variant price, e.g., "from 2 490 Ft")
- Average star rating (if reviews exist) + review count
- "New" badge if newer than 7 days
- "Out of Stock" badge if all variant stock is 0
- Favorite heart icon (for logged-in users)

## Product Details Page

Individual page for every product.

### Coffee Product Details

```
┌─────────────────────────────────────────────────────────┐
│  ┌──────────────┐  Name (large, Playfair Display)       │
│  │              │  Origin: Ethiopia, 1800-2200m          │
│  │  PRODUCT IMG │  Roast: ●○○ Light                     │
│  │   (large)    │  Processing: Washed                    │
│  │              │                                        │
│  │              │  Flavor Notes: [floral] [citrusy]      │
│  │              │                [jasmine] [bergamot]     │
│  └──────────────┘                                        │
│                                                          │
│  Description text (2-3 paragraphs)                      │
│                                                          │
│  ┌─ Variant Selector ────────────────────────────┐     │
│  │ Form:     [Whole Bean ▼]                        │     │
│  │ Size:       ○ 250g (2490 Ft)                    │     │
│  │             ● 500g (4680 Ft)                    │     │
│  │             ○ 1kg  (6580 Ft)                    │     │
│  │                                                 │     │
│  │ Grind (if ground): [Filter ▼]                   │     │
│  │                                                 │     │
│  │ Stock: 30 pcs                                   │     │
│  │                                                 │     │
│  │ Quantity: [- 1 +]                               │     │
│  │                                                 │     │
│  │ [████ Add to Cart ████] [♡ Favorite]            │     │
│  └─────────────────────────────────────────────────┘     │
│                                                          │
│  ── Recommended For You ─────────────────────────────   │
│  [V60 Dripper]  [V60 Filter]  [Starter Bundle]          │
│                                                          │
│  ── Reviews (4.5★ — 12 reviews) ────────────────────   │
│  [review list...]                                        │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Equipment/Merch Details

Simpler layout — no variant selector (except M2 t-shirt size, M4 gift card denomination, M5 workshop date).

## Variant Selector Logic

1. User selects the form (whole bean/ground)
2. If ground: grind type appears (filter/espresso/french press/turkish)
3. User selects the packaging size
4. Price, stock, and SKU update dynamically
5. If the selected variant stock is 0: "Out of Stock" — add-to-cart button disabled, "Notify Me" link (wishlist)

## Search

Search field in the header (on every page):
- Full-text search: product name, description, flavor notes
- Story article titles and content are also searchable
- Result list: products and stories in separate sections
- Minimum 3 characters
- Debounce: 300ms

## Filtering (coffee page)

Left-side filter panel on the coffee list (slide-up drawer on mobile):
- **Origin:** checkbox list (Ethiopia, Colombia, Brazil, Guatemala, Kenya, Indonesia, Costa Rica, Rwanda)
- **Roast:** Light / Medium / Dark
- **Processing:** Washed / Natural / Honey / Wet-hulled
- **Price:** range slider (min-max)
- Filters are combinable (AND logic)
- URL query parameters reflect the filters (bookmarkable, shareable)
- "Clear Filters" button

## Cross-sell

Each product has a maximum of 3 "Recommended For You" products:
- Admin manually configures the related products
- Seed data contains the default cross-sell pairs:
  - For coffees: relevant equipment + filter + bundle
  - For equipment: best-matching coffee
  - For bundles: complementary equipment or coffee

## Mobile

- Product cards in 1 column layout (< 640px)
- Filter panel in slide-up drawer (not inline sidebar)
- No horizontal overflow on any catalog page

## Bundle Page

Bundle product card extra info:
- Content list (component products)
- "Separate price" crossed out + "Bundle price" highlighted
- Savings % badge (e.g., "-28%")
- Bundle stock = minimum stock among components
