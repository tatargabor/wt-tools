## Context

The `wt-hook-memory` unified handler fires on every `UserPromptSubmit` event and currently does proactive recall. When users express frustration, that's a natural priority signal — the emotion says "this is IMPORTANT, the agent keeps failing at this." Currently, such signals are only captured at session end by the Stop hook's transcript extraction — if the session crashes or the user abandons it, the insight is lost.

After exploring the problem space (NLP research, real user patterns, scoring approaches), we concluded that complex scoring (7 categories, weighted multipliers, VADER-style boosters) is over-engineered for this use case. The real need is simple: **detect emotional charge → save the prompt → alert the current agent.**

## Goals / Non-Goals

**Goals:**
- Detect emotionally charged prompts in real-time during `UserPromptSubmit`
- Support both English and Hungarian with accent-tolerant patterns
- Save the entire prompt as a high-priority memory (the semantic search handles relevance)
- Inject an immediate warning to the current agent via `additionalContext`
- Track frustration history within a session for escalation detection
- Prioritize **agent-correction patterns** ("nem ezt kértem", "wrong file") as the most valuable signal
- Zero external dependencies (stdlib `re` + `json` only)
- Keep pattern count small (~30-35 regexes) for maintainability

**Non-Goals:**
- Numeric scoring with weighted categories (over-engineered)
- Context extraction by stripping frustration markers (lossy and complex)
- ML-based sentiment analysis (too heavy)
- Detecting frustration in languages other than English and Hungarian
- Blocking or modifying the user's prompt

## Decisions

### Decision 1: Simple trigger logic, not weighted scoring
**Choice:** Three trigger groups (strong, medium, session-boost) with simple boolean logic instead of 7-category weighted scoring with multipliers.

**Logic:**
- 1 strong trigger → save + inject (high)
- 2+ medium triggers → save + inject (moderate)
- 1 medium trigger + session history (3+ prior) → save + inject (moderate)
- 1 medium trigger alone → inject only, no save (mild)
- Nothing → no action

**Rationale:** After exploring VADER-style scoring with 7 categories, we found it was over-engineered. The real question is binary: "is this prompt emotionally charged?" The three-group trigger logic answers this with ~30 regexes instead of 100+, zero floating-point math, and trivially testable behavior.

**Alternative considered:** Category-based scoring (0.0–1.0) with intensity multipliers. Rejected — added complexity without proportional value. The precision difference between score=0.52 and score=0.48 is meaningless for our use case.

### Decision 2: Save entire prompt, no context extraction
**Choice:** Save the full user prompt with a frustration-level prefix, not an extracted "problem context."

**Format:**
- High: `"🔴 User frustrated (high): <entire prompt>"`
- Moderate: `"⚠️ User frustrated (moderate): <entire prompt>"`

**Rationale:** Context extraction ("strip frustration markers, keep semantic content") is lossy and complex. The shodh semantic search naturally finds the relevant content within saved memories. Saving `"🔴 User frustrated: megint nem működik a hook deploy, már sokadjára!!"` is both human-readable AND machine-searchable. The semantic search will match "hook deploy" queries against this memory.

### Decision 3: Three pattern groups with agent-correction as primary
**Choice:** Organize patterns into three groups by trigger strength:

**Strong triggers** (any single match = save + inject):
- **Agent-correction** (~10 patterns): "nem ezt kértem", "rossz fájlt", "that's not what I asked", "wrong file", "miért nem olvastad el", "read the file first", "you're not listening", "te nem figyelsz"
- **Expletives** (~10 patterns): "fuck", "shit", "baszd meg", "basszus", "a kurva", "geci", "wtf", "ffs"
- **Giving-up** (~8 patterns): "feladom", "hagyjuk", "give up", "forget it", "never mind", "done with this", "waste of time"

**Medium triggers** (2+ combined = save + inject, 1 alone = inject only):
- **Repetition + negation combo** (~5 patterns): "megint nem", "still doesn't", "still not working", "újra nem"
- **Temporal frustration** (~5 patterns): "hányszor", "how many times", "már mondtam", "I already told you", "this is the Nth time"
- **Escalation/absolutes** (~4 patterns): "soha", "never works", "mindig", "always breaks", "lehetetlen", "impossible"
- **Intensifiers**: ALL CAPS (2+ words, 3+ chars each), excessive punctuation (`!!`, `??`, `?!`)

**Rationale:** Agent-correction is the most valuable signal in a developer-agent context — the user is explicitly telling the agent what it did wrong. This is more actionable than general expletives. Putting it as a strong trigger ensures it always saves.

### Decision 4: Accent-tolerant Hungarian patterns
**Choice:** All Hungarian patterns use character classes: `[aá]`, `[eé]`, `[ií]`, `[oó]`, `[oö]`, `[uú]`, `[uü]`.

**Rationale:** Hungarian developers in technical contexts frequently type without accents. "működik" vs "mukodik", "újra" vs "ujra" must both match.

### Decision 5: Immediate context injection to current agent
**Choice:** When emotion is detected (any level including mild), add a warning to the hook's `additionalContext` output that the current agent sees immediately.

**Format:**
```
⚠ EMOTION DETECTED: The user appears frustrated (triggers: agent-correction, repetition).
Acknowledge their concern. Be extra careful with this task.
```

**Rationale:** This is the highest-value addition. The memory save helps future sessions, but the injection helps NOW — the agent in the current session can immediately adjust its behavior. The existing hook infrastructure (`output_hook_context`) supports this with zero additional work.

### Decision 6: Session history via dedup cache extension
**Choice:** Extend the existing session dedup cache with a `frustration_history` key:

```json
{
  "frustration_history": {
    "count": 3,
    "last_level": "mild"
  }
}
```

When `count >= 3`, a single medium trigger is enough to escalate to save (normally requires 2+ medium). This catches the "death by a thousand cuts" pattern.

**Rationale:** Reuses existing cache infrastructure. Simple counter, no timestamp tracking needed.

## Risks / Trade-offs

**[Risk] False positives on code/quotes** → User pastes code containing "doesn't work" as a comment, or quotes an error message. Mitigation: medium triggers require 2+ co-occurring patterns, which is unlikely in pasted code. Strong triggers (expletives, agent-correction) are rarely in code.

**[Risk] Meta-discussion false positives** → While developing this feature, prompts like "add a pattern for 'nem működik'" will trigger. Mitigation: acceptable during development, won't happen in normal use. Mild triggers only inject (no save).

**[Risk] Hook latency** → Python module call adds ~5-10ms. Mitigation: well within 5-second hook timeout. Existing proactive recall takes ~200ms.

**[Risk] Memory noise** → Too many frustration memories. Mitigation: only moderate+ saves. Mild inject-only. Session dedup prevents saving the same frustration pattern twice per session.
