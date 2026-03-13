## Context

170 spec auditálása után kiderült, hogy sok change és hotfix történt OpenSpec workflow-n kívül. A specek elszinkronizálódtak a kódtól. A kód az igazság forrása — a speceket kell igazítani.

Kategóriák:
- **10 DRIFT spec** — kód és spec nem egyezik
- **1 hiányzó spec** — wt-merge (724 sor, 0 spec)
- **2 OBSOLETE spec** — deprecated, lecserélve
- **1 TBD Purpose** — orchestration-config

## Goals / Non-Goals

**Goals:**
- Minden módosított spec pontosan tükrözze a kód jelenlegi viselkedését
- Új spec a wt-merge-hez ami dokumentálja az összes létező feature-t
- Deprecated specek ARCHIVED jelölése
- Specek használhatóak legyenek fejlesztési referenciának

**Non-Goals:**
- Kód módosítás — SEMMI kód nem változik
- Aspirational feature-ök implementálása — csak a spec-et igazítjuk
- Hiányzó feature-ök hozzáadása — ha a kód nem csinálja, a spec sem kéri
- Nem auditált specek javítása

## Decisions

1. **editor-integration: keystroke automation törlése spec-ből**
   Indok: A xdotool/osascript keystroke delivery és WM_CLASS window finding soha nem volt implementálva. A kód thin wrapper az editor CLI körül + manual tip. A spec-et a valósághoz igazítjuk.

2. **merge-conflict-fingerprint és agent-merge-resolution: ASPIRATIONAL jelölés**
   Indok: Ezek a feature-ök a spec-ben vannak de soha nem lettek implementálva. Ahelyett hogy töröljük, ASPIRATIONAL-nak jelöljük — hasznos backlog item-ek lehetnek.

3. **wt-merge: önálló spec létrehozása**
   Indok: A tool 724 soros, komplex LLM-based conflict resolution-nel, JSON deep merge-gel, additive resolver-rel. Eddig semmilyen spec nem dokumentálta.

4. **Delta spec vs. teljes spec átírás**
   Megközelítés: Delta spec-eket használunk (MODIFIED/ADDED/REMOVED sections) ahol létező spec van. Új capability-nek (merge-worktree) teljes spec-et írunk.

## Risks / Trade-offs

- [Risk] Delta spec merge hiba archiváláskor → Mitigation: pontos header matching a meglévő requirement nevekhez
- [Risk] Túl sok spec módosítás egy change-ben → Mitigation: minden módosítás független, sorrendtől független
