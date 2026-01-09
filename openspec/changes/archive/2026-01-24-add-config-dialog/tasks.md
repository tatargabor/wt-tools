# Tasks: Add Configuration Dialog

## 1. Config File Management
- [x] 1.1 Create config schema and defaults in Python
- [x] 1.2 Implement config loading at startup
- [x] 1.3 Implement config saving on change
- [x] 1.4 Add config file migration for future versions

## 2. Settings Dialog UI
- [x] 2.1 Create SettingsDialog class with tab widget
- [x] 2.2 Add "Control Center" tab with opacity, width, refresh settings
- [x] 2.3 Add "JIRA" tab with URL, project, credentials path
- [x] 2.4 Add "Git" tab with branch prefix, fetch timeout
- [x] 2.5 Add "Notifications" tab with enable/sound toggles
- [x] 2.6 Add OK/Cancel/Apply buttons

## 3. Menu Integration
- [x] 3.1 Add "Settings..." menu item to main menu (≡)
- [x] 3.2 Connect menu item to open SettingsDialog

## 4. Apply Config Values
- [x] 4.1 Replace hardcoded opacity with config values
- [x] 4.2 Replace hardcoded window width with config
- [x] 4.3 Replace hardcoded refresh interval with config
- [x] 4.4 Replace hardcoded blink interval with config
- [x] 4.5 Use config for notification settings

## 5. Live Config Updates
- [x] 5.1 Apply opacity changes immediately on dialog close
- [x] 5.2 Restart worker thread with new refresh interval
- [x] 5.3 Update blink timer interval

## 6. Validation
- [x] 6.1 Test config persistence across restarts
- [x] 6.2 Test default values when config missing
- [x] 6.3 Test invalid config values handling

## 7. UX Improvements (added)
- [x] 7.1 Set 100% opacity when dialogs are open (Settings, Work, New)
