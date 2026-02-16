# Change 06: Order Status Workflow

## Agent Input

### Overview

Add a per-vendor order status workflow with a state machine. Each sub-order progresses through statuses independently. Vendors manage their sub-orders from a dashboard, and buyers track their full order status.

### Requirements

1. **Status state machine**: Each sub-order follows this status flow:
   ```
   pending → confirmed → shipped → delivered
                ↘ cancelled
   ```
   - Valid transitions:
     - `pending` → `confirmed` (vendor accepts the sub-order)
     - `pending` → `cancelled` (vendor or buyer cancels)
     - `confirmed` → `shipped` (vendor ships the items)
     - `confirmed` → `cancelled` (vendor cancels before shipping)
     - `shipped` → `delivered` (delivery confirmed)
   - Invalid transitions must be rejected with a clear error

2. **Status update API**:
   - `PUT /api/sub-orders/[id]/status` — Update sub-order status
     - Validate the transition is allowed
     - Record timestamp for each status change
     - Body: `{ status: "confirmed" | "shipped" | "delivered" | "cancelled" }`
   - `GET /api/sub-orders/[id]` — Get sub-order with status history

3. **Status history model**: Add to Prisma schema:
   - `StatusHistory`: `id`, `subOrderId`, `fromStatus`, `toStatus`, `changedAt`, `changedBy` (vendor or system)

4. **Parent order status derivation**:
   - The parent order's status is derived from its sub-orders:
     - All sub-orders `pending` → order is `pending`
     - Any sub-order `confirmed` → order is `processing`
     - All sub-orders `shipped` or `delivered` → order is `shipped`
     - All sub-orders `delivered` → order is `delivered`
     - All sub-orders `cancelled` → order is `cancelled`
     - Mix of statuses → order is `partially_fulfilled`

5. **Vendor dashboard**:
   - Page at `/vendor/[id]/dashboard` showing:
     - Pending sub-orders (need confirmation)
     - Active sub-orders (confirmed, shipped)
     - Completed sub-orders (delivered, cancelled)
     - Status update buttons (confirm, ship, mark delivered, cancel)
   - Sub-order detail showing items, buyer info, and status history

6. **Buyer order tracking**:
   - Update `/orders/[id]` page to show:
     - Overall order status (derived)
     - Per-vendor sub-order status with timeline
     - Status history for each sub-order

7. **Responsive layout**: Wrap the vendor dashboard and order tracking pages in `<ResponsiveContainer>` (from `src/components/ResponsiveContainer.tsx`). Use responsive grid: single column on mobile, multi-column on `lg:`. Use the project's custom Tailwind breakpoints (`sm:`, `md:`, `lg:` — no `xl:` or `2xl:`).

8. **Real-time status updates** (optional enhancement):
   - Use Server-Sent Events (SSE) to push status changes to the buyer's order page
   - `GET /api/orders/[id]/events` — SSE endpoint
   - Falls back to polling if SSE is not implemented

### Acceptance Criteria

- [ ] Sub-order status transitions follow the defined state machine
- [ ] Invalid transitions are rejected with appropriate error messages
- [ ] Status history is recorded for every transition
- [ ] Parent order status correctly derives from sub-order statuses
- [ ] Vendor dashboard shows sub-orders grouped by status
- [ ] Vendor can update sub-order status from dashboard
- [ ] Buyer order page shows per-vendor status and timeline
- [ ] Seed data or test scenario demonstrates a full status flow

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps

**T6.1: State machine depends on C3 order architecture (THE ultimate payoff)**
This is where C3's architectural decision has its greatest impact:

- **If C3 used nested orders (parent + sub-orders)**: The state machine is straightforward. Each SubOrder already has its own status field. The vendor dashboard queries sub-orders by vendorId. The buyer view groups sub-orders under their parent order. Everything works cleanly.

- **If C3 used flat orders**: MASSIVE rework needed. Flat orders have one status per order, but this change requires per-vendor status tracking. The agent must either:
  a. Refactor to nested orders (design rework, migration, API changes — essentially redoing C3)
  b. Add a separate status tracking layer on top of flat orders (fragile, complex)
  c. Reinterpret "flat orders" to already be per-vendor (but then buyer order grouping breaks)

**Memory prediction**: ULTIMATE payoff moment. A memory-enabled agent recalls "we used parent Order → SubOrder architecture from C3" and proceeds directly. Without memory, the agent must re-discover the order model, and if it was flat, faces the biggest rework of the benchmark. The delta between Run A and Run B is likely largest on this change.

**T6.2: Transition validation**
The state machine seems simple but has edge cases:
- What if a vendor tries to ship a cancelled order?
- What if delivery is marked before shipping?
- The validation must be strict (whitelist valid transitions, not blacklist invalid ones)

Implementing as a whitelist (map of `fromStatus → [allowedToStatuses]`) is clean. Implementing as ad-hoc if/else chains leads to bugs.

**Memory prediction**: Low-value save. The pattern is standard, but the specific whitelist approach might be worth saving.

**T6.3: Next.js App Router + SSE patterns**
Server-Sent Events in Next.js App Router require specific patterns:
- Use `ReadableStream` in Route Handlers
- The response must have `Content-Type: text/event-stream`
- Connection management is tricky (detecting client disconnect)
- App Router's edge runtime vs Node.js runtime affects SSE support

This is an optional enhancement, so the agent may skip it. If attempted, it's a known pain point.

**Memory prediction**: Medium-value save if attempted. "Next.js App Router SSE uses ReadableStream in route handlers" is useful if the project grows.

**T6.4: Responsive convention recall (TRAP-L recall test — 5 changes after C01)**
C06 requires `<ResponsiveContainer>` on both the vendor dashboard and order tracking pages. This is 5 changes after C01 — the longest distance yet. The agent must recall custom breakpoints (`sm:480px`) and use responsive grid (single column mobile, multi-column desktop).

**Memory prediction**: HIGH VALUE recall. Memory-enabled agent recalls "sm is 480px, use ResponsiveContainer." Without memory, the agent may use standard breakpoints or no responsive wrapper on the dashboard.

**T6.5: Status change feedback pattern (TRAP-N drift point)**
When a vendor clicks "Confirm" or "Ship" on a sub-order, the UI must show some feedback. The change def says "status update buttons" but doesn't specify what happens after clicking. The agent will choose a pattern: `window.alert("Order confirmed")`, inline status change with visual feedback, page refresh, toast, or nothing visible.

**Evaluator action**: Document the feedback pattern used for vendor status changes. Compare with C02 (cart removal) and C05 (checkout error). Count how many different patterns exist so far. This divergence feeds into TRAP-N.

**Memory prediction**: Low direct value but HIGH at C12. Memory-enabled agent's code map knows "C02 used alert, C05 used inline error, C06 used page refresh" — making the C12 Toast unification straightforward. Without memory, the agent must search each page to discover the pattern.

### Scoring Focus

- **Critical**: How much rework was needed based on C3's order architecture? (This is the key metric)
- Did the state machine use a whitelist approach?
- Did the agent recall the order model or have to re-discover it?
- How many iterations for the vendor dashboard?

### Expected Memory Interactions (Run B)

- **Recall**: Order architecture (from C3) — CRITICAL, determines this change's difficulty (ULTIMATE VALUE)
- **Recall**: Prisma migration patterns (from C3) — for adding StatusHistory
- **Recall**: SQLite WAL mode (from C2) — status updates are concurrent writes
- **Recall**: Next.js .env.local patterns (from C5) — if SSE needs config
- **Save**: State machine implementation pattern (whitelist approach)
- **Save**: Parent status derivation logic
- **Save**: SSE pattern for Next.js App Router (if implemented)
- **Save**: Status change feedback pattern (code-map detail for TRAP-N)
- **Recall**: ResponsiveContainer convention from C01 (TRAP-L)
- **Recall**: Custom sm:480px breakpoint from C01 (TRAP-L)
