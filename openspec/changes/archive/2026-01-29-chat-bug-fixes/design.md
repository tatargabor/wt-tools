## Context

The Control Center chat buttons open the same chat window for every project because the project name is not passed from the button click handler to the dialog.

```
CURRENT FLOW (BUGGY):
──────────────────────────────────────────────────────────────
table.py: chat_btn.clicked.connect(self.show_chat_dialog)
                                   ↓
menus.py: def show_chat_dialog(self):
              current_project = self.get_active_project()
                                       ↓
main_window.py: return self.worktrees[0].get("project")
                       ↑
                       ALWAYS THE FIRST PROJECT!
```

## Goals / Non-Goals

**Goals:**
- Chat button opens the correct project's chat
- Message sending and receiving works reliably

**Non-Goals:**
- Chat UI redesign
- Adding new chat features

## Decisions

### 1. Lambda pattern for project passing

**Decision:** The chat button click handler passes the project name via lambda.

```python
# BEFORE:
chat_btn.clicked.connect(self.show_chat_dialog)

# AFTER:
chat_btn.clicked.connect(lambda checked, p=project: self.show_chat_dialog(p))
```

**Rationale:**
- Same pattern as other buttons (e.g., filter button lambda)
- Simple, clean solution
- No need for state storage

### 2. Optional project parameter in show_chat_dialog

**Decision:** `show_chat_dialog` accepts an optional project parameter.

```python
def show_chat_dialog(self, project: str = None):
    current_project = project or self.get_active_project()
```

**Rationale:**
- Backward compatible with menu-based invocation
- If no project specified, falls back to old logic

## Risks / Trade-offs

**[Risk] Chat launched from menu**
→ The menu also uses `show_chat_dialog`. There's no project context there, but the `get_active_project()` fallback works.

**[Trade-off] Project-specific dialog would be simpler**
→ But that would be a bigger refactor, this is the minimal fix.
