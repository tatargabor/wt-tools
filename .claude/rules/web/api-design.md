---
description: Web API design patterns — error handling, response format, rate limiting
globs:
  - "app/api/**/*.{ts,tsx,js,jsx}"
  - "pages/api/**/*.{ts,tsx,js,jsx}"
  - "routes/**/*.{ts,tsx,js,jsx,py}"
  - "api/**/*.{ts,tsx,js,jsx,py}"
  - "server/**/*.{ts,tsx,js,jsx,py}"
---

# Web API Design Patterns

## 1. Consistent Error Responses

All API routes MUST return structured error responses, not raw strings or stack traces.

```json
{
  "error": "Human-readable message",
  "code": "MACHINE_READABLE_CODE"
}
```

- 400: validation errors (include field-level details)
- 401: not authenticated
- 403: authenticated but not authorized
- 404: resource not found (after ownership check — never leak existence)
- 500: internal error (log details server-side, return generic message to client)

## 2. Request Validation

Validate ALL request inputs before business logic:

```
// Parse and validate
const body = schema.parse(await request.json())  // throws on invalid

// Then proceed with validated data
const result = await db.thing.create({ data: body })
```

Never pass raw `request.body` or `request.query` directly to database queries.

## 3. Resource Access Pattern

For any endpoint that accesses a resource by ID:

```
GET    /api/things/:id  → find by id + ownerCheck → 404 if not found or not owned
PUT    /api/things/:id  → find by id + ownerCheck → validate body → update
DELETE /api/things/:id  → find by id + ownerCheck → delete
```

**ownerCheck**: the query includes the authenticated user's ID in the WHERE clause. If the resource doesn't exist OR belongs to someone else, return the same 404 — never reveal whether a resource exists for another user.

## 4. Pagination

List endpoints MUST support pagination:

```
GET /api/things?page=1&limit=20
```

- Default limit: 20, max limit: 100
- Return total count for UI pagination
- Always scope by owning entity (user/org)

## 5. Idempotency

- GET/HEAD: always safe and idempotent
- PUT: idempotent (same request = same result)
- POST: not idempotent — use idempotency keys for payment/order creation if needed
- DELETE: idempotent (deleting already-deleted = 204, not 404)
