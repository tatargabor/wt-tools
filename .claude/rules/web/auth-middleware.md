---
description: Auth middleware patterns for web frameworks — route protection, redirect logic
globs:
  - "middleware.{ts,tsx,js,jsx}"
  - "src/middleware.{ts,tsx,js,jsx,py}"
  - "app/middleware.{ts,tsx,js,jsx,py}"
  - "server/middleware/**"
  - "lib/auth/**"
  - "utils/auth/**"
---

# Auth Middleware Patterns

When a spec requires "admin pages" or "protected routes", you MUST create auth middleware — not just auth check functions.

## Pattern: Route Protection Middleware

The middleware runs BEFORE route handlers. It checks auth and redirects or returns 401.

### General pattern (any framework):

```
function authMiddleware(request):
  path = request.url.pathname

  # Define protected route prefixes
  protectedPrefixes = ["/admin", "/dashboard", "/account", "/api/protected"]

  # Check if current path needs protection
  if not any(path.startsWith(p) for p in protectedPrefixes):
    return next()  # public route, pass through

  # Check authentication
  session = getSession(request)
  if not session or not session.isValid():
    if isApiRoute(path):
      return Response(401, { error: "Unauthorized" })
    else:
      return redirect("/login?from=" + encodeURIComponent(path))

  return next()  # authenticated, proceed
```

### Key requirements:

1. **Create the middleware file** — it won't exist by default. This is the most common omission.
2. **Register it** — add to framework config (Express `app.use()`, Next.js root `middleware.ts`, Django `MIDDLEWARE` list, FastAPI `@app.middleware`)
3. **Match protected paths** — use prefix matching, not exact paths (new sub-routes auto-protected)
4. **Preserve redirect target** — save the original URL so user returns after login
5. **Handle API vs page routes differently** — APIs return 401 JSON, pages redirect to login

## Common mistakes:

- Creating login/register pages but no middleware → direct URL access bypasses auth
- Auth check only in layout/component → server-side rendering still processes the full page
- Redirecting to `/login` without preserving the original URL → bad UX
- Forgetting to handle `/api/*` routes under the same middleware → API endpoints unprotected

## E2E test requirement:

Any auth middleware MUST have a "cold visit" E2E test:
```
test('unauthenticated visit to /admin redirects to /login', async ({ page }) => {
  await page.goto('/admin')
  await expect(page).toHaveURL(/\/login/)
})
```
