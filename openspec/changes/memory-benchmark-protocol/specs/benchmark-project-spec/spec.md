## ADDED Requirements

### Requirement: CraftBazaar project specification document
The benchmark SHALL include a `project-spec.md` that fully describes the CraftBazaar multi-vendor artisan marketplace. This document serves as the initial brief that the agent receives when starting the project. It SHALL describe the business domain, tech stack (Next.js 14 + Prisma + SQLite), core entities, and high-level feature list without prescribing implementation details.

#### Scenario: Agent reads project spec before first change
- **WHEN** the agent starts the CraftBazaar project
- **THEN** the project-spec provides enough context to understand the domain
- **THEN** the project-spec does NOT reveal traps or prescribe architecture decisions

### Requirement: Change 01 — Product Catalog with Variants
The benchmark SHALL define Change 01 covering: product model with name/description/price/images, variant system (size/color/material combinations), basic CRUD API routes, and seed data. The change description SHALL include acceptance criteria but not implementation hints.

Trap documentation (evaluator-only, not shown to agent):
- T1.1: Variant modeling decision — flat JSON vs separate table. Flat approach breaks in C3/C4.
- T1.2: Prisma setup sequence — must run `prisma generate` after schema changes.
- T1.3: Image handling — local file storage decision affects C5.

#### Scenario: Agent implements Change 01
- **WHEN** the agent receives the Change 01 description
- **THEN** the agent creates a working product catalog with variant support
- **THEN** the evaluator documents which variant modeling approach was chosen

### Requirement: Change 02 — Shopping Cart and Inventory
The benchmark SHALL define Change 02 covering: cart CRUD operations, variant-level stock tracking, stock reservation on add-to-cart, and cart total calculation. The change builds on Change 01's product/variant model.

Trap documentation (evaluator-only):
- T2.1: SQLite concurrent write issue — cart updates fail with SQLITE_BUSY without WAL mode.
- T2.2: Cart must reference variant, not product — first pain point if C1 variant model is wrong.
- T2.3: Stock validation race condition — check-then-decrement without transaction causes oversell.

#### Scenario: Agent implements Change 02
- **WHEN** the agent receives the Change 02 description
- **THEN** the agent creates a working cart with inventory management
- **THEN** the evaluator documents any SQLite issues encountered and how they were resolved

### Requirement: Change 03 — Multi-Vendor Order Splitting
The benchmark SHALL define Change 03 covering: vendor model, product-vendor association, order creation from cart, and order splitting into per-vendor sub-orders. This is the most architecturally significant change.

Trap documentation (evaluator-only):
- T3.1: Order model architecture — flat order with vendor_id per line vs parent order + sub-orders. Flat approach breaks in C6 (per-vendor status tracking).
- T3.2: Prisma migration on existing data — adding vendor FK + splitting orders is complex.
- T3.3: API redesign cascade — product and cart APIs need vendor context.

#### Scenario: Agent implements Change 03
- **WHEN** the agent receives the Change 03 description
- **THEN** the agent creates a working multi-vendor order system
- **THEN** the evaluator documents the order architecture decision (flat vs nested)

### Requirement: Change 04 — Discount and Coupon Engine
The benchmark SHALL define Change 04 covering: coupon CRUD, percentage and fixed-amount discounts, vendor-specific coupons, minimum order value rules, and discount application at checkout.

Trap documentation (evaluator-only):
- T4.1: Discount scope confusion — must apply to variant level, not product level.
- T4.2: Coupon + multi-vendor interaction — how to split a cross-vendor discount.
- T4.3: Prisma Decimal precision — SQLite + Prisma Decimal handling has quirks.

#### Scenario: Agent implements Change 04
- **WHEN** the agent receives the Change 04 description
- **THEN** the agent creates a working discount/coupon system
- **THEN** the evaluator documents whether the agent recalled variant-level pricing from C1/C2

### Requirement: Change 05 — Checkout and Payment
The benchmark SHALL define Change 05 covering: checkout flow UI, Stripe test mode integration, tax calculation, multi-vendor payout split calculation, and order confirmation.

Trap documentation (evaluator-only):
- T5.1: Stripe env setup — STRIPE_SECRET_KEY must go in `.env.local` for Next.js.
- T5.2: Multi-vendor payout calculation — must work with C4 discounts.
- T5.3: SQLite BUSY again — payment records under concurrent checkout, same root cause as C2.

#### Scenario: Agent implements Change 05
- **WHEN** the agent receives the Change 05 description
- **THEN** the agent creates a working checkout with Stripe test mode
- **THEN** the evaluator documents whether the agent reused C2's SQLite WAL knowledge

### Requirement: Change 06 — Order Status Workflow
The benchmark SHALL define Change 06 covering: state machine per sub-order (pending → confirmed → shipped → delivered), vendor dashboard for status updates, buyer order tracking page, and status transition validation.

Trap documentation (evaluator-only):
- T6.1: State machine on flat vs nested orders — if C3 used flat orders, this requires massive rework.
- T6.2: Status transition validation — must enforce valid transitions only.
- T6.3: Real-time updates — Next.js App Router + SSE has specific patterns.

#### Scenario: Agent implements Change 06
- **WHEN** the agent receives the Change 06 description
- **THEN** the agent creates a working order status workflow
- **THEN** the evaluator documents whether the agent benefited from C3's architecture decision

### Requirement: Change descriptions separate agent input from evaluator notes
Each change definition file SHALL have two clearly separated sections: "Agent Input" (what the evaluator pastes to the agent) and "Evaluator Notes" (trap documentation, scoring focus areas, expected memory interactions). The agent SHALL never see the Evaluator Notes section.

#### Scenario: Evaluator uses change definition
- **WHEN** the evaluator opens `changes/03-multi-vendor.md`
- **THEN** the "Agent Input" section is clearly delineated and ready to copy-paste
- **THEN** the "Evaluator Notes" section documents traps, memory expectations, and scoring focus

### Requirement: Trap documentation with memory interaction predictions
Each change's evaluator notes SHALL predict how memory should interact with the change's traps. Predictions SHALL specify: what memory should be saved (if this is the first encounter), what memory should be recalled (if a prior change created relevant knowledge), and what happens without memory (expected failure mode).

#### Scenario: Evaluator reviews trap predictions after a session
- **WHEN** the evaluator compares actual session behavior to trap predictions
- **THEN** the evaluator can determine whether memory helped, didn't help, or was irrelevant for each predicted trap
