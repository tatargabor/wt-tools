## ADDED Requirements

### Requirement: Memory Browse Dialog export button
The Memory Browse Dialog SHALL provide an Export button that exports all project memories to a JSON file.

#### Scenario: Export via dialog
- **WHEN** user clicks the Export button in the Memory Browse Dialog
- **THEN** system opens a directory picker dialog
- **AND** writes the export file with auto-generated name `<project>-memory-<YYYY-MM-DD>.json`
- **AND** shows a success message with the file path and record count

#### Scenario: Export with no memories
- **WHEN** user clicks Export and the project has no memories
- **THEN** system shows a warning that there are no memories to export

### Requirement: Memory Browse Dialog import button
The Memory Browse Dialog SHALL provide an Import button that imports memories from a JSON export file.

#### Scenario: Import via dialog
- **WHEN** user clicks the Import button in the Memory Browse Dialog
- **THEN** system opens a file picker filtered to JSON files
- **AND** after selecting a file, runs the import with dedup
- **AND** shows a result dialog with imported/skipped counts
- **AND** refreshes the memory list to reflect newly imported records

#### Scenario: Import error handling
- **WHEN** the selected file is invalid or import fails
- **THEN** system shows a warning dialog with the error message
