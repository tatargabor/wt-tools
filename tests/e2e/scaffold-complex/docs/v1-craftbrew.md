# CraftBrew v1 — Specialty Coffee Webshop Spec

> Next.js 14+ App Router, Prisma (SQLite), shadcn/ui, Tailwind CSS, NextAuth.js v5, Stripe (test mode), Resend (mock)

## Spec Structure

This spec is modular. The main file (this one) contains the overview, conventions, feature dependency graph, and verification checklist. Detailed specs are in subdirectories:

```
docs/
├── v1-craftbrew.md              ← You are here (overview + dependency graph + checklist)
├── catalog/
│   ├── coffees.md               ← 8 specialty coffees with variants
│   ├── equipment.md             ← 7 brewing equipment items
│   ├── merch.md                 ← 5 merch/promo items
│   └── bundles.md               ← 4 curated bundles
├── features/                    ← HOW it should work (business requirements)
│   ├── product-catalog.md       ← Search, filter, variants, cross-sell
│   ├── cart-checkout.md         ← Cart, checkout, shipping zones, Stripe, invoice
│   ├── subscription.md          ← Coffee subscription + delivery scheduling
│   ├── user-accounts.md         ← Registration, login, profile, addresses
│   ├── reviews-wishlist.md      ← Ratings, comments, wishlist, restock alerts
│   ├── promotions.md            ← Coupons, promo days, gift cards
│   ├── content-stories.md       ← Blog/stories, origin stories, brew guides
│   ├── email-notifications.md   ← Transactional emails (mock)
│   ├── admin.md                 ← Dashboard, CRUD, orders, reviews, content
│   ├── i18n.md                  ← HU/EN internationalization rules
│   └── seo.md                   ← Meta tags, schema.org, sitemap, canonical URLs
└── design/                      ← HOW it should look (visual spec)
    └── design-system.md         ← Colors, fonts, layouts, ASCII mockups
```

## Project-Specific Conventions

- **Package manager:** pnpm
- **Currency:** HUF (Hungarian Forint). Integer, no decimals. Format: `new Intl.NumberFormat("hu-HU", { style: "currency", currency: "HUF", maximumFractionDigits: 0 }).format(price)` yielding `2 490 Ft`
- **Language:** HU/EN. Routes: `/hu/...` and `/en/...`. Default: `/hu`. Admin: HU only.
- **Session:** Anonymous cart uses `session_id` httpOnly cookie (UUID via `crypto.randomUUID()`)
- **Tests:** Jest + `@testing-library/react` for unit tests. Playwright for E2E.
- **Stripe:** Test mode. Use `STRIPE_SECRET_KEY=sk_test_...` and `STRIPE_PUBLISHABLE_KEY=pk_test_...` in `.env.local`
- **Email:** Resend SDK in mock mode (no real emails sent). Log to console in dev.
- **Invoice:** szamlazz.hu API mock — fake endpoint returns PDF placeholder
- **Images:** Use `https://placehold.co/400x300?text=...` placeholders in seed data

## Seed Data

The seed script must populate data from the following sources:

- `catalog/coffees.md` — 8 coffees with all variants
- `catalog/equipment.md` — 7 equipment items
- `catalog/merch.md` — 5 merch items (M2 t-shirt with sizes, M4 gift card with denominations, M5 workshop with dates)
- `catalog/bundles.md` — 4 bundles with components
- Coupons: ELSO10, NYAR2026, BUNDLE20 (see features/promotions.md)
- Promo days: Store Birthday, World Coffee Day (see features/promotions.md)
- 5 story categories + 10 stories (see features/content-stories.md)
- Admin user: admin@craftbrew.hu / admin123

## Required Environment Variables

```bash
DATABASE_URL=...          # SQLite or PostgreSQL connection string
NEXTAUTH_SECRET=...       # NextAuth session encryption secret
STRIPE_SECRET_KEY=...     # Stripe test mode secret key (sk_test_...)
STRIPE_PUBLISHABLE_KEY=...# Stripe test mode publishable key (pk_test_...)
STRIPE_WEBHOOK_SECRET=... # Stripe webhook signing secret (whsec_...)
RESEND_API_KEY=...        # Resend API key (re_test_... for mock mode)
SZAMLAZZ_API_URL=...      # szamlazz.hu invoice API endpoint (mock in dev)
```

## Feature Dependency Graph

Shows the natural implementation order and dependencies between features.

```
                      ┌──────────────────┐
                      │  Infrastructure  │
                      │ Prisma, layout,  │
                      │ design, i18n     │
                      └────────┬─────────┘
                               │
                ┌──────────────┼──────────────┐
                ▼              ▼              ▼
      ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
      │   Product    │ │  User Auth   │ │   Content    │
      │   Catalog    │ │  & Accounts  │ │   Stories    │
      └──────┬───────┘ └──────┬───────┘ └──────────────┘
             │                │
             ▼                ▼
        ┌────────┐       ┌──────────┐
        │  Cart  │       │ Wishlist │
        └───┬────┘       └──────────┘
            │
            ▼
  ┌─────────────────┐
  │    Checkout     │
  │ Stripe, zones,  │
  │ coupons, gift   │
  └───┬─────────────┘
      │
      ├──────────────────────┐
      ▼                      ▼
  ┌────────────┐      ┌─────────────────┐
  │  Reviews   │      │  Subscription   │
  └────────────┘      └───┬─────────────┘
                           │
                           ▼
                    ┌──────────────────┐
                    │   Admin Core    │
                    └────────┬─────────┘
                             │
                  ┌──────────┴──────────┐
                  │   Admin Promo      │
                  └────────┬────────────┘
                           │
                           ▼
  ┌──────────────────────────────────────┐
  │       Email Notifications           │
  └──────────────────┬───────────────────┘
                     │
                     ▼
           ┌──────────────────┐
           │       SEO        │
           └────────┬─────────┘
                    │
                    ▼
           ┌──────────────────┐
           │    E2E Tests     │
           └──────────────────┘
```

## Verification Checklist

Post-run verification. Each item must be manually or automatically checkable.

### Storefront
- [ ] Homepage (`/hu`) hero banner with CraftBrew branding, featured products, "What Others Say" section
- [ ] `/hu/kavek` shows 8 coffee products in responsive grid (1/2/3 columns)
- [ ] `/hu/eszkozok` shows 7 equipment items
- [ ] `/hu/merch` shows merch items
- [ ] Product cards: image, name, price in HUF (e.g. "2 490 Ft"), average rating stars
- [ ] Product detail: large image, full description, flavor notes (coffee), variant selector (form/size/grind)
- [ ] Variant selection updates price dynamically
- [ ] Out-of-stock variant: disabled, "Out of Stock" badge
- [ ] Search bar: full-text search across products and stories
- [ ] Filter: by origin, roast level, processing method, price range
- [ ] Bundle page shows contents, individual vs bundle price, savings percentage
- [ ] Cross-sell: "Recommended With This" section on product detail pages
- [ ] Language switcher (HU/EN) in header, persists in session
- [ ] `/en/coffees` shows English content

### Cart & Checkout
- [ ] Add to cart with variant selection
- [ ] Cart page: items with variant info, quantity controls, line totals, cart total
- [ ] Coupon code input on cart page — "ELSO10" gives 10% off first order
- [ ] Gift card code input — partially redeemable, shows remaining balance
- [ ] Checkout step 1: shipping address + zone auto-detection + shipping cost display
- [ ] Checkout step 2: Stripe payment form (test mode card: 4242...)
- [ ] Checkout step 3: order summary with all line items, shipping, discount, total
- [ ] After order: cart cleared, stock decremented, order confirmation page
- [ ] Invoice generated via mock API, downloadable as PDF placeholder
- [ ] Shipping zones: Budapest 990 Ft, +20km 1490 Ft, +40km 2490 Ft
- [ ] Free shipping: Budapest over 15000 Ft, +20km over 25000 Ft

### Subscription
- [ ] Subscription setup page: coffee selection, form/size, frequency (daily/weekly/biweekly/monthly)
- [ ] Delivery window selection: morning (6-9), forenoon (9-12), afternoon (14-17)
- [ ] Subscription pricing: daily -15%, weekly -10%, biweekly -7%, monthly -5%
- [ ] User dashboard: active subscriptions with next delivery date
- [ ] Pause subscription (date range)
- [ ] Skip single delivery
- [ ] Modify subscription (coffee, quantity, schedule)
- [ ] Cancel subscription
- [ ] Daily delivery not available for +40km zone

### User Account
- [ ] Registration form: name, email, password
- [ ] Login with credentials
- [ ] Profile page: personal info, language preference
- [ ] Saved addresses with zone labels
- [ ] Order history with status tracking
- [ ] "My Orders" page shows all past orders with status badges

### Reviews & Wishlist
- [ ] Product detail: star rating display (1-5) with count
- [ ] Write review: only for registered users who purchased the product
- [ ] Review form: star rating + title + text body
- [ ] Reviews appear after admin approval
- [ ] Admin reply visible below review
- [ ] Homepage "What Others Say" section shows top approved reviews
- [ ] Wishlist: heart icon on product cards, dedicated wishlist page
- [ ] "Back in Stock" restock notification opt-in on out-of-stock items

### Promotions
- [ ] Coupon "ELSO10": 10% off, first order only
- [ ] Coupon "NYAR2026": 15% off, expires 2026-08-31, max 500 uses
- [ ] Coupon "BUNDLE20": 20% off, bundles only
- [ ] Coupons not stackable (one per order)
- [ ] Promo day: banner on homepage, auto-discount at checkout, no code needed
- [ ] Gift card: purchasable in 5000/10000/20000 Ft denominations
- [ ] Gift card: redeemable at checkout, partial balance supported

### Content / Stories
- [ ] `/hu/sztorik` lists all published stories by category
- [ ] Story categories: Origin Stories, Roasting, Brew Guides, Health, Gift Ideas
- [ ] Story detail: title, author, date, cover image, body, related products
- [ ] Related products link to product pages
- [ ] At least 10 stories seeded with content

### Admin
- [ ] `/admin` login required (redirect to `/admin/login`)
- [ ] Dashboard: today's revenue, order count, active subscribers, new registrations (7d)
- [ ] Dashboard: top 3 products today, 7-day revenue trend, low stock alerts
- [ ] Products CRUD: DataTable, create/edit with variant management, SEO fields
- [ ] Bundle editor: select components, set bundle price, auto-calculate savings
- [ ] Orders: list with status filter, detail with line items, status flow (New → Processing → Packed → Shipping → Delivered)
- [ ] Daily deliveries view: date picker, grouped by time window, delivery checklist
- [ ] Subscriptions management: list, pause/modify/cancel on behalf of customer
- [ ] Coupons CRUD: code, type, value, expiry, max uses, category filter
- [ ] Promo days: set date, discount %, banner text (HU/EN)
- [ ] Gift cards: list with balance, transaction log
- [ ] Review moderation: approve/reject, admin reply
- [ ] Content/stories: create/edit, category, HU+EN, related products, draft/published

### Email
- [ ] Welcome email on registration (in user's language)
- [ ] Order confirmation with line items, total, shipping address
- [ ] Shipping notification with estimated delivery
- [ ] Delivery confirmation + "How did you like it?" review request link
- [ ] "Back in Stock" restock notification to wishlist subscribers
- [ ] Promo day announcement to all subscribers
- [ ] All emails respect user language preference (HU/EN)

### SEO & Technical
- [ ] Meta title and description on all public pages
- [ ] schema.org Product structured data on product pages
- [ ] XML sitemap at `/sitemap.xml`
- [ ] Open Graph tags for social sharing
- [ ] Canonical URLs on all pages
- [ ] `hreflang` tags linking HU/EN versions
- [ ] `/api/health` returns `{ status: "ok" }`
- [ ] `pnpm build` succeeds
- [ ] `pnpm test` passes
- [ ] `pnpm test:e2e` passes
