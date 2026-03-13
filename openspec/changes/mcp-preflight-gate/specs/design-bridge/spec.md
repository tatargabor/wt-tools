## MODIFIED Requirements

### Requirement: Non-fatal design bridge
All design-bridge functions SHALL be non-fatal during agent execution. However, during orchestrator preflight, MCP availability SHALL be validated and failures SHALL trigger a checkpoint instead of silent fallback.

#### Scenario: MCP unreachable during planner run
- **WHEN** the design MCP server is registered but unreachable
- **AND** the orchestrator preflight has already been approved or skipped
- **THEN** the planner completes normally — design prompt section was injected but MCP tool calls return errors, which the LLM handles gracefully

#### Scenario: MCP unreachable during agent execution
- **WHEN** the design MCP server is registered but unreachable during Ralph loop iteration
- **THEN** the agent handles MCP errors gracefully and continues implementation using available context

#### Scenario: MCP unreachable during orchestrator preflight
- **WHEN** the design MCP server is registered but not authenticated
- **AND** the orchestrator is in preflight phase before decomposition
- **THEN** a checkpoint of type `mcp_auth` is triggered instead of silently continuing

## ADDED Requirements

### Requirement: Design MCP health check function
The bridge SHALL provide a `check_design_mcp_health()` function that tests MCP connectivity using a lightweight `run_claude` probe.

#### Scenario: Health check with authenticated MCP
- **WHEN** `check_design_mcp_health()` is called
- **AND** `DESIGN_MCP_CONFIG` is set to a valid config file
- **THEN** the function runs `run_claude` with a probe prompt and the MCP config
- **AND** returns 0 if the MCP responds successfully

#### Scenario: Health check without MCP config
- **WHEN** `check_design_mcp_health()` is called
- **AND** `DESIGN_MCP_CONFIG` is not set
- **THEN** the function returns 1 without running a probe
