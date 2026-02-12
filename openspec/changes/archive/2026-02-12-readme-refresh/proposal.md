## Why

The current README.md is detailed about GUI and basic CLI but missing key information: platform/editor support status, many CLI tools are undocumented, there's no clear project introduction for newcomers, and no known issues section. Documentation generation has no stored instructions, so each README update is ad-hoc. We need a README guide that defines the structure and rules, then a refreshed README that follows it.

## What Changes

- Create `docs/readme-guide.md` — a stored set of instructions defining what the README must contain, its structure, tone, and mandatory sections. This serves as the source of truth for future README generation/updates.
- Rewrite `README.md` following the guide:
  - Add clear project introduction (what it is, who it's for)
  - Add Platform & Editor Support section (Linux primary, macOS supported, Zed primary editor)
  - Document all CLI tools from `bin/` (currently ~10 are undocumented)
  - Add Known Issues & Limitations section
  - Restructure for scannability (overview first, details later)
  - Update architecture diagram
- Update `docs/config.md` to reference the new guide

## Capabilities

### New Capabilities
- `readme-guide`: Instructions and rules for README generation — defines mandatory sections, structure template, tone/style rules, platform/editor info requirements, and update checklist.

### Modified Capabilities
- `opensource`: Update English Documentation requirement to reference the readme-guide as the source of truth for README structure.

## Impact

- `docs/readme-guide.md` — new file
- `README.md` — full rewrite
- `docs/config.md` — updated references
- `openspec/specs/opensource/spec.md` — minor delta (reference to guide)
