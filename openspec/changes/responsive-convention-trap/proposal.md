## Why

The benchmark has 10 convention traps (A, B, D-K) but none test frontend/CSS conventions. Responsive design is a high-value convention trap because it's established once (breakpoints, mobile-first pattern) and must be maintained across every UI page — product listing, cart, checkout, dashboard. An agent that forgets the convention will use inconsistent breakpoints or desktop-first patterns, creating a measurable divergence that's easy to evaluate with code-level grep checks (no browser rendering needed).

## What Changes

- Add **TRAP-L: Responsive breakpoint convention** to the CraftBazaar benchmark
  - C01 establishes the convention: mobile-first Tailwind with custom breakpoints `sm:640px`, `md:768px`, `lg:1024px` in `tailwind.config.ts`, plus a shared responsive container component
  - C02, C05, C06 each add new UI pages that must follow the convention
  - C10, C11 redesign existing pages — must maintain the responsive pattern
  - C12 adds a consistency audit: grep all pages for responsive class usage, flag inconsistent breakpoints or desktop-first patterns
- Add evaluator checks to `test-*.sh` scripts for responsive convention compliance
- Update `scoring-rubric.md` with TRAP-L scoring criteria

## Capabilities

### New Capabilities
- `responsive-convention-trap`: TRAP-L definition — responsive design convention for the CraftBazaar benchmark. Covers: convention establishment in C01, convention recall in C02/C05/C06, convention preservation in C10/C11, and consistency audit in C12.

### Modified Capabilities

## Impact

- Modified files: `benchmark/changes/01-product-catalog.md` (add responsive requirements), `benchmark/changes/02-shopping-cart.md`, `benchmark/changes/05-checkout.md`, `benchmark/changes/06-order-workflow.md`, `benchmark/changes/10-cart-ux-correction.md`, `benchmark/changes/11-vendor-dashboard-redesign.md`, `benchmark/changes/12-sprint-retro.md` (add audit bug)
- Modified files: `benchmark/scoring-rubric.md` (add TRAP-L section), `benchmark/tests/test-01.sh` through `test-12.sh` (add responsive checks)
- No runtime code changes — all modifications are within the benchmark definition and evaluator
