import { test } from "@playwright/test";

// Capture screenshots of key pages for the E2E report.
// Run via: pnpm exec playwright test capture-screenshots.ts

const pages = [
  { name: "storefront", path: "/products" },
  { name: "cart", path: "/cart" },
  { name: "orders", path: "/orders" },
  { name: "admin-login", path: "/admin" },
  { name: "admin-products", path: "/admin/products" },
];

for (const { name, path } of pages) {
  test(`screenshot: ${name}`, async ({ page }) => {
    await page.goto(`http://localhost:3000${path}`, {
      waitUntil: "networkidle",
      timeout: 10000,
    });
    await page.screenshot({
      path: `e2e-screenshots/${name}.png`,
      fullPage: true,
    });
  });
}
