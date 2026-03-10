# Design System

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

## Homepage Layout (`/hu`)

```
┌─────────────────────────────────────────────────────────────┐
│  ┌─ Header ───────────────────────────────────────────────┐│
│  │ 🔶 CraftBrew    Coffees  Equipment  Stories  🔍  🛒 EN││
│  └────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌─ Hero Banner ──────────────────────────────────────────┐│
│  │                                                         ││
│  │  "Specialty coffee,                                     ││
│  │   delivered to your table."  [Browse our coffees →]    ││
│  │                                                         ││
│  │  (background: large coffee bean/cup image placeholder)  ││
│  │                                                         ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌─ Featured Coffees ───────────────────────────────────────┐│
│  │  "Our Favorites"                                        ││
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  ││
│  │  │ Ethiopia │ │ Colombia │ │ Rwanda   │ │ Kenya    │  ││
│  │  │ 2490 Ft  │ │ 2890 Ft  │ │ 3490 Ft  │ │ 3290 Ft  │  ││
│  │  │ ★★★★★    │ │ ★★★★☆    │ │ ★★★★★    │ │ ★★★★☆    │  ││
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘  ││
│  │                          [View all →]                   ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌─ Subscription CTA ──────────────────────────────────────┐│
│  │  ┌──────────────────────────────────────────────────┐  ││
│  │  │  "Fresh coffee every morning — with a sub"       │  ││
│  │  │  Daily delivery in Budapest, 15% discount        │  ││
│  │  │                                                  │  ││
│  │  │  [Subscription details →]                        │  ││
│  │  └──────────────────────────────────────────────────┘  ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌─ Testimonials ────────────────────────────────────────────┐│
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐               ││
│  │  │ ★★★★★    │ │ ★★★★★    │ │ ★★★★☆    │               ││
│  │  │ "The best│ │ "The     │ │ "Always  │               ││
│  │  │ coffee   │ │ Starter  │ │ arrives  │               ││
│  │  │ of my    │ │ Pack is  │ │ fresh"   │               ││
│  │  │ life"    │ │ perfect" │ │          │               ││
│  │  │ Kiss J.  │ │ Toth M.  │ │ Szabo K. │               ││
│  │  └──────────┘ └──────────┘ └──────────┘               ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌─ Footer ───────────────────────────────────────────────┐│
│  │  CraftBrew              Products          Contact      ││
│  │  Specialty Coffee        Coffees           hello@craft ││
│  │  Budapest               Equipment          brew.hu     ││
│  │                          Stories                        ││
│  │  © 2026 CraftBrew       Subscription       [FB] [IG]  ││
│  └────────────────────────────────────────────────────────┘│
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Responsive Rules (CRITICAL)

The entire application must be responsive. On mobile (< 640px) nothing should overflow or shift out of alignment.

### Breakpoints

| Breakpoint | Width | Characteristics |
|---|---|---|
| Mobile | < 640px | 1 column, hamburger nav, stack layout |
| Tablet | 640px - 1023px | 2 column grid, compact nav |
| Desktop | >= 1024px | 3-4 column grid, full nav |

### Mobile-Specific Rules

**Header:**
- Logo + hamburger icon (NOT: all menu items spelled out!)
- Hamburger click -> slide-in drawer (from left side)
- Drawer content: menu items, language, cart, profile
- Drawer close: overlay click or X button

```
Mobile header:
┌─────────────────────────────┐
│ ☰  🔶 CraftBrew     🔍 🛒  │
└─────────────────────────────┘

Drawer open:
┌────────────────┬────────────┐
│ ✕              │            │
│                │  (overlay) │
│ Coffees        │            │
│ Equipment      │            │
│ Stories        │            │
│ Subscription   │            │
│ ────────────── │            │
│ 🛒 Cart (3)   │            │
│ 👤 My Account │            │
│ 🌐 EN         │            │
└────────────────┴────────────┘
```

**Product Cards:**
- 1 column, full width
- Card: horizontal layout (image left, info right) OR vertical (image on top)
- Price and stars clearly visible
- Minimum touch target: 44x44px for every interactive element

**Product Details:**
- Image full width
- Variant selector below it
- Add-to-cart button in sticky bottom bar

```
Mobile product details:
┌─────────────────────────────┐
│ [← Back]                    │
│                             │
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │    PRODUCT IMAGE        │ │
│ │                         │ │
│ └─────────────────────────┘ │
│                             │
│ Ethiopia Yirgacheffe        │
│ ★★★★★ (12)                  │
│ From 2 490 Ft               │
│                             │
│ Form: [Whole Bean ▼]        │
│ Size: ○ 250g ● 500g ○ 1kg  │
│                             │
│ [description...]            │
│                             │
│ ─── Recommended With ─────  │
│ [V60] [Filter]              │
│                             │
│ ─── Reviews ──────────────  │
│ [review list...]            │
│                             │
├─────────────────────────────┤
│  4 680 Ft  [███ Add to Cart]│  ← sticky bottom bar
└─────────────────────────────┘
```

**Cart:**
- Items in vertical list
- Quantity buttons well-touchable (min 44px)
- Summary sticky at bottom

**Checkout:**
- Steps arranged vertically
- Form fields full width
- "Pay" button sticky at bottom

**Admin:**
- Sidebar -> hamburger drawer
- DataTables horizontally scrollable (must not break!)
- Forms in vertical layout

### General Mobile Rules

1. **Overflow hidden** — nothing should overflow horizontally, no horizontal scroll on the page (except DataTable)
2. **Touch target** — minimum 44x44px for every button, link, checkbox
3. **Font size** — minimum 16px in input fields (iOS zoom prevention)
4. **Safe area** — padding-bottom for sticky elements (iOS bottom bar)
5. **Images** — `object-fit: cover`, fixed aspect ratio, no distortion
6. **Modal/Dialog** — on mobile use full-screen sheet (sliding up from bottom), not a small modal

### Header Mobile (C01)

- Desktop: full navigation bar
- Mobile: hamburger icon → slide-in drawer (no overflow)
- Drawer contains: menu items, language switcher, cart, profile

## Promo Banner

On promo day, appears at the top of the homepage (above hero):

```
┌─────────────────────────────────────────────────────────────┐
│  🎉 CraftBrew turns 1! 20% off everything!           [✕]  │
└─────────────────────────────────────────────────────────────┘
```

- Background color: brand-secondary (#D97706)
- Text: white, font-semibold
- Dismissible (X button), but returns on page reload (session cookie)

## Components

Using shadcn/ui components:
- Button, Card, Badge, Input, Label, Select, Checkbox, RadioGroup
- Dialog (desktop) / Sheet (mobile) — responsive modal
- DropdownMenu, Table, DataTable
- Toast (notifications)
- Separator, Tabs
- Calendar (date picker — subscription, promo day)
- Accordion (FAQ, filters on mobile)
