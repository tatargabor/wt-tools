## MODIFIED Requirements

### Requirement: Account management menu actions
The GUI SHALL provide menu actions to add, remove, and scan for Claude accounts.

#### Scenario: Add account via menu
- **WHEN** user selects "Add Account..." from the menu
- **THEN** the main window hides (always-on-top conflict prevention)
- **AND** a dialog prompts for account name and session key
- **AND** the account is saved to `claude-session.json`
- **AND** the usage worker restarts to include the new account

#### Scenario: Remove account via menu
- **WHEN** user selects "Remove Account..." from the menu
- **AND** more than one account exists
- **THEN** a selection dialog lists all account names
- **AND** the selected account is removed from `claude-session.json`
- **AND** the usage worker restarts

#### Scenario: Remove action hidden for single account
- **WHEN** only one account is configured
- **THEN** the "Remove Account..." menu action SHALL NOT be visible

#### Scenario: Scan Chrome sessions via menu
- **WHEN** user selects "Scan Chrome Sessions" from the menu
- **THEN** the system SHALL scan all Chrome profiles for Claude session cookies
- **AND** replace the account list with discovered sessions
- **AND** restart the usage worker

#### Scenario: Scan Chrome sessions via toolbar button
- **WHEN** user clicks the scan button (🔍) in the toolbar
- **THEN** the behavior SHALL be identical to the menu action
