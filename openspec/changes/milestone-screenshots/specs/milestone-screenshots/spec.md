## ADDED Requirements

### Requirement: Screenshot capture at milestone checkpoint
The system SHALL capture screenshots of configured URLs from the milestone dev server after the server health check passes and before sending the milestone email. Screenshots SHALL be saved as PNG files to a temporary directory.

#### Scenario: Screenshots captured successfully
- **WHEN** a milestone checkpoint runs with `milestones.screenshots.urls` configured and the dev server is healthy
- **THEN** the system captures a screenshot of each configured URL using a headless browser, saving each as a PNG file

#### Scenario: No screenshot URLs configured
- **WHEN** a milestone checkpoint runs without `milestones.screenshots.urls` configured
- **THEN** the system skips screenshot capture and sends the email without images

#### Scenario: Headless browser not available
- **WHEN** the screenshot capture command fails (e.g., Playwright not installed)
- **THEN** the system logs a warning and continues — the milestone email is sent without screenshots

#### Scenario: No dev server running
- **WHEN** a milestone checkpoint has no dev server (server detection returned empty)
- **THEN** the system skips screenshot capture entirely

### Requirement: Screenshot embedding in milestone email
The system SHALL embed captured screenshots as base64 inline `<img>` tags in the milestone notification email HTML body, below the phase summary table and above the change list.

#### Scenario: Email with screenshots
- **WHEN** screenshots were captured successfully
- **THEN** the email HTML contains an `<img src="data:image/png;base64,...">` tag for each screenshot, with a caption showing the URL path

#### Scenario: Temp files cleaned up
- **WHEN** the milestone email has been sent (or failed)
- **THEN** the temporary screenshot directory is removed

### Requirement: Screenshot configuration directives
The system SHALL support the following directives under `milestones.screenshots`:
- `urls`: Array of URL paths to screenshot (e.g., `["/", "/products"]`). No default — screenshots disabled if not set.
- `viewport`: Viewport dimensions as `WIDTHxHEIGHT` string (default: `1280x720`).
- `wait_after_load`: Seconds to wait after page load before capture (default: `2`).
- `command`: Optional custom capture command override. Receives `$URL` and `$OUTPUT` env vars.

#### Scenario: Directive parsing
- **WHEN** `orchestration.yaml` contains `milestones.screenshots.urls: ["/", "/about"]`
- **THEN** the directive resolver includes these URLs in the resolved milestones config

#### Scenario: Default viewport
- **WHEN** `milestones.screenshots.viewport` is not set but `urls` is configured
- **THEN** the system uses `1280x720` as the default viewport size

#### Scenario: Custom capture command
- **WHEN** `milestones.screenshots.command` is set to `"chromium --headless --screenshot=$OUTPUT $URL"`
- **THEN** the system uses this command instead of the default Playwright CLI
