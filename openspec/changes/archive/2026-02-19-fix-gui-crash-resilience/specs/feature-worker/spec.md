## MODIFIED Requirements

### Requirement: Feature cache in table rendering
The `_create_project_header` method SHALL read feature status from `self._feature_cache[project]` instead of calling subprocesses. The `get_memory_status` method SHALL read from cache and NOT run subprocess calls. The `get_openspec_status` method SHALL be called to retrieve openspec status before accessing its fields.

#### Scenario: Table render uses cache
- **WHEN** `refresh_table_display` rebuilds the table
- **THEN** `_create_project_header` reads `self._feature_cache.get(project, {})` for both memory and openspec button states, with zero subprocess calls

#### Scenario: Cache not yet populated
- **WHEN** the table renders before the first FeatureWorker poll completes
- **THEN** all feature buttons show gray/default state (memory: gray "checking...", openspec: gray "checking...")

#### Scenario: OpenSpec status variable is defined before use
- **WHEN** `_create_project_header` renders the OpenSpec [O] button
- **THEN** `os_status` is obtained via `self.get_openspec_status(project)` before any access to `os_status.get()`
- **AND** no NameError occurs regardless of cache state
