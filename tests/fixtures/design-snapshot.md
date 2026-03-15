## Design Tokens

Colors:
- background: bg-white
- foreground: text-gray-900
- primary: bg-blue-600
- destructive: bg-red-600
- accent: bg-gray-100
- border: border-gray-200
- muted: text-gray-500

Typography:
- h1: text-3xl font-bold
- h2: text-2xl font-semibold
- base-font: text-sm

Spacing:
- section-gap: space-y-8
- card-padding: p-4

Shadows:
- card: shadow-sm

## Component Hierarchy

### Product Catalog (/)
- Navbar → Logo, SearchBar, CartLink(ShoppingBag icon)
- ProductGrid → ProductCard[] → Image, Title, ShortDescription, Price, AddToCart
