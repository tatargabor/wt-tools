## MODIFIED Requirements

### Requirement: Installation via install.sh
The `wt-memory` script SHALL be included in the `scripts` array of `install_scripts()` in `install.sh`, so it is symlinked to `~/.local/bin/` during installation. The CLI SHALL support the `audit` and `dedup` subcommands in its main dispatch and usage text.

#### Scenario: Fresh install
- **WHEN** `install.sh` is run
- **THEN** `wt-memory` is symlinked to `~/.local/bin/wt-memory`

#### Scenario: Audit command dispatch
- **WHEN** `wt-memory audit` is run
- **THEN** the main dispatch routes to `cmd_audit`

#### Scenario: Dedup command dispatch
- **WHEN** `wt-memory dedup` is run
- **THEN** the main dispatch routes to `cmd_dedup`

#### Scenario: Help text includes new commands
- **WHEN** `wt-memory --help` is run
- **THEN** the usage text lists `audit` and `dedup` under the Diagnostics section
