## 1. CLAUDE.md Update

- [x] 1.1 Add "Agent Discovery Saving" subsection to the Proactive Memory section in CLAUDE.md. Content: "Discover → Save → Tell" ordering rule, what counts as a discovery (gotchas, unexpected behavior, architecture findings, environment quirks), what doesn't (routine observations, documented behavior). Keep it to ~5 lines.

## 2. Explore Skill

- [x] 2.1 Add "Discover → Save → Tell" instruction to the explore SKILL.md, inside or adjacent to the existing "Recognizing Knowledge Worth Saving" section. Make it clear this covers AGENT discoveries (not just user-shared knowledge). Keep it concise — reference the pattern by name, don't duplicate the full CLAUDE.md text.
- [x] 2.2 Add matching instruction to `.claude/commands/opsx/explore.md`

## 3. FF Skill

- [x] 3.1 Add "Discover → Save → Tell" one-liner to the ff SKILL.md, near the existing "Recognize user-shared knowledge mid-flow" section (step 3c). Add a note that this also covers agent's own findings during codebase research.
- [x] 3.2 Add matching instruction to `.claude/commands/opsx/ff.md`

## 4. Apply Skill

- [x] 4.1 Add "Discover → Save → Tell" one-liner to the apply SKILL.md, near the existing mid-flow recognition section (step 4c). Clarify that agent-discovered errors and workarounds should be saved immediately, not deferred to step 7.
- [x] 4.2 Add matching instruction to `.claude/commands/opsx/apply.md`

## 5. Continue Skill

- [x] 5.1 Add "Discover → Save → Tell" one-liner to the continue SKILL.md, near the existing mid-flow recognition section (step 2c).
- [x] 5.2 Add matching instruction to `.claude/commands/opsx/continue.md`

## 6. Verify Skill

- [x] 6.1 Add "Discover → Save → Tell" one-liner to the verify SKILL.md, near the investigation/verification steps.
- [x] 6.2 Add matching instruction to `.claude/commands/opsx/verify.md`
