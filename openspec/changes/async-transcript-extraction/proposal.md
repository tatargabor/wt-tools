## Why

The `wt-hook-memory-save` Stop hook currently runs transcript-based LLM extraction (haiku call) synchronously, blocking Claude Code for 5-15 seconds after every response. In automated benchmark loops (`wt-loop`), this adds ~2-5 minutes of total overhead across 15-20 iterations. Since accuracy matters more than speed, the extraction itself is valuable — but the blocking is unnecessary.

## What Changes

Move the transcript extraction (haiku LLM call + memory save) to a background process. The Stop hook will fork the extraction, write a lockfile, and exit immediately. The extraction runs asynchronously — no blocking, no lost insights.

The commit-based design choice extraction (Path 2) remains synchronous since it's fast (<1s).

## Capabilities

### New Capabilities
- `async-extraction`: Background transcript processing with lockfile-based concurrency control

### Modified Capabilities
- None (the extraction logic itself is unchanged — only the execution model changes)

## Scope

- **In scope**: Making `extract_from_transcript()` run in background, lockfile to prevent concurrent runs, cleanup of temp/lock files
- **Out of scope**: Changing extraction logic, prompt, model selection, or memory save format
