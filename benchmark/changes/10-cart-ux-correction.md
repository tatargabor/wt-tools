# Change 10: Cart Page UX Correction

## Agent Input

### Overview

The design team has reviewed the cart page built in Change 02 and identified specific UX problems. This change implements their corrections.

### Background

The cart page from C02 works functionally but doesn't meet UX standards. The design team has provided specific corrections based on their review.

### Requirements

1. **Inline quantity editing**: Item quantities must be editable directly in the cart list — using an inline number input or increment/decrement buttons. There must NOT be a modal, popup, or separate page for editing quantities. The quantity change should take effect immediately (no separate "save" action needed).

2. **Toast notification on removal**: When a user removes an item from the cart, show a brief toast notification (e.g., "Item removed from cart"). Do NOT use `window.confirm()` or any confirmation dialog before removal. The removal should be immediate with an undo option in the toast.

3. **Real-time cart total**: The cart total must update immediately as quantities change. There must NOT be an "Update cart" or "Recalculate" button. Changes are saved and totals recalculated automatically on every quantity adjustment.

4. **Empty cart CTA**: When the cart is empty, display a prominent call-to-action button linking to `/products` (e.g., "Start Shopping" or "Browse Products"). It must be an actual `<a>` tag or `Link` component with `href="/products"`, not just plain text saying "Your cart is empty."

### Acceptance Criteria

- [ ] Quantities editable inline (no modal, no separate page)
- [ ] No `confirm()` dialog calls in cart page JavaScript
- [ ] Toast notification shown on item removal
- [ ] Cart total updates in real-time (no "Update" button)
- [ ] No submit button with text matching "update" on the cart page
- [ ] Empty cart has a link/button to /products
- [ ] Cart page still functions correctly (add, remove, update quantities)

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T10.1: Reintroducing the "Update cart" button (repeat-failure trap)**
The "Update cart" button is the standard cart pattern in most e-commerce tutorials and templates. When the agent restructures the cart page for inline editing, it's very likely to add an "Update cart" button because that's the default pattern. The specific requirement says NO update button — totals update in real-time.

**Memory prediction**: HIGH VALUE for repeat failures. If the test fails on the first try (agent adds Update button), the memory-enabled agent should remember "design team specifically rejected Update button, wants real-time totals." Without memory, the agent might fix the button but introduce it again in another form.

**T10.2: Adding confirm() dialog (common pattern)**
When implementing "remove item," the natural reflex is to add `if (confirm("Are you sure?"))`. The requirement explicitly says NO confirm dialog — use a toast with undo instead.

**Memory prediction**: Medium value. This is a single-check test, but the confirm() pattern is so ingrained that even after fixing, it might be reintroduced during refactoring.

**T10.3: Empty cart CTA must be a real link**
The agent might render "Your cart is empty. Browse products." as plain text without a clickable link. The requirement specifies a `<a href="/products">` or equivalent.

**Memory prediction**: Low value but easy to miss on first try.

### Scoring Focus

- Did the agent add an "Update cart" button? (Common trap)
- Did the agent use confirm() for removal? (Common pattern)
- Does the empty cart have a real link to /products?
- How many test iterations to pass test-10.sh?

### Expected Memory Interactions (Run B)

- **Recall**: C02 cart page implementation — component structure and file location (HIGH VALUE)
- **Recall**: What specific corrections were requested (CRITICAL for avoiding repeat failures)
- **Save**: "No Update button — real-time totals" design decision
- **Save**: "No confirm() — toast with undo" design decision
- **Save**: "Empty cart must have link to /products" requirement
