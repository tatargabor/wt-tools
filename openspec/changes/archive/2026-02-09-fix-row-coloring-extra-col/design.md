## Context

The Control Center GUI uses a QTableWidget to display worktree rows. Most columns use `setItem()` (QTableWidgetItem), but the Extra column (COL_EXTRA = 5) uses `setCellWidget()` to embed Ralph buttons. Row coloring is applied via `item.setBackground()`, which only affects QTableWidgetItems — cellWidgets sit on top and have their own transparent background, creating a visual gap.

Three places set row background colors:
1. `_render_worktree_row()` — initial render (compacting, waiting, idle states)
2. `update_pulse()` — 50ms pulse animation for running rows
3. `toggle_blink()` — 500ms blink for attention-needing rows

## Goals / Non-Goals

**Goals:**
- Row background coloring extends visually across all columns, including COL_EXTRA when it contains a cellWidget
- Works for all coloring modes: static (compacting/waiting/idle), pulse animation (running), and blink (attention)

**Non-Goals:**
- Changing the Ralph button colors themselves (they have explicit stylesheets)
- Refactoring the column system or moving away from cellWidgets

## Decisions

**Decision: Apply background via stylesheet on the cellWidget container**

When coloring a row, in addition to `item.setBackground()`, also find any `cellWidget` and set its background via stylesheet. The integrations_widget in `_render_extra_column()` will be styled with a transparent background by default, and the row-coloring code will override it when needed.

Approach: Create a helper method `_set_row_background(row, color)` that:
1. Iterates columns and calls `item.setBackground(color)` for items
2. Checks for cellWidgets and applies `background-color` via stylesheet

Alternative considered: Using `setAutoFillBackground(True)` + QPalette — rejected because stylesheet is already used extensively in this codebase and is more readable.

## Risks / Trade-offs

- [Risk] Stylesheet overwrite on cellWidget may interfere with button styles → Mitigation: Only set background on the container QWidget, not on the QPushButtons inside it. Buttons have their own explicit stylesheets.
- [Risk] Performance of stylesheet changes on every pulse tick (50ms) → Mitigation: `setStyleSheet()` on a simple container widget is lightweight; no measurable overhead expected.
