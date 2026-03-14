## Context

Milestone checkpoints (implemented in `lib/orchestration/milestone.sh`) create a worktree with a running dev server after each phase completes. An email is sent with text stats. The human must manually visit `localhost:310N` to visually verify the build. This adds a screenshot capture step between server health check and email, embedding images inline.

## Goals / Non-Goals

**Goals:**
- Capture screenshots of configured URLs from the milestone dev server
- Embed screenshots as base64 inline images in the milestone email
- Configurable URL list, viewport, and capture command via directives
- Graceful degradation — if no headless browser available, skip screenshots silently

**Non-Goals:**
- AI-based visual review of screenshots (future Szint 2)
- Human approval gate that blocks orchestration
- Screenshot diffing against design mockups
- Storing screenshots persistently (they live in the email only)

## Decisions

**1. Capture tool: `npx playwright screenshot` CLI**
- Rationale: Playwright is the de facto standard for headless browser automation, `npx` means zero-install for JS projects, the CLI interface is simple (`npx playwright screenshot --viewport-size=W,H URL output.png`)
- Alternative: `chromium --headless --screenshot` — lower level, less portable across environments
- Alternative: `wkhtmltoimage` — older, less maintained, poor SPA support
- Fallback: if `npx playwright screenshot` fails or isn't available, log warning and skip — screenshots are non-blocking

**2. Image embedding: base64 inline `<img>` in HTML email**
- Rationale: Works in all email clients without attachment management. Resend API accepts HTML body with inline base64 images. No need for separate attachment API.
- Trade-off: Email size increases (~50-200KB per screenshot). Acceptable for 3-5 screenshots per phase.

**3. Screenshot storage: temp directory, cleaned up after email sent**
- Screenshots saved to `/tmp/wt-milestone-screenshots-$phase/` during capture, deleted after email assembly. No persistent storage needed.

**4. Custom capture command override**
- `milestones.screenshots.command` directive allows overriding the entire capture command (e.g., for non-JS projects or custom setups). Receives `$URL` and `$OUTPUT` as env vars.

## Risks / Trade-offs

- [Risk] Playwright not installed in project → Mitigation: `npx playwright screenshot` auto-installs, but may take 30-60s first time. Log progress. If it fails, skip gracefully.
- [Risk] Dev server not ready when screenshots start → Mitigation: Screenshots run after health check / 5s alive check, which already exists in milestone checkpoint flow.
- [Risk] Large emails with many screenshots → Mitigation: Cap at 5 URLs max. Resize to reasonable viewport (1280x720 default). PNG compression is sufficient.
- [Risk] SPA pages need time to render → Mitigation: `wait_after_load` directive (default 2s) gives JS time to hydrate before capture.
