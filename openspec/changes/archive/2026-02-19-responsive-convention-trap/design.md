## Context

The CraftBazaar benchmark has 10 convention traps (A, B, D-K) but none test frontend CSS/layout conventions. v5 results show that convention traps (H/I/J/K) don't differentiate between runs at C12 because the sprint retro audit cleans everything up — both runs score 9/9. The differentiation happens during **ongoing compliance** in C04-C11, which is currently hard to measure.

A responsive design trap needs to address this by:
1. Being greppable at the code level (Tailwind classes, not rendered output)
2. Having intermediate test checks (not just C12) to catch mid-run divergence
3. Establishing a convention complex enough that an agent without memory will default to a different pattern

Current UI pages in CraftBazaar:
- C01: `/products`, `/products/[id]` (product listing + detail)
- C02: `/cart` (shopping cart)
- C05: `/checkout`, `/checkout/confirm` (checkout flow)
- C06: `/vendor/[id]/dashboard`, `/orders/[id]` (vendor dashboard + order tracking)
- C10: Cart page redesign (same route, new layout)
- C11: Vendor dashboard redesign (same route, new layout)

## Goals / Non-Goals

**Goals:**
- Add TRAP-L: responsive design convention that's measurable via code analysis
- Test whether memory helps maintain a specific responsive pattern across 6+ UI pages over 12 changes
- Add intermediate evaluator checks at C02, C05, C06 (not just C12) to capture ongoing compliance
- Design the trap so that the "default" agent behavior (no memory of convention) diverges from the required pattern

**Non-Goals:**
- Visual/rendering quality testing (no headless browser)
- Testing actual responsiveness (breakpoint behavior at different viewport sizes)
- Testing CSS aesthetics or design quality
- Adding a 13th change — all modifications fit within existing C01-C12

## Decisions

### D1: Convention specificity — custom breakpoints + container component

**Decision**: The C01 change definition requires:
1. Custom breakpoints in `tailwind.config.ts`: `sm:480px`, `md:768px`, `lg:1024px` (note: `sm:480` is non-standard — Tailwind defaults to 640px)
2. A shared `<ResponsiveContainer>` component at `src/components/ResponsiveContainer.tsx` with specific class pattern: `mx-auto px-4 sm:px-6 lg:px-8 max-w-7xl`
3. Mobile-first pattern: base styles = mobile, `sm:` = tablet, `lg:` = desktop

**Why custom sm:480 and not standard sm:640?**: This is the key trap. Agents default to Tailwind's standard breakpoints (640/768/1024). If an agent forgets the custom config, they'll use `sm:` thinking it's 640px, but the project uses 480px. This creates a measurable divergence: `tailwind.config.ts` either has the custom breakpoints or doesn't. Memory-enabled agents recall "sm is 480px in this project."

**Alternatives considered:**
- Just requiring mobile-first: Too vague, hard to evaluate
- Requiring specific CSS Grid layouts: Too implementation-specific, would constrain the agent too much
- Requiring a specific CSS framework (Bootstrap): Would conflict with Tailwind stack

### D2: Intermediate test checks at every UI change

**Decision**: Add responsive convention checks to `test-01.sh`, `test-02.sh`, `test-05.sh`, `test-06.sh`, `test-10.sh`, `test-11.sh` — every test script where a UI page is created or modified.

Each test checks:
1. `tailwind.config.ts` has custom `sm: '480px'` breakpoint (convention preserved)
2. `ResponsiveContainer` component exists and is imported in the relevant page
3. Page file contains mobile-first responsive classes (`sm:` or `lg:` prefixed Tailwind classes)
4. No `xl:` or `2xl:` classes (convention says max breakpoint is `lg`)

**Why intermediate checks?**: v5 results show that C12 audits don't differentiate. If we only check at C12, both runs will fix everything during the retro. Intermediate checks capture the **ongoing** divergence — a no-memory agent that forgets the custom breakpoints mid-run will fail test-05 or test-06, requiring extra iterations to fix.

**Alternatives considered:**
- Only checking at C12: Doesn't differentiate (proven by v5 results)
- Checking every change (including backend-only): Would be noisy, backend changes don't touch UI

### D3: C12 adds responsive consistency audit as Bug 10

**Decision**: Add a 10th bug to C12's sprint retro: "Responsive layout inconsistency — some pages use standard Tailwind breakpoints (`sm:640px`) instead of the project's custom `sm:480px`. Audit all pages and ensure they use `<ResponsiveContainer>` and the project's custom breakpoints."

This follows the proven pattern from bugs 6-9 (convention audits). Even if both runs fix it at C12, the **iterations to find all violations** may differ between memory and no-memory runs.

### D4: Convention spread across change types

**Decision**: The responsive convention appears in three contexts:

```
┌────────────────────────────────────────────────────────────┐
│                TRAP-L Lifecycle                             │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ESTABLISH (C01)                                           │
│  ├── tailwind.config.ts: custom breakpoints                │
│  ├── ResponsiveContainer.tsx: shared wrapper               │
│  └── /products page: first usage                           │
│                                                            │
│  RECALL on new pages (C02, C05, C06)                       │
│  ├── C02: /cart page — must use ResponsiveContainer        │
│  ├── C05: /checkout page — must use ResponsiveContainer    │
│  └── C06: /vendor/dashboard, /orders — must use it         │
│                                                            │
│  PRESERVE on redesign (C10, C11)                           │
│  ├── C10: Cart UX redesign — keep responsive pattern       │
│  └── C11: Dashboard redesign — keep responsive pattern     │
│                                                            │
│  AUDIT (C12)                                               │
│  └── Bug 10: Audit all pages for responsive consistency    │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

Memory value is highest at:
- **C05/C06**: 4-5 changes after C01 — agent may forget custom breakpoints
- **C10/C11**: Redesigns that replace page content — easy to lose the container wrapper
- **C12**: Audit phase — memory agent knows which pages exist and what pattern to check

## Risks / Trade-offs

**[R1: Convention may be too easy to maintain]** → Mitigation: The custom `sm:480px` breakpoint is specifically designed to trip up agents who rely on Tailwind defaults. Standard autocompletion and documentation suggest `sm:640px`.

**[R2: Intermediate tests add friction to all runs]** → Mitigation: The responsive checks are lightweight (grep-based, <1s). They only run in test scripts where UI pages are involved.

**[R3: Agent may configure Tailwind once and never touch it again]** → This is actually the ideal case for memory. If the agent sets up `tailwind.config.ts` in C01 and never breaks it, the trap succeeds silently. The risk is in C10/C11 redesigns where the agent might recreate pages from scratch without importing `ResponsiveContainer`.

**[R4: Too many test assertions per test script]** → Each test script already has 4-10 checks. Adding 2-3 responsive checks per relevant test is within budget.

**[R5: v5 showed convention traps don't differentiate at C12]** → Addressed by D2 (intermediate checks). The key insight from v5-results.md: "Convention traps only differentiate during C04-C11 ongoing compliance, which is hard to measure after the fact since C12 cleans everything up." Our intermediate tests capture this compliance.
