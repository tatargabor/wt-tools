## ADDED Requirements

### Requirement: PreToolUse hook for hot-topic Bash commands
A new hook script `wt-hook-memory-pretool` SHALL run on `PreToolUse` events matching the `Bash` tool. It SHALL parse the command for hot-topic patterns and inject relevant memories via `additionalContext` before the command executes.

#### Scenario: Bash command matches database hot topic
- **WHEN** Claude is about to execute a Bash command containing `psql`, `mysql`, `sqlite3`, `mongosh`, `prisma`, `sequelize`, `knex`, or `typeorm`
- **AND** wt-memory is healthy
- **THEN** the hook SHALL recall memories with query related to "database" and the specific tool
- **AND** SHALL output JSON with `hookSpecificOutput.additionalContext` containing relevant memories
- **AND** SHALL limit to 2 memories maximum

#### Scenario: Bash command matches API hot topic
- **WHEN** Claude is about to execute a Bash command containing `curl`, `wget`, or `httpie`
- **AND** wt-memory is healthy
- **THEN** the hook SHALL recall memories related to "api" and the specific endpoint if detectable

#### Scenario: Bash command matches deploy hot topic
- **WHEN** Claude is about to execute a Bash command containing `docker`, `kubectl`, `terraform`, `ansible`, or `ssh`
- **AND** wt-memory is healthy
- **THEN** the hook SHALL recall memories related to "deployment" and the specific tool

#### Scenario: Bash command matches auth hot topic
- **WHEN** Claude is about to execute a Bash command referencing `.env`, `credential`, `secret`, `password`, `token`, `.pem`, or `.key`
- **AND** wt-memory is healthy
- **THEN** the hook SHALL recall memories related to "auth" and the specific pattern

#### Scenario: Bash command matches python/node hot topic
- **WHEN** Claude is about to execute a Bash command starting with `python`, `python3`, `node`, `npx`, `npm run`, or `bun run`
- **AND** wt-memory is healthy
- **THEN** the hook SHALL recall memories related to the runtime and script name if detectable

#### Scenario: Bash command does not match any hot topic
- **WHEN** Claude is about to execute a Bash command that does not match any hot-topic pattern
- **THEN** the hook SHALL exit 0 immediately with no output
- **AND** the total execution time SHALL be less than 5ms

### Requirement: Hot-topic pattern matching is fast
The pattern check against the command string SHALL use a single compiled regex and complete in under 5ms. Memory recall only executes after a positive pattern match.

#### Scenario: Non-matching command latency
- **WHEN** a Bash command like `ls -la` or `git status` is about to execute
- **THEN** the hook SHALL complete in under 5ms with no output

#### Scenario: Matching command latency
- **WHEN** a Bash command like `psql -h localhost` is about to execute
- **THEN** the hook SHALL complete in under 5 seconds (including recall)
- **AND** typical completion time SHALL be under 500ms

### Requirement: Hot-topic categories are configurable
The base hot-topic pattern list SHALL be hardcoded in the script. A future extension point SHALL allow project-specific patterns via a config file, but this is not required in the initial implementation.

#### Scenario: Default patterns cover common tools
- **WHEN** the hook is installed without any custom configuration
- **THEN** it SHALL recognize database, API, deploy, auth, python, and node patterns

### Requirement: Hook deployment includes PreToolUse
The `wt-deploy-hooks` script SHALL include `wt-hook-memory-pretool` in a `PreToolUse` hook event with matcher `"Bash"`.

#### Scenario: Deploy adds PreToolUse hook
- **WHEN** `wt-deploy-hooks /path/to/project` is called
- **THEN** settings.json SHALL contain a `PreToolUse` entry matching `"Bash"` with `wt-hook-memory-pretool`
- **AND** the timeout SHALL be 5 seconds
