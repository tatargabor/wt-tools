# Session Annotation: Change NN — <change-name>

**Run**: A (baseline) / B (with-memory)
**Date**: YYYY-MM-DD
**Annotator**: <name>

## Quantitative Metrics

| Metric | Value |
|--------|-------|
| Iterations | |
| Tokens | |
| Time (minutes) | |
| Commits | |
| Dead ends (0-5) | |
| Repeated mistakes (0-3) | |
| Design rework (0-3) | |
| First-try test pass | yes / no |

## Run B Memory Metrics (skip for Run A)

| Metric | Value |
|--------|-------|
| Memory recalls | |
| Useful recalls | |
| Memories saved | |
| Save quality (H/M/L) | |

## Qualitative Notes

### Dead Ends Observed

<!-- For each dead end, describe: what the agent tried, when it realized the mistake, how it recovered -->

1. **Dead end**:
   - **Approach tried**:
   - **Realization**:
   - **Recovery**:
   - **Iterations lost**:

### Repeated Mistakes

<!-- Did the agent repeat a mistake from a previous change? Which one? -->

1. **Mistake**:
   - **First occurrence**: Change NN
   - **Repeated in**: This change
   - **Resolution time**:

### Design Rework

<!-- Did the agent need to modify code from previous changes? What and why? -->

1. **Rework**:
   - **Original code**: (change, file, approach)
   - **What changed**:
   - **Why**:

### Trap Encounters

<!-- For each trap defined in the evaluator notes, document what happened -->

**T<N.M>: <trap name>**
- Encountered: yes / no
- Agent's approach:
- Impact:
- Memory interaction (Run B only): recalled / saved / missed

## Memory Event Log (Run B only)

### Recalls

| # | Query | Results | Useful? | Influenced behavior? |
|---|-------|---------|---------|---------------------|
| 1 | | | yes/no | |

### Saves

| # | Content (summary) | Type | Tags | Quality |
|---|-------------------|------|------|---------|
| 1 | | | | H/M/L |

## Summary

<!-- 2-3 sentences summarizing this change's session -->
