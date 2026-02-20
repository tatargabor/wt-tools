# LogBook — Event Logging API

## Business Context

LogBook is a lightweight event logging service. Teams use it to record and track events (deployments, incidents, releases, meetings) organized by categories and tags.

## Tech Stack

- **Runtime**: Node.js (v18+)
- **Framework**: Express
- **Database**: SQLite via `better-sqlite3` (file: `data/logbook.db`). WAL mode enabled for concurrent reads.
- **IDs**: `nanoid` package — prefixed format (see conventions)
- **No ORM** — raw SQL via better-sqlite3
- **Body parsing**: Express `express.json()` middleware (default settings)

## Core Entities

```
Category (cat_*)
  ├── id          TEXT PRIMARY KEY
  ├── name        TEXT NOT NULL
  ├── description TEXT
  ├── removedAt   DATETIME (nullable, soft-delete)
  └── createdAt   DATETIME DEFAULT CURRENT_TIMESTAMP

Event (evt_*)
  ├── id          TEXT PRIMARY KEY
  ├── title       TEXT NOT NULL
  ├── body        TEXT
  ├── categoryId  TEXT REFERENCES Category(id)
  ├── severity    TEXT CHECK(severity IN ('info','warning','critical'))
  ├── removedAt   DATETIME (nullable, soft-delete)
  └── createdAt   DATETIME DEFAULT CURRENT_TIMESTAMP

Tag (tag_*)
  ├── id          TEXT PRIMARY KEY
  └── name        TEXT NOT NULL UNIQUE

EventTag (many-to-many)
  ├── eventId     TEXT REFERENCES Event(id)
  └── tagId       TEXT REFERENCES Tag(id)

Comment (cmt_*)
  ├── id          TEXT PRIMARY KEY
  ├── eventId     TEXT REFERENCES Event(id)
  ├── author      TEXT NOT NULL
  ├── body        TEXT NOT NULL
  ├── removedAt   DATETIME (nullable, soft-delete)
  └── createdAt   DATETIME DEFAULT CURRENT_TIMESTAMP

Notification (ntf_*)
  ├── id          TEXT PRIMARY KEY
  ├── type        TEXT NOT NULL
  ├── message     TEXT NOT NULL
  ├── read        INTEGER DEFAULT 0
  ├── removedAt   DATETIME (nullable, soft-delete)
  └── createdAt   DATETIME DEFAULT CURRENT_TIMESTAMP

Batch (bat_*)
  ├── id          TEXT PRIMARY KEY
  ├── operation   TEXT NOT NULL
  ├── count       INTEGER NOT NULL
  ├── detail      TEXT
  └── createdAt   DATETIME DEFAULT CURRENT_TIMESTAMP
```

## Project Conventions

These conventions are established in Change 01 and MUST be followed by all subsequent code:

1. **Pagination**: All list endpoints return `{entries: [...], paging: {current, size, count, pages}}`. Query params: `?page=1&size=20`.
2. **Errors**: All error responses use `{fault: {reason: string, code: string, ts: string}}`. Codes are SCREAMING_SNAKE.
3. **Soft-delete**: Use `removedAt` column (DATETIME, nullable). Filter `WHERE removedAt IS NULL`.
4. **Date formatting**: `fmtDate(date)` from `lib/fmt.js` returns `YYYY/MM/DD HH:mm`.
5. **IDs**: Prefixed nanoid — `evt_`, `cat_`, `cmt_`, `tag_`, `bat_` + `nanoid(12)`.
6. **Success wrapper**: All 2xx responses include `{ok: true, ...payload}`.

## Project Structure

```
src/
  server.js          # Express app, route mounting, listen
  routes/
    events.js        # /events CRUD
    categories.js    # /categories CRUD
    tags.js          # /tags CRUD (C02)
    comments.js      # /events/:id/comments (C03)
    dashboard.js     # /dashboard (C04)
    export.js        # /export (C04)
    bulk.js          # /bulk (C05)
  db/
    setup.js         # Schema creation, migrations
    events.js        # Event queries
    categories.js    # Category queries
    ...
  lib/
    fmt.js           # fmtDate() helper
    ids.js           # makeId(prefix) helper
  middleware/
    errors.js        # Error handler (fault format)
data/
  logbook.db         # SQLite database (auto-created)
tests/
  test-NN.sh         # Acceptance tests per change
```

## Development

```bash
# Install dependencies
npm install

# Start server (port 3000)
node src/server.js

# Run tests for change N
bash tests/test-0N.sh 3000
```

## Architecture Notes

- **DB query layer**: All SQL queries live in `db/*.js` modules. Route handlers call db functions — they don't write inline SQL.
- **Error middleware**: Centralized error handling in `middleware/errors.js`. Routes throw or call `next(err)` — they don't format error responses themselves.
- **Categories are flat**: No hierarchy, no parent-child relationships.

## Constraints

- SQLite only — no external databases
- No ORM — use better-sqlite3 directly
- No frontend — API-only, tested with curl
- Single-file database at `data/logbook.db`
