# CraftBazaar — Multi-Vendor Artisan Marketplace

## Business Context

CraftBazaar is an online marketplace where independent artisans sell handmade goods directly to buyers. Think Etsy-style: multiple vendors, each with their own product catalog, fulfillment, and order management. The platform handles the shared infrastructure — product browsing, cart, checkout, payment splitting, and order tracking.

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **ORM**: Prisma
- **Database**: SQLite (file-based, zero external dependencies)
- **Payment**: Stripe (test mode)
- **Language**: TypeScript
- **Styling**: Tailwind CSS (custom breakpoints: `sm:480px`, `md:768px`, `lg:1024px`)

## Core Entities

### Product
A physical item listed by a vendor. Has a name, description, base price, and images. Products can have **variants** — combinations of attributes like size, color, and material, each with their own price and stock level.

### Variant
A specific purchasable configuration of a product. For example, a "Ceramic Mug" product might have variants: Large/Blue, Small/Red, Large/Green. Each variant has its own SKU, price, and inventory count.

### Vendor
An independent seller on the platform. Each vendor manages their own products, fulfills their own orders, and has a dashboard for order management.

### Cart
A buyer's shopping session. Contains items (referencing specific variants) with quantities. Tracks totals and validates stock availability.

### Order
A completed purchase. Since a single cart can contain items from multiple vendors, an order may need to be split into per-vendor sub-orders for independent fulfillment and tracking.

### Coupon / Discount
Promotional pricing. Can be percentage-based or fixed amount, global or vendor-specific, with minimum order value rules.

## Feature Overview

The platform is built incrementally through 6 changes:

1. **Product Catalog** — Product and variant CRUD, browsing, seed data
2. **Shopping Cart** — Cart management, stock tracking, reservation
3. **Multi-Vendor Orders** — Vendor model, order creation, per-vendor splitting
4. **Discounts** — Coupon system, discount types, vendor-specific promotions
5. **Checkout & Payment** — Stripe integration, tax calculation, payout splitting
6. **Order Workflow** — Status state machine, vendor dashboard, buyer tracking

Each change builds on the previous ones. The data model evolves as new features are added.

## Project Structure

```
craftbazaar/
├── prisma/
│   └── schema.prisma
├── src/
│   ├── app/                  # Next.js App Router pages
│   │   ├── api/              # API routes
│   │   ├── products/         # Product browsing pages
│   │   ├── cart/             # Cart page
│   │   ├── checkout/         # Checkout flow
│   │   ├── orders/           # Buyer order tracking
│   │   └── vendor/           # Vendor dashboard
│   ├── lib/                  # Shared utilities, DB client
│   └── components/           # Reusable UI components (ResponsiveContainer, Pagination, Toast)
├── public/                   # Static assets
├── docs/
│   └── benchmark/            # Change definitions (agent input)
├── results/                  # Per-change status files (written by agent)
├── openspec/                 # OpenSpec config and changes
├── CLAUDE.md                 # Agent instructions
├── package.json
└── tsconfig.json
```

## Development Commands

```bash
# Install dependencies
npm install

# Run Prisma migrations
npx prisma migrate dev

# Generate Prisma client
npx prisma generate

# Start dev server
PORT=${PORT:-3000} npm run dev

# Run tests
npm test

# Seed database
npx prisma db seed
```

## Constraints

- SQLite only — no external database servers
- Stripe test mode only — no real payments
- All data stored locally (no cloud services)
- Single-machine deployment (no containers, no cloud hosting)
