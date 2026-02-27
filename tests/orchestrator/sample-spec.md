# SampleApp v2 — Roadmap

> Updated: 2026-02-27

## 1. v1 Status

| Feature | Status |
|---|---|
| User registration | ✅ Done |
| Basic dashboard | ✅ Done |
| File upload | ❌ Not started |
| Payment integration | ❌ Not started |

## 2. Feature Roadmap

### Prioritás 1 — Security & Infrastructure

#### 2.1 Input validation
- Add server-side validation for all API endpoints
- Use zod schema validation
- **Files:** `src/api/*.ts`

#### 2.2 Rate limiting
- Add rate limiting middleware (express-rate-limit)
- 100 requests/minute per IP
- **Files:** `src/middleware/rate-limit.ts`

### Prioritás 2 — Core Features

#### 2.3 File upload system
- Support PDF, CSV, images (max 10MB)
- Store in S3-compatible storage
- **Files:** `src/api/upload.ts`, `src/lib/storage.ts`

#### 2.4 Payment integration
- Stripe integration for subscriptions
- Monthly/yearly plans
- Webhook handler for events
- **Files:** `src/api/payments.ts`, `src/lib/stripe.ts`

#### 2.5 Email notifications
- Transactional emails via SendGrid
- Welcome, payment confirmation, password reset templates
- **Files:** `src/lib/email.ts`, `src/templates/*.html`

### Prioritás 3 — Nice to have

#### 2.6 Dark mode
- Theme toggle in settings
- CSS variables approach

#### 2.7 Export functionality
- CSV and JSON export for user data
- Pagination support for large exports

## 3. Tech Stack

- TypeScript, Express.js, PostgreSQL
- Prisma ORM, React frontend
- S3 for file storage

## Orchestrator Directives
- max_parallel: 2
- merge_policy: checkpoint
- test_command: npm test
- notification: none
