## Why

Sok change és hotfix történt OpenSpec workflow-n kívül, emiatt a specek elszinkronizálódtak a kódtól. A kód az igazság forrása — a speceket kell a kódhoz igazítani. 170 spec auditálása után 10 DRIFT spec, 5 hiányzó spec, és 2 OBSOLETE spec azonosítva.

## What Changes

- **Fix 10 DRIFT spec** — editor-integration, worktree-tools (wt-new, wt-add, wt-close, wt-list), merge-conflict-fingerprint, agent-merge-resolution, smart-memory-recall, orchestration-token-tracking, ralph-team-lifecycle, ralph-team-prompt specs a kód valóságához igazítva
- **Create 1 new spec** — wt-merge (724 sor komplex kód, 0 spec)
- **Archive 2 OBSOLETE specs** — memory-hooks-cli, memory-hooks-gui (header-ben DEPRECATED, kód eltávolítva/lecserélve)
- **Fix orchestration-config** Purpose section (TBD → valós leírás)
- **NO CODE CHANGES** — csak spec fájlok módosulnak

## Capabilities

### New Capabilities
- `merge-worktree`: wt-merge CLI tool specifikációja — LLM conflict resolution, JSON deep merge, additive resolver, squash merge, generated file auto-resolution

### Modified Capabilities
- `editor-integration`: Keystroke automation (xdotool/osascript) és WM_CLASS window finding törlése — kód thin wrapper + manual tip
- `worktree-tools`: wt-new 10+ undokumentált feature hozzáadása (env bootstrap, dep install, hook deploy, --branch/--skip-fetch/--new flags); openspec init requirement törlése; wt-close --keep-branch/--delete-remote hozzáadása; wt-list --remote hozzáadása; wt-add bare repo requirement törlése
- `merge-conflict-fingerprint`: Aspirational-ra jelölés — git merge-tree fingerprint nincs implementálva
- `agent-merge-resolution`: Aspirational-ra jelölés — agent rebase flags nincs implementálva
- `smart-memory-recall`: Memory count guard requirement törlése (kód nem implementálja, spec tiltja is)
- `orchestration-token-tracking`: JSONL fallback requirement törlése (nincs kódban)
- `ralph-team-lifecycle`: Spec szűkítése az implementált funkcionalitásra
- `ralph-team-prompt`: Spec szűkítése az implementált prompt tartalmára
- `orchestration-config`: Purpose section kitöltése
- `memory-hooks-cli`: Archiválás (DEPRECATED)
- `memory-hooks-gui`: Archiválás (DEPRECATED)

## Impact

- Csak `openspec/specs/*/spec.md` fájlok módosulnak
- Kód nem változik
- Új spec: `openspec/specs/merge-worktree/spec.md`
- 2 spec archiválva (tartalma megmarad, de ARCHIVED jelöléssel)
