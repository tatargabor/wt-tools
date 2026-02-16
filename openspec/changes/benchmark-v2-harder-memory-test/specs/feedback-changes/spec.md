## ADDED Requirements

### Requirement: Change 10 — Cart page UX correction
Create `benchmark/changes/10-cart-ux-correction.md` that specifies design corrections to C02's cart page.

Agent input must list 4 specific corrections:
1. Inline quantity editing (no modal/separate page)
2. Toast notification on item removal (no confirm dialog)
3. Real-time cart total update (no "Update cart" button)
4. Empty cart shows CTA button to /products (not just text)

Evaluator notes must specify:
- **Memory prediction**: Agent should recall C02's cart page implementation and know exactly which components to modify
- **Repeat-failure trap**: The "Update cart" button is a common cart pattern. Without memory of "they specifically rejected this," the agent is likely to reintroduce it when restructuring the page.
- **Measurable**: `test-10.sh` checks for absence of confirm() calls, absence of "Update" submit button, presence of /products link

#### Scenario: Test catches reintroduced pattern
- **WHEN** agent implements C10 but adds an "Update cart" button (common pattern)
- **THEN** test-10.sh fails with "FAIL: found submit button matching 'update'"
- **AND** agent must fix in follow-up iteration, ideally remembering the specific requirement

---

### Requirement: Change 11 — Vendor dashboard redesign
Create `benchmark/changes/11-vendor-dashboard-redesign.md` that replaces C06's tabbed dashboard with a flat list.

Agent input must specify:
1. Remove tab/panel grouping — single flat list sorted by date
2. Status as colored badge (not tab header)
3. Buyer email (not session ID) per row
4. Action buttons in dropdown menu (not individual buttons)
5. Pagination (10 items per page)

Evaluator notes must specify:
- **Memory prediction**: Agent should recall C06's tabbed layout with status groups and know the full component structure to replace
- **Counter-pattern trap**: The correction is OPPOSITE to what C06 specified. Without memory, agent might try to "enhance" the tabs instead of removing them.
- **Measurable**: `test-11.sh` checks for absence of tab components, presence of pagination controls, badge CSS classes

#### Scenario: Agent preserves tabs instead of removing
- **WHEN** agent "redesigns" but keeps tabs with badges added
- **THEN** test-11.sh fails with "FAIL: found tab/panel component in dashboard"
