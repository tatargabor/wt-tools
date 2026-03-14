## 1. Screenshot Capture Function

- [ ] 1.1 Add `capture_milestone_screenshots()` function in `lib/orchestration/milestone.sh`. Args: `port`, `urls_json` (JSON array string), `viewport`, `wait_secs`, `custom_command`. Creates temp dir `/tmp/wt-milestone-screenshots-$$`, iterates URLs, calls `_capture_single_screenshot()` for each. Returns temp dir path on stdout. Returns 1 if no screenshots captured.
- [ ] 1.2 Add `_capture_single_screenshot()` helper. Args: `url`, `output_path`, `viewport`, `wait_secs`, `custom_command`. If `custom_command` is set, run it with `URL` and `OUTPUT` env vars. Otherwise run `npx playwright screenshot --viewport-size=$W,$H --wait-for-timeout=${wait_ms} "$url" "$output_path"`. Return 0 on success, 1 on failure (log warning, don't abort).

## 2. Email Embedding

- [ ] 2.1 Add `_build_screenshot_html()` function in `lib/orchestration/milestone.sh`. Args: `screenshot_dir`, `urls_json`. Iterates screenshot files, base64-encodes each, builds `<img src="data:image/png;base64,...">` tags with URL path caption. Returns HTML string on stdout.
- [ ] 2.2 Modify `_send_milestone_email()` to accept optional `screenshot_dir` arg. After the phase summary table, insert screenshot HTML via `_build_screenshot_html()`. After email is sent (or fails), remove the temp screenshot dir.

## 3. Integration into Checkpoint Flow

- [ ] 3.1 Modify `run_milestone_checkpoint()` — after server health check (line ~83), read screenshot config from state directives (`milestones.screenshots.urls`, `.viewport`, `.wait_after_load`, `.command`). If `urls` is non-empty and server is running, call `capture_milestone_screenshots()`. Pass the screenshot dir to `_send_milestone_email()`.

## 4. Directive Parsing

- [ ] 4.1 Add `milestones_screenshots_urls`, `milestones_screenshots_viewport`, `milestones_screenshots_wait_after_load`, `milestones_screenshots_command` variables in `parse_directives()` in `lib/orchestration/utils.sh`. Add case branches for `milestones_screenshots_*`. Add to JSON output under `milestones.screenshots` object.

## 5. Testing

- [ ] 5.1 Add unit tests in `tests/unit/test_milestones.sh`: test `_build_screenshot_html()` with mock PNG files (1x1 pixel PNGs), verify base64 `<img>` tags in output. Test with empty dir (no screenshots).
- [ ] 5.2 Add unit test for screenshot config directive parsing — verify `milestones.screenshots.urls` flows through `parse_directives()` correctly.
