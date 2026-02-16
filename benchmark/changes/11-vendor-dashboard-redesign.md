# Change 11: Vendor Dashboard Redesign

## Agent Input

### Overview

The business team wants to replace the tabbed vendor dashboard from Change 06 with a simpler flat list design. The current tabbed layout (grouping sub-orders by status into pending/active/completed tabs) is being removed entirely.

### Background

In C06, the vendor dashboard at `/vendor/[id]/dashboard` groups sub-orders into tabs by status (Pending, Active, Completed). The business team has decided this layout doesn't work well — vendors want to see everything in chronological order with status as a visual indicator, not a filter.

### Requirements

1. **Remove tab/panel grouping**: Delete the tab-based layout completely. No `<Tab>`, `<TabPanel>`, `<TabList>`, or equivalent components should remain in the vendor dashboard. Replace with a single flat list.

2. **Single sorted list**: Display all sub-orders in a single list, sorted by date (most recent first). Each row shows:
   - Order date
   - Buyer email (not buyer session ID — resolve the buyer's email if available, or show "Guest" if anonymous)
   - Items summary (e.g., "3 items, $45.99")
   - Status as a colored badge

3. **Status badges**: Render status as a colored badge element. The badge must use CSS classes containing the word "badge" (e.g., `badge badge-pending`, `status-badge`). Colors:
   - Pending: yellow/amber
   - Confirmed: blue
   - Shipped: purple
   - Delivered: green
   - Cancelled: red/gray

4. **Dropdown actions**: Replace individual action buttons (Confirm, Ship, Deliver, Cancel) with a single dropdown/menu per row. The dropdown shows only valid actions based on current status.

5. **Pagination**: Display 10 items per page with pagination controls:
   - Previous/Next buttons
   - Page number display (e.g., "Page 1 of 5")
   - Must have elements identifiable as pagination controls (buttons or links with "prev"/"next" or page numbers)

### Acceptance Criteria

- [ ] No tab or panel components in vendor dashboard HTML
- [ ] Single flat list sorted by creation date (descending)
- [ ] Buyer email shown per row (not session ID)
- [ ] Status rendered as badge with appropriate CSS classes
- [ ] Action buttons in dropdown menu (not individual buttons)
- [ ] Pagination with 10 items per page
- [ ] Pagination controls present (prev/next or page numbers)
- [ ] All status transitions still work via dropdown actions

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T11.1: Keeping tabs instead of removing them (counter-pattern trap)**
The agent built the tabbed layout in C06. Without memory of "they specifically want NO tabs," the agent might interpret "redesign" as "enhance the tabs" — adding badges to tab headers, adding pagination per tab, etc. The requirement is to REMOVE tabs entirely.

**Memory prediction**: HIGH VALUE for counter-pattern detection. Memory-enabled agent recalls "C06 used tabs, C11 says remove tabs completely." Without memory, the agent might default to enhancing the existing pattern rather than replacing it.

**T11.2: Session ID vs email**
C06 likely used `buyerSessionId` (from C03's Order model) since there's no user authentication. The redesign asks for buyer EMAIL, which may not exist in the data model. The agent needs to decide: add an email field to Order? Use a placeholder? Show "Guest"?

**Memory prediction**: Medium value. This tests whether the agent understands the data model limitations.

**T11.3: Pagination convention recall (TRAP-I payoff)**
C01 established the `{ data, total, page, limit }` pagination format. The vendor dashboard's API endpoint must use the same format. If the agent recalls this convention, implementation is straightforward. If not, the agent may implement a different pagination approach (client-side slicing, or a different API shape), which fails the C12 consistency check.

**Memory prediction**: HIGH VALUE recall for TRAP-I. Memory-enabled agent recalls "all list endpoints use { data, total, page, limit } with ?page=&limit= query params" from C01 and applies it. Without memory, may implement ad-hoc pagination.

**T11.4: Responsive convention preservation (TRAP-L preservation test)**
C11 redesigns the vendor dashboard but does NOT re-state the responsive convention. The agent must PRESERVE the `<ResponsiveContainer>` wrapper during the redesign. If the agent rewrites the dashboard from scratch (which is likely given the tab→flat list transformation), they may forget the responsive wrapper.

**Memory prediction**: HIGH VALUE preservation test. Memory-enabled agent recalls "dashboard uses ResponsiveContainer" from C06. Without memory, the agent is rebuilding the entire page layout and may omit the responsive wrapper.

**T11.5: Pagination UI specification and reuse opportunity (TRAP-M key moment)**
C11 explicitly requires "10 items per page with pagination controls: Previous/Next buttons, Page number display." This is the first change with a SPECIFIC pagination UI requirement. The critical observation: did the agent create a reusable `<Pagination>` component or build ad-hoc pagination inline?

**Evaluator action**: Document whether the pagination implementation is reusable or ad-hoc. Compare the pagination UI with C01's `/products` and C03's `/vendors`/`/orders`. Count how many DIFFERENT pagination implementations exist. This divergence is the setup for C12 Bug 10.

**Memory prediction**: HIGH VALUE for code-map. Memory-enabled agent might recall "in C01 I built Prev/Next buttons, in C03 I built page numbers" and consider extracting a shared component. Without memory, the agent builds another ad-hoc implementation.

### Scoring Focus

- Did the agent REMOVE tabs or try to enhance them? (Critical counter-pattern test)
- Are status badges present with proper CSS classes?
- Does pagination work with proper controls?
- How many test iterations to pass test-11.sh?

### Expected Memory Interactions (Run B)

- **Recall**: C06 dashboard implementation — component file, tab structure (HIGH VALUE)
- **Recall**: "Remove tabs, use flat list" — the counter-pattern decision (CRITICAL)
- **Recall**: Order/SubOrder data model from C03 — what buyer info is available
- **Save**: "Flat list with badges, no tabs" dashboard design decision
- **Save**: Pagination approach chosen
- **Save**: Pagination UI reusability (shared component vs ad-hoc — code-map for TRAP-M)
- **Recall**: ResponsiveContainer convention — preserve during redesign (TRAP-L)
- **Recall**: Prior pagination implementations from C01, C03 (TRAP-M)
