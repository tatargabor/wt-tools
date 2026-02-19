## ADDED Requirements

### Requirement: FeatureWorker cache renders project header correctly
A GUI test SHALL verify that when `_feature_cache` contains data for a project, the project header renders without exceptions and shows correct button states.

#### Scenario: Project header with populated feature cache
- **WHEN** `_feature_cache` contains memory and openspec status for a project
- **AND** `refresh_table_display()` is called
- **THEN** the project header row renders without exceptions
- **AND** the Memory [M] button shows the correct color based on memory count
- **AND** the OpenSpec [O] button shows the correct color based on install status

#### Scenario: Project header with empty feature cache
- **WHEN** `_feature_cache` is empty (FeatureWorker hasn't polled yet)
- **AND** `refresh_table_display()` is called
- **THEN** both [M] and [O] buttons show gray "checking..." state

### Requirement: Opaque row background test
A GUI test SHALL verify that no table cell has an alpha-transparent background after rendering.

#### Scenario: All row backgrounds are opaque after status update
- **WHEN** `update_status()` processes worktree data including idle, running, and waiting rows
- **THEN** every QTableWidgetItem background color has alpha == 255
