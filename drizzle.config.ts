import { defineConfig } from "drizzle-kit";

// ═══════════════════════════════════════════════════════════════
// Drizzle Config — D1 (SQLite) for Cloudflare
// ═══════════════════════════════════════════════════════════════
//
// For Cloudflare D1, we use the "sqlite" dialect.
// The actual database connection is handled at runtime via
// the D1 binding (c.env.DB) in functions/[[path]].ts
//
// To generate migrations:
//   npx drizzle-kit generate
//
// To apply migrations to local D1:
//   npx wrangler d1 migrations apply the-vault-db --local
//
// To apply migrations to production D1:
//   npx wrangler d1 migrations apply the-vault-db --remote
// ═══════════════════════════════════════════════════════════════

export default defineConfig({
  schema: "./db/schema.ts",
  out: "./db/migrations",
  dialect: "sqlite",
  driver: "d1-http",
  dbCredentials: {
    // These are only used for drizzle-kit generate/migrate commands
    // Runtime uses the D1 binding directly via c.env.DB
    accountId: process.env.CLOUDFLARE_ACCOUNT_ID || "",
    databaseId: process.env.D1_DATABASE_ID || "",
    token: process.env.CLOUDFLARE_API_TOKEN || "",
  },
});
