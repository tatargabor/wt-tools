# Design System

## Figma

**Design file:** https://www.figma.com/design/QrtIGnpTs8jPbEXFuLu2xO/Untitled
**Figma Make:** https://www.figma.com/make/DDCs2kpcLYw6E3Q1EcDjCK/Detailed-Webshop-Design

### Frame mapping

| Frame | Content | Related spec |
|-------|---------|--------------|
| Design Tokens & Components | Colors, typography, buttons, cards, badges | design-system.md |
| Homepage Desktop (1280px) | Header, Hero, Featured, Subscription CTA, Stories, Testimonials, Footer | product-catalog.md |
| Homepage Mobile (375px) | Hamburger drawer, mobile hero, 1-column layout | product-catalog.md |
| Coffee Catalog | Filter sidebar, 3-column grid, sorting | product-catalog.md |
| Product Detail | Variant selector, reviews, recommended products | product-catalog.md, reviews-wishlist.md |
| Cart | Cart items, coupon/gift card input, summary | cart-checkout.md |
| Checkout 3-Step | Shipping, payment, confirmation | cart-checkout.md |
| Subscription Wizard | 5-step wizard (coffee, form, frequency, delivery, summary) | subscription.md |
| User Subscriptions & Calendar | Subscription card, calendar view | subscription.md |
| User Orders & Profile | Profile, addresses, orders, favorites | user-accounts.md, reviews-wishlist.md |
| Admin Dashboard | KPI cards, revenue chart, top products, low stock | admin.md |
| Admin Products | Product list, editor tabs, bundle editor | admin.md |
| Admin Orders & Deliveries | Order list, daily deliveries view | admin.md |
| Admin Coupons/Promo/Gift/Reviews | 4 admin management pages | admin.md, promotions.md, reviews-wishlist.md |
| Stories | Story list + detail + admin editor | content-stories.md |
| Auth Pages | Login, register, password reset | user-accounts.md |
| Special States | 404, 500, empty states, loading, toast, promo banner | — |
| Email Templates | Welcome, order, shipping, gift card | email-notifications.md |

> Agents read Figma frames via Figma MCP during implementation. The design-bridge rule (.claude/rules/design-bridge.md) instructs them to follow design tokens and component structure.

## Brand

**CraftBrew** — warm, artisanal, premium but not elitist. The joy and community of coffee.

## Colors

```
Primary:     #78350F  (amber-900)   — dark coffee brown (buttons, active nav)
Secondary:   #D97706  (amber-600)   — gold (hover, accent, link)
Background:  #FFFBEB  (amber-50)    — warm cream (page background)
Surface:     #FFFFFF                 — card/panel background
Text:        #1C1917  (stone-900)   — main text
Muted:       #78716C  (stone-500)   — secondary text
Border:      #E7E5E4  (stone-200)   — borders
Success:     #16A34A  (green-600)   — in stock, success
Warning:     #D97706  (amber-600)   — low stock, warning
Error:       #DC2626  (red-600)     — error, out of stock
```

Tailwind custom colors in `tailwind.config.ts`:
```typescript
colors: {
  brand: {
    primary: '#78350F',
    secondary: '#D97706',
    cream: '#FFFBEB',
  }
}
```

## Typography

- **Headings:** Playfair Display (serif) — h1-h3
- **Body:** Inter (sans-serif) — p, span, label, button
- **Mono:** JetBrains Mono — code, order numbers

Font loading: `next/font/google`

Sizing:
- h1: 2.5rem (40px), font-bold
- h2: 2rem (32px), font-semibold
- h3: 1.5rem (24px), font-semibold
- body: 1rem (16px), font-normal
- small: 0.875rem (14px)
- caption: 0.75rem (12px)

## Spacing & Layout

- Container max-width: 1280px, auto margin
- Section padding: py-12 (48px) desktop, py-8 (32px) mobile
- Card padding: p-6 (24px)
- Grid gap: gap-6 (24px) desktop, gap-4 (16px) mobile
- Border radius: rounded-lg (8px) cards, rounded-md (6px) buttons/inputs

## Responsive Breakpoints

| Breakpoint | Width | Characteristics |
|---|---|---|
| Mobile | < 640px | 1 column, hamburger nav, stack layout |
| Tablet | 640px - 1023px | 2 column grid, compact nav |
| Desktop | >= 1024px | 3-4 column grid, full nav |

## Mobile Rules (CRITICAL)

1. **No horizontal overflow** — nothing should overflow horizontally (except DataTable)
2. **Touch target** — minimum 44x44px for every button, link, checkbox
3. **Font size** — minimum 16px in input fields (iOS zoom prevention)
4. **Safe area** — padding-bottom for sticky elements (iOS bottom bar)
5. **Images** — `object-fit: cover`, fixed aspect ratio, no distortion
6. **Modal/Dialog** — on mobile use full-screen sheet (sliding up from bottom), not a small modal

> For visual reference of all layouts (desktop + mobile), see the Figma frames listed above.

## Components

Using shadcn/ui components:
- Button, Card, Badge, Input, Label, Select, Checkbox, RadioGroup
- Dialog (desktop) / Sheet (mobile) — responsive modal
- DropdownMenu, Table, DataTable
- Toast (notifications)
- Separator, Tabs
- Calendar (date picker — subscription, promo day)
- Accordion (FAQ, filters on mobile)
