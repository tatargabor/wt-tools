## 1. C01 — Establish Responsive Convention

- [x] 1.1 Add responsive design requirements to `benchmark/changes/01-product-catalog.md` Agent Input section: custom breakpoints in `tailwind.config.ts` (`sm:480px`, `md:768px`, `lg:1024px`), `ResponsiveContainer` component, mobile-first pattern, no `xl:`/`2xl:`
- [x] 1.2 Add TRAP-L evaluator notes to `benchmark/changes/01-product-catalog.md`: trap description, memory predictions, expected memory interactions (Save: custom breakpoints, ResponsiveContainer convention)
- [x] 1.3 Add responsive convention checks to `benchmark/tests/test-01.sh`: check `tailwind.config.ts` for `480`, check `ResponsiveContainer.tsx` exists, check products page imports it

## 2. C02 — Recall on Cart Page

- [x] 2.1 Add responsive requirement to `benchmark/changes/02-shopping-cart.md` Agent Input: "Wrap cart page in `<ResponsiveContainer>`. Use project's custom Tailwind breakpoints."
- [x] 2.2 Add TRAP-L evaluator notes to `benchmark/changes/02-shopping-cart.md`: recall test, memory prediction (agent should recall convention from C01)
- [x] 2.3 Add responsive checks to `benchmark/tests/test-02.sh`: check cart page imports `ResponsiveContainer`, check `tailwind.config.ts` still has `480`

## 3. C05 — Recall on Checkout Pages

- [x] 3.1 Add responsive requirement to `benchmark/changes/05-checkout.md` Agent Input: "Wrap checkout and confirmation pages in `<ResponsiveContainer>`. Use project's custom Tailwind breakpoints."
- [x] 3.2 Add TRAP-L evaluator notes to `benchmark/changes/05-checkout.md`: recall test after 4 changes
- [x] 3.3 Add responsive checks to `benchmark/tests/test-05.sh`: check checkout page(s) import `ResponsiveContainer`

## 4. C06 — Recall on Dashboard and Order Pages

- [x] 4.1 Add responsive requirement to `benchmark/changes/06-order-workflow.md` Agent Input: "Wrap vendor dashboard and order tracking pages in `<ResponsiveContainer>`. Use responsive grid (single column on mobile, multi-column on `lg:`)."
- [x] 4.2 Add TRAP-L evaluator notes to `benchmark/changes/06-order-workflow.md`: recall test, multi-page convention adherence
- [x] 4.3 Add responsive checks to `benchmark/tests/test-06.sh`: check dashboard and orders pages import `ResponsiveContainer`

## 5. C10 — Preservation on Cart Redesign

- [x] 5.1 Add TRAP-L evaluator notes to `benchmark/changes/10-cart-ux-correction.md`: preservation test — agent must maintain ResponsiveContainer during cart redesign (NOT re-stated in requirements)
- [x] 5.2 Add responsive checks to `benchmark/tests/test-10.sh`: check redesigned cart page still imports `ResponsiveContainer`, check `tailwind.config.ts` still intact

## 6. C11 — Preservation on Dashboard Redesign

- [x] 6.1 Add TRAP-L evaluator notes to `benchmark/changes/11-vendor-dashboard-redesign.md`: preservation test — agent must maintain ResponsiveContainer during dashboard redesign (NOT re-stated in requirements)
- [x] 6.2 Add responsive checks to `benchmark/tests/test-11.sh`: check redesigned dashboard still imports `ResponsiveContainer`, check no `xl:`/`2xl:` introduced

## 7. C12 — Audit Bug and Retro

- [x] 7.1 Add Bug 10 to `benchmark/changes/12-sprint-retro.md` Agent Input: "Responsive layout inconsistency — audit all pages for `ResponsiveContainer` usage and custom breakpoints"
- [x] 7.2 Add TRAP-L evaluator notes to `benchmark/changes/12-sprint-retro.md`: audit scope, memory prediction for file locations
- [x] 7.3 Add responsive checks to `benchmark/tests/test-12.sh` (or update existing): all pages use `ResponsiveContainer`, no `xl:`/`2xl:`, `tailwind.config.ts` has custom breakpoints

## 8. Scoring Rubric and Documentation

- [x] 8.1 Add TRAP-L section to `benchmark/scoring-rubric.md`: scoring table (C01 creation, C02/C05/C06 recall, C10/C11 preservation, C12 audit), intermediate failure counting
- [x] 8.2 Update `benchmark/project-spec.md` if needed: mention `ResponsiveContainer` component in project structure, add `sm:480px` convention to tech stack notes
