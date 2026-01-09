# Change: Menu System Restructure

JIRA Key: TBD
Story: TBD

## Why

The current menu structure has grown organically and lacks consistency. With the plugin architecture in place, we need a clear separation of:
- **Global actions** - App settings, quit, restart
- **Project/Repository actions** - Team sync, JIRA integration, project settings
- **Worktree actions** - Git operations, focus, open, close

This restructure will improve:
- User discoverability of features
- Plugin integration points
- Consistency across all menu types (main, context, tray)

## Current State Analysis

### Main Menu (hamburger button ≡)
- Settings...
- Minimize to Tray
- Restart
- Quit

### Tray Menu
- Show
- New Worktree...
- Quit

### Context Menu (right-click on empty area)
- + New Worktree
- Work...
- ↻ Refresh
- Minimize to Tray
- Restart
- Quit

### Row Context Menu (right-click on worktree row)
- Focus Window
- Open in Terminal
- Open in File Manager
- Copy Path
- + New Worktree... (for same project)
- **Git submenu**: Merge to..., Merge from..., Push, Pull, Fetch
- **JIRA submenu** (conditional): Open Story, Log Work..., Sync Worklog, Sync Proposals
- **Project submenu**: Team Chat..., Generate Chat Key..., Team Settings..., Initialize wt-control...
- **Ralph Loop submenu**: Start/Stop Loop, View Terminal/Log
- **Worktree submenu**: Close, Push Branch
- Worktree Config...

### Issues Identified

1. **Mixed levels**: Row context menu mixes project-level (Team Settings) with worktree-level (Close) actions
2. **No icons**: Menus lack visual cues for quick recognition
3. **Inconsistent grouping**: JIRA in submenu, but Ralph Loop also in submenu (different patterns)
4. **Plugin visibility**: No clear extension point for plugin menu items
5. **Tray menu minimal**: Missing quick actions (refresh, settings)

## What Changes

### 1. Three-Level Menu Organization

#### Global Level (App-wide)
| Action | Icon | Shortcut | Location |
|--------|------|----------|----------|
| Settings | ⚙️ | - | Main menu, Tray |
| Refresh | ↻ | F5 | Toolbar, Context |
| Minimize | − | - | Toolbar |
| Restart | 🔄 | - | Main menu |
| Quit | ✕ | - | Main menu, Tray |

#### Project Level (Repository)
| Action | Icon | Shortcut | Location |
|--------|------|----------|----------|
| New Worktree | + | - | Toolbar, Context |
| Team Chat | 💬 | - | Toolbar (badge), Context |
| Team Settings | 👥 | - | Project submenu |
| Init wt-control | 🔧 | - | Project submenu |
| Generate Chat Key | 🔑 | - | Project submenu |
| **Plugin: JIRA** | | | |
| Sync Proposals | 📋 | - | Project submenu |

#### Worktree Level
| Action | Icon | Shortcut | Location |
|--------|------|----------|----------|
| Focus Window | 🎯 | - | Row context |
| Open Terminal | >_ | - | Row context |
| Open File Manager | 📁 | - | Row context |
| Copy Path | 📋 | - | Row context |
| Worktree Config | ⚙️ | - | Row context |
| Close Worktree | ✕ | - | Row context |
| **Git Operations** | | | |
| Push | ↑ | - | Git submenu |
| Pull | ↓ | - | Git submenu |
| Fetch | ⟳ | - | Git submenu |
| Merge to... | ⤴️ | - | Git submenu |
| Merge from... | ⤵️ | - | Git submenu |
| Push Branch (wt) | ↑ | - | Git submenu |
| **Ralph Loop** | | | |
| Start Loop | ▶️ | - | Ralph submenu |
| Stop Loop | ⏹️ | - | Ralph submenu |
| View Terminal | 🖥️ | - | Ralph submenu |
| View Log | 📄 | - | Ralph submenu |
| **Plugin: JIRA** | | | |
| Open Story | 🔗 | - | JIRA submenu |
| Log Work | ⏱️ | - | JIRA submenu |
| Sync Worklog | 🔄 | - | JIRA submenu |

### 2. Restructured Menus

#### New Main Menu (hamburger ≡)
```
[Global]
⚙️  Settings...
↻   Refresh

[Project: {project_name}]
👥  Team Settings...
💬  Team Chat...

[Plugins]
📋  JIRA...  (if available)

---
🔄  Restart
✕   Quit
```

#### New Tray Menu
```
Show
---
+ New Worktree...
⚙️  Settings...
---
✕   Quit
```

#### New Empty Context Menu
```
+   New Worktree...
📂  Work...
---
↻   Refresh
---
−   Minimize to Tray
```

#### New Row Context Menu
```
[Worktree Actions]
🎯  Focus Window
>_  Open in Terminal
📁  Open in File Manager
📋  Copy Path

---

[Create]
+   New Worktree... (for {project})

---

[Git ▸]
↑   Push
↓   Pull
⟳   Fetch
---
⤴️  Merge to...
⤵️  Merge from...

[Ralph Loop ▸]
▶️  Start Loop... / ⏹️ Stop Loop
🖥️  View Terminal
📄  View Log

[JIRA ▸]  (plugin, if available)
🔗  Open Story
⏱️  Log Work...
🔄  Sync Worklog

---

[Project ▸]
💬  Team Chat...
👥  Team Settings...
🔧  Initialize wt-control...

---

⚙️  Worktree Config...
✕   Close Worktree
```

### 3. Plugin Menu Integration

Plugins register menu items via `PluginRegistry`:

```python
class MenuItem:
    label: str
    icon: str  # Unicode or path
    action: Callable
    level: Literal["global", "project", "worktree"]
    submenu: str | None  # e.g., "JIRA", "Confluence"
    order: int  # Sort order within submenu
```

Example:
```python
class JiraPlugin(Plugin):
    def get_menu_items(self) -> list[MenuItem]:
        return [
            MenuItem("Open Story", "🔗", self.open_story, "worktree", "JIRA", 1),
            MenuItem("Log Work...", "⏱️", self.log_work, "worktree", "JIRA", 2),
            MenuItem("Sync Worklog", "🔄", self.sync_worklog, "worktree", "JIRA", 3),
            MenuItem("Sync Proposals", "📋", self.sync_proposals, "project", "JIRA", 1),
        ]
```

### 4. Toolbar Buttons

Current toolbar:
```
[+ New] [Work] [v1.x.x]     [↻] [−] [≡]
```

Proposed toolbar:
```
[+ New] [Work] [💬] [v1.x.x]     [↻] [−] [≡]
```

- Chat button shows unread badge (already implemented)
- All buttons have tooltips

### 5. Icon Standard

| Category | Style |
|----------|-------|
| Actions | Unicode emoji (single char) |
| Status | Colored circles (●○) |
| Plugins | Plugin-provided icon or fallback |

For text-only mode (accessibility), icons are hidden and labels are shown.

## Impact

- **Modified files:**
  - `gui/control_center/mixins/menus.py` - Complete rewrite
  - `gui/control_center/main_window.py` - Toolbar updates
  - `wt_tools/plugins/base.py` - Add MenuItem class

- **New files:**
  - `gui/control_center/mixins/menu_builder.py` - Centralized menu construction

- **No breaking changes** to existing functionality

## Verification

1. All menu items accessible from at least one location
2. Plugin menus appear only when plugin available
3. Icons display correctly on Linux, macOS, Windows
4. Context-appropriate menus (project items only when project selected)
5. Keyboard navigation works in all menus

## Tasks

- [ ] 1.1 Define MenuItem dataclass in plugins/base.py
- [ ] 1.2 Create menu_builder.py with centralized menu construction
- [ ] 1.3 Refactor menus.py to use menu_builder
- [ ] 1.4 Add icons to all menu items
- [ ] 1.5 Restructure row context menu with clear sections
- [ ] 1.6 Update main menu with project section
- [ ] 1.7 Update tray menu with additional actions
- [ ] 1.8 Add plugin menu integration
- [ ] 1.9 Test on all platforms
