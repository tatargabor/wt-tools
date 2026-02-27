# Project Brief

## Purpose

Sample project for orchestrator testing. Three features with a dependency chain.

## Tech Stack

- Bash scripts
- Plain text files

## Domain Context

A trivial project that creates text files. Used to validate orchestrator decomposition, dispatch, and merge pipeline.

## Feature Roadmap

### Done
- Project skeleton created

### Next
- Feature Alpha: Create alpha.txt with content "Hello from Alpha". Independent, no dependencies.
- Feature Beta: Create beta.txt that imports a value from alpha.txt. Depends on Feature Alpha being complete.
- Feature Charlie: Create charlie.txt with content "Hello from Charlie". Independent, can run in parallel with Alpha.

### Ideas
- Feature Delta: Combine all text files into a summary

## Orchestrator Directives
- max_parallel: 2
- merge_policy: eager
- checkpoint_every: 2
- test_command: test -f alpha.txt && test -f beta.txt && test -f charlie.txt
- notification: none
- token_budget: 50000
- pause_on_exit: false
