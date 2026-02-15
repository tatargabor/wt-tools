# Benchmark Comparison Report

**Date**: YYYY-MM-DD
**Model**: <model name and version>
**Evaluator**: <name>

## Summary

### Aggregate Metrics

| Metric | Run A (baseline) | Run B (memory) | Delta | Delta % |
|--------|-----------------|----------------|-------|---------|
| Total dead ends | | | | |
| Total repeated mistakes | | | | |
| Total design rework | | | | |
| First-try pass rate | /6 | /6 | | |
| Total iterations | | | | |
| Total tokens | | | | |
| Total time (min) | | | | |

### Run B Memory Summary

| Metric | Value |
|--------|-------|
| Total recalls | |
| Useful recalls | |
| Recall efficiency | % |
| Total saves | |
| Avg save quality | |

## Per-Change Comparison

### Change 01: Product Catalog

| Metric | Run A | Run B | Delta |
|--------|-------|-------|-------|
| Dead ends | | | |
| Repeated mistakes | | | |
| Design rework | | | |
| First-try pass | | | |
| Iterations | | | |
| Tokens | | | |

**Key observations**:
<!-- What happened differently? Did memory matter for this change? -->

### Change 02: Shopping Cart

| Metric | Run A | Run B | Delta |
|--------|-------|-------|-------|
| Dead ends | | | |
| Repeated mistakes | | | |
| Design rework | | | |
| First-try pass | | | |
| Iterations | | | |
| Tokens | | | |

**Key observations**:

### Change 03: Multi-Vendor Orders

| Metric | Run A | Run B | Delta |
|--------|-------|-------|-------|
| Dead ends | | | |
| Repeated mistakes | | | |
| Design rework | | | |
| First-try pass | | | |
| Iterations | | | |
| Tokens | | | |

**Key observations**:
<!-- This is the pivotal change. What order architecture was chosen in each run? -->

### Change 04: Discounts

| Metric | Run A | Run B | Delta |
|--------|-------|-------|-------|
| Dead ends | | | |
| Repeated mistakes | | | |
| Design rework | | | |
| First-try pass | | | |
| Iterations | | | |
| Tokens | | | |

**Key observations**:
<!-- Did Run B recall variant-level pricing and order architecture? -->

### Change 05: Checkout

| Metric | Run A | Run B | Delta |
|--------|-------|-------|-------|
| Dead ends | | | |
| Repeated mistakes | | | |
| Design rework | | | |
| First-try pass | | | |
| Iterations | | | |
| Tokens | | | |

**Key observations**:
<!-- Did Run B recall SQLite WAL mode from C2? Did SQLITE_BUSY recur in Run A? -->

### Change 06: Order Workflow

| Metric | Run A | Run B | Delta |
|--------|-------|-------|-------|
| Dead ends | | | |
| Repeated mistakes | | | |
| Design rework | | | |
| First-try pass | | | |
| Iterations | | | |
| Tokens | | | |

**Key observations**:
<!-- Ultimate payoff. How much rework did each run need based on C3's architecture? -->

## Narrative Findings

### Where memory helped most

<!-- Identify the 2-3 moments where memory had the clearest positive impact -->

### Where memory didn't help

<!-- Identify cases where Run B performed similarly to Run A despite having memory -->

### Unexpected results

<!-- Anything surprising — Run A outperforming Run B, unexpected traps, etc. -->

## Diagnostic Summary

### Memory Gap Analysis

| Gap Category | Count | Critical | Moderate | Minor |
|-------------|-------|----------|----------|-------|
| Missed recall | | | | |
| Low-quality save | | | | |
| Missing memory type | | | | |
| Timing issue | | | | |
| Recall relevance | | | | |

### Top Improvement Recommendations

1. **Recommendation**:
   - Gap:
   - Impact:
   - Suggested change:

2. **Recommendation**:
   - Gap:
   - Impact:
   - Suggested change:

3. **Recommendation**:
   - Gap:
   - Impact:
   - Suggested change:

## Conclusion

<!-- Overall assessment: Does shodh-memory measurably improve agent performance? What's the evidence? What should be improved? -->
