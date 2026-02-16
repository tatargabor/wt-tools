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

**T11.3: Pagination implementation**
Adding pagination to a Next.js page requires either client-side pagination (filter/slice the array) or server-side (query params). The agent needs to choose and implement consistently.

**Memory prediction**: Low value — this is a standard implementation task.

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
