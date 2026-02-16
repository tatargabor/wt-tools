## Context

The CraftBazaar benchmark tests memory value across 12 changes. Convention traps (H-K) establish a rule and check compliance. This change introduces a NEW trap type: **implementation drift** — no rule is stated, the agent naturally diverges across pages, and a later change asks for unification.

The key difference from convention traps:

```
Convention trap:        C01: "Use X pattern"  → C04: Did you use X? → PASS/FAIL
Implementation drift:   C01: Build freely     → C03: Build freely  → C12: "Unify!" → HOW MUCH WORK?
```

Memory value is different too:
- Convention trap: memory stores a RULE ("always use formatPrice")
- Implementation drift: memory stores IMPLEMENTATION DETAILS ("C01 products page uses < Prev | Next > buttons, C03 orders page uses page numbers")

This tests the **code map** memory type that v5 introduced but only achieved 33% coverage on.

## Goals / Non-Goals

**Goals:**
- Add TRAP-M (Pagination UI) and TRAP-N (Notification/feedback) to the benchmark
- Design traps so divergence happens NATURALLY (no forced wrong path)
- Measure how many iterations the unification takes (memory vs no-memory)
- Evaluator notes document what to look for at each change

**Non-Goals:**
- Not adding new changes (C13, C14) — everything fits within existing C01-C12
- Not prescribing HOW each page should implement the feature (that's the point — agent chooses freely)
- Not testing visual quality of the unified component

## Decisions

### D1: TRAP-M — Pagination UI Divergence

**Lifecycle:**

```
┌────────────────────────────────────────────────────────────────┐
│  TRAP-M: Pagination UI                                         │
│                                                                │
│  C01: /products page (list endpoint has { data, total, page }) │
│       Agent builds SOME pagination UI                          │
│       Common patterns: "< Prev | Next >",                     │
│       "Load More" button, infinite scroll, nothing             │
│       EVALUATOR: Document what pattern was used                │
│                                                                │
│  C03: /vendors, /orders pages (new list endpoints)             │
│       Agent builds pagination UI AGAIN                         │
│       Likely different from C01 (different context, no memory) │
│       EVALUATOR: Document if same or different from C01        │
│                                                                │
│  C06: /vendor/[id]/dashboard (sub-orders by status)            │
│       Tab-based grouping — may or may not have pagination      │
│       EVALUATOR: Document if pagination exists                 │
│                                                                │
│  C11: Dashboard redesign — EXPLICITLY requires:                │
│       "10 items per page, Previous/Next buttons,               │
│        Page number display (e.g., 'Page 1 of 5')"             │
│       This is the FIRST explicit pagination UI spec            │
│       EVALUATOR: Did agent create reusable component or        │
│       ad-hoc implementation?                                   │
│                                                                │
│  C12: Bug 10: "Create a shared <Pagination> component at      │
│       src/components/Pagination.tsx. Replace all ad-hoc        │
│       pagination UI across the app."                           │
│       MEMORY AGENT: Knows exactly which pages have pagination  │
│       and what each looks like                                 │
│       NO-MEMORY: Must search all pages, figure out what        │
│       each does, then replace                                  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**Why this works:**
- TRAP-I already ensures the API returns `{ data, total, page, limit }` everywhere
- But NO convention specifies the UI component
- The agent naturally implements pagination UI differently per page
- C11's explicit pagination spec forces ONE specific format, but only for the dashboard
- C12 unification requires finding ALL pagination UIs and replacing them

**Evaluation method:**
- C12 test checks: `Pagination.tsx` exists, all list pages import it, no inline prev/next buttons outside the component
- Iteration count for C12 Bug 10 (memory agent should need fewer iterations)

### D2: TRAP-N — Notification/Feedback Divergence

**Lifecycle:**

```
┌────────────────────────────────────────────────────────────────┐
│  TRAP-N: Notification / User Feedback                          │
│                                                                │
│  C02: Cart item removal                                        │
│       Agent must show some feedback when item is removed       │
│       Common patterns: window.alert(), inline "Removed!" text, │
│       console.log(), nothing                                   │
│       (C02 doesn't specify HOW to show feedback)               │
│       EVALUATOR: Document what pattern was used                │
│                                                                │
│  C05: Checkout error/success                                   │
│       Payment fails → show error to user                       │
│       Payment succeeds → redirect to confirmation              │
│       Common patterns: inline error div, alert(), redirect     │
│       EVALUATOR: Document error display pattern                │
│                                                                │
│  C06: Status update feedback                                   │
│       Vendor clicks "Confirm" → needs feedback                 │
│       Common patterns: alert("Order confirmed"), page refresh, │
│       inline status change, nothing                            │
│       EVALUATOR: Document feedback pattern                     │
│                                                                │
│  C10: Cart UX Correction — EXPLICITLY requires:                │
│       "Toast notification on removal. NO window.confirm().     │
│        Toast with undo option."                                │
│       This is the FIRST explicit notification spec             │
│       Agent builds a toast system (but only for cart)          │
│       EVALUATOR: Did agent build reusable toast or ad-hoc?     │
│                                                                │
│  C12: Bug 11: "Inconsistent user feedback — some pages use     │
│       alert(), some use inline messages, and the cart uses a   │
│       toast. Create a shared notification/toast system at      │
│       src/components/Toast.tsx and replace all ad-hoc feedback  │
│       patterns."                                               │
│       MEMORY AGENT: Knows C02 used alert(), C05 used inline,  │
│       C06 used alert(), C10 introduced toast — 3 places to fix │
│       NO-MEMORY: Must search entire codebase for alert(),      │
│       inline messages, find what each page does                │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**Why this works:**
- Feedback patterns are inherently invisible to automated tests until you look for them
- The agent's default varies by context (alert for destructive, inline for errors, nothing for success)
- C10 introduces the "correct" pattern (toast) but only for ONE page
- C12 asks "now use toast everywhere" — the drift is already baked in

**Evaluation method:**
- C12 test checks: `Toast.tsx` exists, no `window.alert(` or `window.confirm(` anywhere in `src/`, all pages import the shared toast
- Iteration count for C12 Bug 11

### D3: No explicit instruction before C12 — the divergence must be natural

**Critical design decision**: We do NOT add any instruction to C01, C02, C03, C05, C06 that says "use a shared component." The whole point is that the agent builds each page independently and naturally uses different patterns.

We ONLY add:
- **Evaluator notes** (invisible to agent) documenting what to look for
- **C11** already has explicit pagination requirements (this is fine — it's one page)
- **C10** already has explicit toast requirements (this is fine — it's one page)
- **C12** asks for unification (this is the trap trigger)

**Alternatives considered:**
- Requiring a shared component from C01: This would make it a convention trap (like TRAP-H), not a drift trap
- Testing drift without unification: No measurable outcome, just observation
- Adding a C13 for unification: Unnecessary, C12 sprint retro is the natural place for cross-cutting fixes

### D4: Changes to C12 — two new bugs (10 and 11)

C12 currently has 9 bugs. We add two more:

| Bug # | Title | What to Fix |
|-------|-------|-------------|
| 10 | Pagination UI inconsistency | Create `src/components/Pagination.tsx`, replace all ad-hoc pagination UI |
| 11 | User feedback inconsistency | Create `src/components/Toast.tsx`, replace all alert()/inline feedback with toast |

Both follow the existing C12 pattern: "audit the codebase for X, create shared utility, fix all instances."

The memory advantage: the agent doesn't just need to know WHAT to fix — they need to know WHERE each page implemented its own version.

## Risks / Trade-offs

**[R1: Agent might create shared components spontaneously]** → This is actually fine. If the agent builds `<Pagination>` in C01 and reuses it in C03, there's no drift — and no Bug 10 work needed at C12. This scenario is a natural "memory doesn't matter because the agent was proactive." Score it as 0 iterations (best case for both runs).

**[R2: Agent might use exactly the same ad-hoc pattern everywhere]** → Unlikely but possible. Even if the code is similar, without a shared component, C12 still requires creating one and consolidating. The iteration difference comes from knowing what files to touch.

**[R3: C12 is getting large (11 bugs)]** → This is intentional. C12 is designed to be the hardest change and the biggest memory differentiator. Each additional bug adds a few minutes to the run. 11 bugs is still manageable in the `--max 15` iteration budget.

**[R4: Drift traps overlap with code map memories]** → Yes, and this is a FEATURE. Code map memories (v5: 33% coverage) are exactly what would help with drift traps. If v6 achieves better code map coverage, drift traps will show a larger memory advantage.

**[R5: Notification pattern might not diverge]** → If the agent consistently uses one pattern (e.g., always `alert()`), the unification is simpler but still requires creating a toast system and replacing all `alert()` calls. The iteration count still favors the memory agent who knows the exact locations.
