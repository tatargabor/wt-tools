# Pi (pi-mono) vs wt-tools — Összehasonlító elemzés

> **Dátum:** 2026-03-08
> **Források:** [github.com/badlogic/pi-mono](https://github.com/badlogic/pi-mono) · [pi.dev](https://pi.dev/)
> **Szerző:** Mario Zechner (badlogic) — a libGDX keretrendszer alkotója

---

## 1. Mi a Pi?

Pi egy **minimális, maximálisan bővíthető terminál-alapú AI coding agent**, TypeScript monorepo-ként implementálva. A filozófiája: "There are many coding agents, but this one is mine." MIT licensz, teljesen nyílt forráskódú. **21.1k GitHub star, 140 contributor, 3,157 commit** (2026. március).

Zechner a Claude Code-ot kritizálva építette: "turned into a spaceship with 80% of functionality I have no use for." A projekt tudatosan **nem** építi be a legtöbb funkciót a magba — ehelyett egy erős extension rendszert ad, amivel bármi felépíthető. Ez az alapvető szemléleti különbség a wt-tools-hoz képest.

**Radikális döntések:**
- **~900 tokenes system prompt** (vs Claude Code ezres nagyságrendje) — a logika: frontier modellek RL-tréninggel már tudják mi a dolguk
- **YOLO mód alapértelmezetten** — nincs permission popup ("ha írhat és futtathat kódot, game over"), konténerizálj ha kell
- **Anti-MCP álláspontot** képvisel — szerinte az MCP serverek túl sok tokent fogyasztanak (pl. Playwright MCP = 13.7k token csak tool definíciókra), helyette CLI tool + README mint Skill (225 token)

---

## 2. Architektúra összehasonlítás

### Pi monorepo csomagok

```
pi-mono/
├── packages/ai/           — Unified multi-provider LLM API
├── packages/agent/        — Agent runtime (tool calling, state, events)
├── packages/coding-agent/ — A terminál coding agent (a fő termék)
├── packages/tui/          — Terminal UI könyvtár (differential rendering)
├── packages/web-ui/       — Web-alapú chat komponensek
├── packages/mom/          — Slack bot (pi-mom)
└── packages/pods/         — GPU pod menedzsment (vLLM deployment)
```

### wt-tools struktúra

```
wt-tools/
├── bin/                   — CLI eszközök (bash)
├── lib/                   — Megosztott könyvtárak (bash)
├── .claude/skills/        — OpenSpec és wt skillek
├── .claude/commands/      — Slash commandok
├── hooks/                 — Claude Code hook rendszer
├── gui/                   — PySide6 Control Center
├── shodh-memory/          — RocksDB-alapú memória backend
└── benchmark/             — MemoryProbe szintetikus benchmark
```

### Összehasonlítás

| Szempont | Pi | wt-tools |
|----------|-----|----------|
| **Nyelv** | TypeScript (teljes) | Bash + Python (GUI, memory) |
| **Típus** | Önálló coding agent | Claude Code kiegészítő toolkit |
| **LLM integráció** | Saját multi-provider API | Claude Code-ra épít |
| **Futtatási mód** | Standalone alkalmazás | Claude Code pluginként |
| **Telepítés** | `npm install -g` | `git clone + install.sh` |
| **Licensz** | MIT | MIT |

---

## 3. Feature-by-Feature összehasonlítás

### 3.1 LLM Provider támogatás

| | Pi | wt-tools |
|---|---|---|
| **Anthropic** | API + Pro/Max subscription OAuth | Claude Code-on keresztül |
| **OpenAI** | API + ChatGPT Plus/Pro OAuth | — |
| **Google** | Gemini, Vertex, Antigravity | — |
| **Azure** | OpenAI Responses API | — |
| **Bedrock** | Amazon Bedrock | — |
| **Mistral, Groq, xAI** | Mind támogatott | — |
| **Lokális modellek** | Ollama, LM Studio, vLLM | — |
| **Modellváltás** | Mid-session, hot-swap | Claude Code feature |
| **Saját provider** | Extension-nel regisztrálható | — |

**Értékelés:** Pi itt **messze előrébb jár** — 20+ provider natívan. De ez azért van, mert Pi egy teljes agent, míg wt-tools a Claude Code ökoszisztémára épít. Nekünk ez nem probléma, amíg Claude Code-ot használunk, de ha más LLM-ekre is szükség lenne, Pi megközelítése értékes.

### 3.2 Extension / Plugin rendszer

#### Pi Extensions

```typescript
// TypeScript extension — teljes API hozzáférés
export default function myExtension(pi: ExtensionAPI) {
  // Egyedi tool regisztráció
  pi.registerTool("my-tool", { ... });

  // Életciklus események
  pi.on("agent_start", (ctx) => { ... });
  pi.on("tool_call", (ctx) => { ... });     // Intercept + block
  pi.on("tool_result", (ctx) => { ... });   // Modify results
  pi.on("session_compact", (ctx) => { ... });

  // UI interakció
  pi.on("some_event", async (ctx) => {
    const answer = await ctx.ui.select(["option1", "option2"]);
    ctx.ui.notify("Done!");
    ctx.ui.setWidget("my-widget", myComponent);
  });

  // Parancsok, billentyűk
  pi.registerCommand("/my-cmd", handler);
  pi.registerShortcut("ctrl+k", handler);
}
```

**Pi extension képességek:**
- 22 typed hook event (session, agent, tool, input, model)
- Egyedi tool-ok regisztrálása amit az LLM hívhat
- Tool hívások interceptálása és blokkolása
- Tool eredmények módosítása (chaining)
- Custom UI komponensek (TUI widgetek)
- Parancsok, billentyűparancsok regisztrálása
- Provider regisztráció (egyedi LLM provider)
- Session state perzisztálás
- Hot-reload (`/reload`)
- npm/git csomagolás és megosztás

#### wt-tools Plugins

```bash
# Bash/Markdown alapú plugin rendszer
.claude/
├── skills/           — SKILL.md fájlok (prompt injection)
├── commands/         — Slash command markdown fájlok
└── hooks/           — settings.json hook definíciók
```

**wt-tools plugin képességek:**
- Skills: Markdown prompt template-ek
- Commands: Slash parancsok (markdown)
- Hooks: 5 lifecycle event (SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop)
- MCP server: Tool-ok kiajánlása
- Nincs tool interceptálás
- Nincs UI widget rendszer
- Nincs hot-reload (restart szükséges)

**Értékelés:** Pi extension rendszere **lényegesen erősebb**. TypeScript API, typed events, UI widgetek, tool interceptálás, hot-reload. A wt-tools hook rendszere funkcionálisan behatároltabb, de az 5-layer memory hook minta innovatív — Pi-nek nincs hasonló automatizált memória pipeline-ja.

### 3.3 Memória / Kontextus kezelés

#### Pi kontextus kezelés

```
┌─────────────────────────────────────────┐
│            Pi Context System            │
├─────────────────────────────────────────┤
│ AGENTS.md / SYSTEM.md — projekt context │
│ Auto-compaction — régebbi üzenetek      │
│   összefoglalása LLM-mel                │
│ Branch summarization — ág váltáskor     │
│   az elhagyott ág összefoglalása        │
│ Skills — on-demand betöltés             │
│ Extensions — context injection hookok   │
│ Prompt templates — újrahasználható      │
│ Session tree — elágazó beszélgetések    │
└─────────────────────────────────────────┘
```

**Pi jellemzők:**
- Session-en belüli: auto-compaction (trigger: `contextTokens > contextWindow - 16384 reserve`)
- Összefoglaló struktúra: Goal / Constraints / Progress (Done/InProgress/Blocked) / Key Decisions / Next Steps + `<read-files>` és `<modified-files>` XML
- Token becslés: `chars / 4` heurisztika, valós `usage` adattal ahol elérhető
- Tree-based session: elágazó beszélgetések egyetlen JSONL fájlban (`id/parentId` tree, leaf pointer)
- Branch summary: ág váltáskor az elhagyott ág kontextusának LLM összefoglalása
- Split-turn compaction: ha egy turn túl nagy, párhuzamos összefoglalót generál (history + turn prefix) és merge-öli
- `transformContext` hook: extension-ek módosíthatják az `AgentMessage[]` tömböt minden LLM hívás előtt
- **Nincs cross-session memória** (sem embedding, sem RAG, sem automatikus tudásmentés)
- Mom (Slack bot) használ `MEMORY.md` fájlokat — de a coding agent nem

#### wt-tools memória rendszer

```
┌─────────────────────────────────────────┐
│         wt-tools Memory System          │
├─────────────────────────────────────────┤
│ 5-Layer Hook Pipeline:                  │
│ L1: Session warmstart (cheat-sheet)     │
│ L2: Prompt-based topic recall           │
│ L3: Hot-topic pre-tool injection        │
│ L4: Error-triggered recall              │
│ L5: Session-end extraction (Haiku)      │
├─────────────────────────────────────────┤
│ shodh-memory backend:                   │
│ • RocksDB + vector embeddings           │
│ • Semantic search (5 recall mód)        │
│ • Typed: Decision / Learning / Context  │
│ • Branch awareness                      │
│ • Phase tags (orchestration)            │
│ • Rules: deterministic keyword-based    │
├─────────────────────────────────────────┤
│ Cross-session, cross-worktree, cross-   │
│ machine (sync push/pull via git)        │
├─────────────────────────────────────────┤
│ Benchmark: +34% convention compliance   │
│ Metrics dashboard, audit, dedup         │
└─────────────────────────────────────────┘
```

**Értékelés:** wt-tools memória rendszere **egyértelműen fejlettebb**. Pi-nek nincs cross-session memóriája — minden session nulláról indul. A wt-tools 5-layer automatizált pipeline-ja, a szemantikus keresés, branch awareness, phase tags, és a benchmark-kal igazolt +34% javulás kategóriákkal előrébb van. Ez a wt-tools egyedi erőssége.

### 3.4 Multi-Agent / Orchestráció

#### Pi multi-agent megközelítés

```
Pi subagent extension (example/extension):
┌────────────┐
│  Fő agent  │
└─────┬──────┘
      │ spawn pi subprocess
      ▼
┌────────────┐  ┌────────────┐  ┌────────────┐
│   Scout    │  │  Planner   │  │   Worker   │
│ (read-only)│  │ (read-only)│  │ (coding)   │
└────────────┘  └────────────┘  └────────────┘

Módok:
- Single: 1 agent, 1 feladat
- Parallel: max 8 task, 4 concurrent
- Chain: A → B → C ({previous} placeholder)

Beépített workflow-k:
- /implement: scout → planner → worker
- /scout-and-plan: scout → planner
- /implement-and-review: worker → reviewer → worker
```

**Fontos:** Ez nem beépített feature, hanem egy **example extension**! A Pi core szándékosan nem tartalmaz sub-agent támogatást.

**Pi agent loop technikai részlet:** Az agent loop-nak két független message queue-ja van:
- **Steering**: tool végrehajtás közben interrupt-ol, a hátralévő tool hívásokat skip-eli
- **Follow-up**: az agent leállása után folytatja (multi-turn autonomous viselkedés)
- Mindkettő "all" vagy "one-at-a-time" drain módot támogat
- Tool végrehajtás szekvenciális, abort támogatással
- Hibák tool result-ként jelennek meg (nem exception)

#### wt-tools orchestráció

```
wt-tools orchestráció:
┌──────────────┐
│   Sentinel   │ — supervisor, crash recovery, auto-approve
└──────┬───────┘
       │
┌──────▼───────┐
│ Orchestrator │ — spec decomposition, dependency graph
└──────┬───────┘
       │ dispatch (per-worktree)
       ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│ Ralph #1 │ │ Ralph #2 │ │ Ralph #3 │  — autonomous loops
│ worktree │ │ worktree │ │ worktree │
└────┬─────┘ └────┬─────┘ └────┬─────┘
     │             │             │
     └─────────────┴─────────────┘
                   │
            Merge + Verify gates
```

**wt-tools jellemzők:**
- Sentinel: felügyeli az orchestrátort, crash recovery
- Spec decomposition: LLM-alapú feladatfelbontás dependency graph-fal
- Git worktree izoláció: minden change saját worktree
- Ralph loop: autonomous iteration + completion detection
- Merge policy: checkpoint, final, auto
- Verification gates: verify + smoke test before merge
- Phase-aware memory: planning vs execution vs verification recall
- OpenSpec artifact tracking: proposal → design → specs → tasks
- Cross-machine team sync + agent messaging

**Értékelés:** wt-tools orchestrációja **production-grade**, Pi-é **demo/example szintű**. A sentinel, dependency-aware dispatch, verification gates, és phase-aware memory kombinációja egy teljes CI/CD-jellegű pipeline — Pi subagent extension-je inkább ad-hoc task delegation.

### 3.5 Session kezelés

| Szempont | Pi | wt-tools |
|----------|-----|----------|
| **Perzisztálás** | JSONL fájlok | Claude Code natív |
| **Session tree** | Elágazó beszélgetések, `/tree` navigáció | — (Claude Code nem támogatja) |
| **Branching** | `/fork` és `/tree` — ugyanabban a fájlban | — |
| **Compaction** | LLM összefoglaló, fájl tracking, turn-aware | Claude Code saját compaction |
| **Branch summary** | Ág váltáskor az elhagyott ág összefoglalása | — |
| **Export** | HTML, gist, szűrhető | — |
| **Bookmarks** | Label entry-k | — |

**Értékelés:** Pi session kezelése **innovatív** — a tree-based branching és a branch summarization egyedülálló. Ezek a funkciók valódi értéket adnának bármely coding agent-nek. wt-tools a Claude Code-ra bízza a session kezelést, ami korlátozottabb.

### 3.6 Beépített eszközök (Tools)

| Tool | Pi | wt-tools (via Claude Code) |
|------|-----|----------------------------|
| Read | beépített | beépített |
| Write | beépített | beépített |
| Edit | beépített (diff-based) | beépített |
| Bash | beépített | beépített |
| Grep | beépített | beépített |
| Find/Glob | beépített | beépített |
| Ls | beépített | — (Bash-on keresztül) |
| Agent (sub-agent) | extension | beépített |
| WebFetch | — | beépített |
| WebSearch | — | beépített |
| Notebook | — | beépített |
| MCP tools | extension-nel | natív + wt-tools MCP server |

**Értékelés:** Nagyjából azonos alapkészlet. Pi szándékosan minimális (4 core tool), Claude Code gazdagabb beépített készlettel rendelkezik.

### 3.7 Mód-ok és integráció

| Mód | Pi | wt-tools |
|-----|-----|----------|
| **Interactive TUI** | Saját TUI (pi-tui csomag) | Claude Code TUI |
| **Print/JSON** | Nem-interaktív kimenet | Claude Code `--print` |
| **RPC** | JSONL stdin/stdout protokoll | — |
| **SDK** | TypeScript API beágyazáshoz | — |
| **Web UI** | pi-web-ui csomag | — |
| **Slack bot** | pi-mom | — |
| **GPU pod mgmt** | pi-pods (vLLM) | — |
| **GUI** | — | PySide6 Control Center |

**Értékelés:** Pi **több integrációs módot** kínál (RPC, SDK, Web UI, Slack bot). wt-tools-nak van GUI-ja, ami Pi-nek nincs. A pi-pods (GPU menedzsment) teljesen egyedi képesség.

---

## 4. Szemléleti különbségek

### Pi filozófia: "Extension-first minimalizmus"

```
Szándékosan KIZÁRT beépített funkciók:
✗ Sub-agent-ek          → extension-nel megoldható
✗ Plan mód              → extension-nel megoldható
✗ Permission popupok    → extension-nel megoldható
✗ MCP                   → extension-nel megoldható
✗ Beépített todo        → extension-nel megoldható
✗ Background bash       → extension-nel megoldható
✗ Cross-session memory  → senki nem építette meg
```

**Előny:** Kis, áttekinthető core. Felhasználó alakítja a saját élményét.
**Hátrány:** Sok fontos funkció "extension-nel megoldható" de nincs megcsinálva. A memory például csak session-en belül létezik.

### wt-tools filozófia: "Batteries-included workflow toolkit"

```
Beépített és integrált:
✓ Multi-agent orchestráció (sentinel, Ralph)
✓ Cross-session memory (+34% benchmark)
✓ OpenSpec workflow (proposal → deploy)
✓ Git worktree menedzsment
✓ GUI (Control Center)
✓ Team sync & messaging
✓ MCP server
✓ 5-layer memory hooks
✓ Metrics & benchmarking
```

**Előny:** Teljes, production-ready workflow. Nem kell összeszedni a darabokat.
**Hátrány:** Nagyobb komplexitás, erősebb kötődés a Claude Code-hoz.

---

## 5. Amit érdemes lenne átvenni Pi-tól

### 5.1 Extension/Plugin API — MAGAS PRIORITÁS

Pi extension rendszere a **legfontosabb tanulság**. Jelenleg a wt-tools plugin rendszere: SKILL.md (prompt), command markdown, és bash hook-ok. Pi-ben:

- Typed TypeScript API teljes hozzáféréssel
- 30+ hook event (vs wt-tools 5)
- Tool interceptálás és eredmény módosítás
- Custom UI widgetek
- Hot-reload
- npm/git csomagolás

**Javaslat:** Nem kell lemásolni Pi-t, de egy erősebb plugin API a hook rendszeren túl értékes lenne. Prioritás:
1. Tool result modification hook-ok (a jelenlegi PostToolUse csak olvas, nem módosít)
2. Custom MCP tool regisztráció plugin-ból
3. Plugin csomagolás és megosztás (`wt-plugin install <git-url>`)

### 5.2 Session Tree / Branching — KÖZEPES PRIORITÁS

Pi session tree-je lehetővé teszi:
- Visszalépés egy korábbi pontra és más irányba indulás
- Branch summary: az elhagyott ág kontextusának megőrzése
- Navigáció az egész session fán belül

Ez Claude Code-ban nem implementálható közvetlenül (a session kezelés zárt), de az elv alkalmazható:
- **OpenSpec branching:** Egy change-en belül design alternatívák fán
- **Orchestration replanning:** Kudarcnál ne nulláról, hanem a döntési fáról induljon

### 5.3 RPC mód / SDK — KÖZEPES PRIORITÁS

Pi RPC módja JSONL stdin/stdout protokollal lehetővé teszi:
- Nyelv-agnosztikus integráció (Python, Go, stb.)
- IDE beágyazás
- Custom frontend-ek

**Javaslat:** Az MCP server már ad egy API felületet, de egy egyszerűbb RPC interfész a wt-tools funkciókhoz (worktree management, memory, orchestration state) hasznos lenne külső integrációkhoz.

### 5.4 Multi-Provider AI API — ALACSONY PRIORITÁS (jelenleg)

Pi `@mariozechner/pi-ai` csomagja egységes API-t ad 20+ LLM providerhez. Ez jelenleg nem releváns (Claude Code-ot használunk), de ha a jövőben más LLM-ekre is szükség lenne az orchestrációban (pl. olcsóbb modellek task routing-ra), ez a minta értékes.

### 5.5 Compaction finomhangolás — ALACSONY PRIORITÁS

Pi compaction-ja néhány elemet jobban csinál:
- **Fájl tracking:** Kompakció során nyilvántartja, mely fájlokat olvasta/módosította az agent
- **Turn-aware cutting:** Ha a vágáspont egy tool hívás közepére esik, két összefoglalót generál
- **Branch summary injection:** Ág váltáskor az előző ág kontextusa bekerül az újba

Ezek apró de hasznos finomítások. A Claude Code saját compaction-ja korlátozottabb, de a wt-tools memory rendszere (L1-L5) részben kompenzálja ezt.

### 5.6 Prompt Templates — ALACSONY PRIORITÁS

Pi prompt template-jei markdown fájlok argumentum-substitúcióval (`$1`, `$@`, `${@:N:L}`). Ez lényegében megegyezik a wt-tools SKILL.md rendszerével, szóval nincs nagy tanulság.

### 5.7 Web UI komponensek — PERSPEKTIVIKUS

Pi `pi-web-ui` csomagja böngészőben futó chat komponenseket ad. Ha a wt-tools GUI-t webre migrálnánk (PySide6 → web), ez hasznos referencia.

### 5.8 Slack bot (pi-mom) — PERSPEKTIVIKUS

Pi-mom egy LLM-powered Slack bot ami bash-t futtat, fájlokat kezel, és memóriát tart. Ha a wt-tools-hoz Slack integrációt adnánk (orchestration notifications, remote triggering), pi-mom jó kiindulás.

---

## 6. Amit Pi-nek érdemes lenne tőlünk átvennie

| Funkció | Mi van nálunk | Mi van Pi-nál |
|---------|---------------|---------------|
| **Cross-session memory** | 5-layer hook, semantic search, +34% | Semmi |
| **Orchestráció** | Sentinel, dependency graph, Ralph loops | Example extension |
| **Worktree izoláció** | Natív, integrált | Nincs |
| **Team sync** | Git-branch alapú, encrypted | Nincs |
| **OpenSpec workflow** | Proposal → archive pipeline | Nincs (skills van) |
| **Memory benchmark** | MemoryProbe szintetikus + real-world | Nincs |
| **GUI** | PySide6 Control Center | Nincs |
| **Memory sync** | Git orphan branch push/pull | Nincs |
| **Rules rendszer** | Deterministic keyword-match injection | Nincs |
| **Phase-aware recall** | Planning vs execution vs verification | Nincs |

---

## 7. Összefoglaló mátrix

```
                        Pi                    wt-tools
                        ─────────────────     ─────────────────
Önálló agent            ████████████████ 10   ░░░░░░░░░░░░░░░░  0
  (Pi standalone,       (Claude Code
   wt-tools plugin)      kiegészítő)

Extension rendszer      ████████████████  9   ████░░░░░░░░░░░░  3
  (typed API, 30+       (bash hooks,
   events, hot-reload)   5 events, SKILL.md)

LLM provider            ████████████████ 10   ██░░░░░░░░░░░░░░  1
  (20+ provider,        (Claude Code only)
   OAuth, hot-swap)

Cross-session memory    ░░░░░░░░░░░░░░░░  0   ████████████████ 10
  (nem létezik)          (5-layer, semantic,
                          +34% benchmark)

Orchestráció            ██░░░░░░░░░░░░░░  2   ████████████████  9
  (example extension)    (sentinel, Ralph,
                          dependency graph)

Session mgmt            ████████████████  9   ████░░░░░░░░░░░░  3
  (tree, branch,         (Claude Code natív)
   compaction, export)

GUI                     ░░░░░░░░░░░░░░░░  0   ████████████████  8
  (nincs)                (PySide6 Control
                          Center)

Team sync               ░░░░░░░░░░░░░░░░  0   ████████████░░░░  7
  (nincs)                (git branch,
                          encrypted chat)

Integrációs módok       ████████████████  9   ████████░░░░░░░░  5
  (RPC, SDK, Web UI,    (MCP server,
   Slack bot, pods)       CLI, GUI)

Workflow framework      ████████░░░░░░░░  5   ████████████████  9
  (skills, templates)    (OpenSpec pipeline,
                          proposal→archive)

Dokumentáció            ████████████████  9   ████████████░░░░  7
  (docs/, 50+ example   (docs/, de kevesebb
   extensions)            example)
```

---

## 8. Konklúzió

Pi és wt-tools **fundamentálisan más problémát oldanak meg**:

- **Pi** = egy coding agent ami bármilyen LLM-mel működik, maximálisan testreszabható extension rendszerrel. **Horizontális**: széles provider támogatás, sok integráció, minimális core.

- **wt-tools** = egy Claude Code-ra épülő workflow toolkit ami multi-agent orchestrációt, cross-session memóriát, és spec-driven fejlesztést ad. **Vertikális**: egy LLM-en mély integráció, production workflow.

**A két projekt nem versenyez** — inkább kiegészítik egymást. Pi extension rendszere és integrációs módjai inspirálhatják a wt-tools plugin fejlesztését, míg a wt-tools memória rendszere és orchestrációja olyan területek ahol Pi még nem járt.

### Top 3 actionable tanulság

1. **Extension API erősítése** — A jelenlegi hook rendszer (5 event) túl szűk. Tool result modification, custom tool regisztráció, és plugin csomagolás a következő lépések.
2. **Session tree gondolat alkalmazása** — Nem a Claude Code session-re, hanem az OpenSpec decision tree-re: design alternatívák, orchestration replan ágak.
3. **RPC/API réteg** — A wt-tools funkciók (memory, worktree, orchestration) programozható API-n keresztüli elérése külső integrációkhoz.
