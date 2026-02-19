## 1. Fix registration

- [x] 1.1 In `bin/wt-project` `_register_mcp_server()`: remove `python` from `claude mcp add` command — run script directly via shebang
- [x] 1.2 In `bin/wt-project` `_register_mcp_server()`: remove the `_is_mcp_registered` early-return so re-registration always happens (fixes stale configs)

## 2. Update spec

- [x] 2.1 Update `openspec/specs/mcp-memory-tools/spec.md` registration scenario to reflect shebang-based execution
