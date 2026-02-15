#!/usr/bin/env bash
# init-with-memory.sh - Bootstrap CraftBazaar for Run B (with memory)
#
# Usage: ./init-with-memory.sh [target-dir]
# Default target: ~/benchmark/run-b/craftbazaar

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WT_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET="${1:-$HOME/benchmark/run-b/craftbazaar}"

# --- Prerequisites ---
missing=()
command -v git >/dev/null || missing+=("git")
command -v node >/dev/null || missing+=("node")
command -v openspec >/dev/null || missing+=("openspec (npm i -g @fission-ai/openspec)")
command -v wt-deploy-hooks >/dev/null || missing+=("wt-deploy-hooks")
command -v wt-memory >/dev/null || missing+=("wt-memory")
command -v wt-memory-hooks >/dev/null || missing+=("wt-memory-hooks")
if [ ${#missing[@]} -gt 0 ]; then
  echo "ERROR: Missing prerequisites: ${missing[*]}" >&2
  exit 1
fi

# --- Check target ---
if [ -d "$TARGET/.git" ]; then
  echo "ERROR: $TARGET already has a git repo. Remove it first or pick a different directory." >&2
  exit 1
fi

echo "=== CraftBazaar Benchmark — Run B (With Memory) ==="
echo "Target: $TARGET"
echo ""

# --- Create and init ---
mkdir -p "$TARGET"
cd "$TARGET"

git init
npm init -y --silent

openspec init --tools claude

# openspec init skips config in non-interactive mode — create it
echo "schema: spec-driven" > openspec/config.yaml

wt-deploy-hooks .

# --- Install memory hooks into OpenSpec skills ---
wt-memory-hooks install

# --- Directories ---
mkdir -p docs/benchmark results

# --- CLAUDE.md (with memory, PORT=3001) ---
cp "$SCRIPT_DIR/claude-md/with-memory.md" ./CLAUDE.md

# --- Project spec (domain context for the agent) ---
cp "$SCRIPT_DIR/project-spec.md" docs/benchmark/project-spec.md

# --- Extract agent-only sections from change definitions ---
for f in "$SCRIPT_DIR"/changes/0*.md; do
  sed '/<!-- EVALUATOR NOTES BELOW/,$d' "$f" > docs/benchmark/"$(basename "$f")"
done

# --- Create OpenSpec changes with proposals ---
for f in "$SCRIPT_DIR"/changes/0*.md; do
  # Derive change name: 01-product-catalog.md -> product-catalog
  change_name=$(basename "$f" .md | sed 's/^[0-9]*-//')

  # Create the change
  openspec new change "$change_name" >/dev/null 2>&1

  # Extract agent input as proposal (everything above EVALUATOR NOTES marker,
  # skipping the first "# Change NN:" header line)
  sed '/<!-- EVALUATOR NOTES BELOW/,$d' "$f" \
    | sed '1{/^# Change/d}' \
    > openspec/changes/"$change_name"/proposal.md

  echo "  ✔ Change: $change_name (proposal ready)"
done

# --- Verify extraction ---
count=$(ls docs/benchmark/0*.md 2>/dev/null | wc -l)
if [ "$count" -ne 6 ]; then
  echo "WARNING: Expected 6 change files, found $count" >&2
fi

if grep -rl "Evaluator Notes" docs/benchmark/*.md 2>/dev/null; then
  echo "ERROR: Evaluator notes leaked into agent-visible files!" >&2
  exit 1
fi

# --- Verify memory ---
if ! wt-memory health >/dev/null 2>&1; then
  echo "WARNING: wt-memory health check failed. Memory may not work during the run." >&2
fi

# --- Initial commit ---
git add -A
git commit -m "Initial CraftBazaar setup (memory run)"

echo ""
echo "=== Done ==="
echo "  Directory: $TARGET"
echo "  CLAUDE.md: with-memory (PORT=3001, proactive memory enabled)"
echo "  Changes:   6 OpenSpec changes with proposals"
echo "  Memory:    hooks installed"
echo ""
echo "Start the run:"
echo "  cd $TARGET"
echo "  wt-loop start \"Build CraftBazaar changes 01-06\" --max 20 --stall-threshold 3 --done manual"
