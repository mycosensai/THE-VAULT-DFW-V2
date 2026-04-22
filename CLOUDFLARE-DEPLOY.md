# The Vault — Cloudflare Deployment Guide

## Overview

This guide covers three ways to deploy The Vault to Cloudflare Pages + D1, ordered from **easiest to most powerful**:

| Method | Requires CLI? | Auto-Deploy? | Best For |
|--------|--------------|--------------|----------|
| **1. Dashboard Upload** | No | Manual drag & drop | Quick one-time deploy |
| **2. GitHub Actions** | No | Push-to-deploy | Ongoing development |
| **3. Wrangler CLI** | Yes | Manual command | Advanced/power users |

---

## What I Built For You

All Cloudflare deployment infrastructure is ready:

| File | Purpose |
|------|---------|
| `wrangler.toml` | Cloudflare Pages + D1 + custom domain config |
| `.github/workflows/deploy-cloudflare.yml` | Auto-deploy on every git push |
| `functions/[[path]].ts` | Edge-compatible API server (replaces Node.js) |
| `db/schema.ts` | D1 (SQLite) Drizzle ORM schema |
| `db/migrations/0000_initial.sql` | Initial database migration |
| `drizzle.config.ts` | D1-compatible Drizzle config |
| `deploy-no-wrangler.sh` | Build script for dashboard upload |

---

## Architecture Changes for Cloudflare

Your app was built for Node.js + MySQL. Here's what changed:

| Before (Node.js) | After (Cloudflare Edge) |
|-----------------|------------------------|
| MySQL (`mysql2`) | **D1 (SQLite)** via `drizzle-orm/d1` |
| Node.js server (`@hono/node-server`) | **Cloudflare Pages Functions** (edge) |
| `process.env` | `c.env` (Cloudflare bindings) |
| Runtime: Single region | **Runtime: 300+ cities worldwide** |
| Cold starts: seconds | **Cold starts: <1ms** |

**The frontend React code does NOT need changes.** Only the backend server needed adaptation.

---

## Pre-Deployment Checklist

Before deploying, you need:

- [ ] **Cloudflare account** (free) — sign up at https://dash.cloudflare.com
- [ ] **Domain** `thevault.win` added to your Cloudflare account
- [ ] **Source code** — your `src/` and `db/` folders (these were missing from the upload!)

---

## Method 1: Dashboard Upload (No CLI — Easiest)

### Step 1: Build

```bash
# In your project folder
npm install
bash deploy-no-wrangler.sh
```

This creates a `cloudflare-upload/` folder.

### Step 2: Create D1 Database

1. Go to https://dash.cloudflare.com
2. Navigate to **Workers & Pages → D1**
3. Click **Create database**
4. Name: `the-vault-db`
5. Click **Create**
6. Copy the **Database ID** (you'll need it later)

### Step 3: Deploy via Dashboard

1. Go to https://dash.cloudflare.com → **Workers & Pages**
2. Click **Create** → **Pages**
3. Select **Upload assets**
4. Project name: `the-vault`
5. Drag the `cloudflare-upload/` folder into the browser
6. Click **Deploy site**

### Step 4: Connect D1 Database

1. In your Pages project, go to **Settings → Functions**
2. Under **D1 database bindings**, click **Add binding**
3. Variable name: `DB`
4. Select your `the-vault-db` database
5. Click **Save**

### Step 5: Add Secrets

1. Go to **Settings → Environment variables**
2. Click **Add variables** for each secret:

| Variable Name | Description | How to Get |
|--------------|-------------|-----------|
| `APP_SECRET` | JWT signing secret | `openssl rand -base64 32` |
| `STRIPE_SECRET_KEY` | Stripe payments | Stripe Dashboard → API keys |
| `VITE_STRIPE_PUBLISHABLE_KEY` | Stripe frontend | Stripe Dashboard → API keys |
| `OPENAI_API_KEY` | AI chat | OpenAI Dashboard |

### Step 6: Add Custom Domain

1. Go to **Custom domains**
2. Click **Set up a custom domain**
3. Enter: `thevault.win`
4. Cloudflare auto-configures DNS
5. Repeat for `www.thevault.win` (redirects to root)

---

## Method 2: GitHub Actions (Recommended — Push to Deploy)

This is the **best long-term solution**. Push code to GitHub, it auto-deploys.

### Step 1: Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/the-vault.git
git push -u origin main
```

### Step 2: Get Cloudflare Credentials

1. **Account ID**: Cloudflare Dashboard → right sidebar → copy Account ID

2. **API Token**: 
   - Go to https://dash.cloudflare.com/profile/api-tokens
   - Click **Create Token**
   - Use **Custom token** template
   - Permissions needed:
     - `Cloudflare Pages:Edit`
     - `D1:Edit`
     - `Account:Read`
   - Account Resources: Include your account
   - Click **Continue to summary** → **Create token**
   - Copy the token

3. **D1 Database ID**:
   - Workers & Pages → D1 → the-vault-db
   - Copy the Database ID

### Step 3: Add GitHub Secrets

1. Go to your GitHub repo → **Settings → Secrets and variables → Actions**
2. Click **New repository secret** for each:

| Secret Name | Value |
|------------|-------|
| `CLOUDFLARE_API_TOKEN` | Your API token from Step 2 |
| `CLOUDFLARE_ACCOUNT_ID` | Your Account ID from Step 2 |
| `D1_DATABASE_ID` | Your D1 Database ID from Step 2 |

### Step 4: Deploy!

Push any change to the `main` branch:

```bash
git push
```

GitHub Actions will automatically:
- Build your app
- Deploy to Cloudflare Pages
- Apply D1 migrations

Track progress at: GitHub repo → **Actions** tab

---

## Method 3: Wrangler CLI

If you decide wrangler is fine after all:

### Install Wrangler

```bash
npm install -g wrangler
```

### Login

```bash
npx wrangler login
```

### Create D1 Database

```bash
npx wrangler d1 create the-vault-db
```

### Update wrangler.toml

Paste the Database ID into `wrangler.toml`:

```toml
[[d1_databases]]
binding = "DB"
database_name = "the-vault-db"
database_id = "YOUR_ACTUAL_DATABASE_ID_HERE"
```

### Set Secrets

```bash
npx wrangler secret put APP_SECRET
npx wrangler secret put STRIPE_SECRET_KEY
npx wrangler secret put VITE_STRIPE_PUBLISHABLE_KEY
npx wrangler secret put OPENAI_API_KEY
```

### Deploy

```bash
npm run build
npx wrangler pages deploy dist --project-name=the-vault
```

### Add Custom Domain

```bash
npx wrangler pages domain add the-vault thevault.win
npx wrangler pages domain add the-vault www.thevault.win
```

---

## Post-Deployment: Set Up D1 Schema

After first deploy, initialize your database:

### Via Wrangler

```bash
npx wrangler d1 execute the-vault-db --file=./db/migrations/0000_initial.sql --remote
```

### Via Dashboard

1. Workers & Pages → D1 → the-vault-db
2. Click **Console** tab
3. Copy-paste the SQL from `db/migrations/0000_initial.sql`
4. Click **Execute**

---

## Post-Deployment: Configure Custom Domain

### Add Domain to Pages

1. Dashboard → Workers & Pages → the-vault
2. Click **Custom domains**
3. Click **Set up a custom domain**
4. Enter `thevault.win`
5. Cloudflare automatically configures DNS

### Set Up www Redirect

1. After `thevault.win` is active, add `www.thevault.win`
2. Cloudflare will offer to redirect www → root automatically
3. Accept the redirect

---

## Troubleshooting

### "Database binding not found"
- Go to Pages → Settings → Functions → D1 database bindings
- Ensure `DB` is bound to `the-vault-db`

### "APP_SECRET not set"
- Add the secret via Dashboard (Settings → Environment variables)
- Or: `npx wrangler secret put APP_SECRET`

### "Build fails"
- Ensure Node.js 20+: `node --version`
- Delete `node_modules` and `package-lock.json`, then `npm install`

### "API routes 404"
- Check that `functions/[[path]].ts` exists
- Ensure wrangler.toml has `compatibility_flags = ["nodejs_compat"]`

### "CORS errors"
- Update the `origin` array in `functions/[[path]].ts` to include your domain

---

## File Structure

```
the-vault/
├── .github/workflows/
│   └── deploy-cloudflare.yml   # GitHub Actions auto-deploy
├── db/
│   ├── schema.ts                # D1 Drizzle ORM schema
│   └── migrations/
│       ├── 0000_initial.sql     # Initial migration
│       └── meta/
│           └── _journal.json    # Migration journal
├── functions/
│   └── [[path]].ts              # Edge API server (replaces Node.js)
├── src/                         # YOUR REACT SOURCE CODE
│   ├── components/
│   ├── sections/
│   ├── server/                  # YOUR BACKEND CODE
│   └── ...
├── cloudflare-upload/           # Generated by deploy-no-wrangler.sh
├── wrangler.toml                # Cloudflare configuration
├── deploy-no-wrangler.sh        # Dashboard deploy helper
├── package.json
├── vite.config.ts
└── ... (other config files)
```

---

## Need Help?

- Cloudflare Pages docs: https://developers.cloudflare.com/pages
- D1 docs: https://developers.cloudflare.com/d1
- Drizzle with D1: https://orm.drizzle.team/docs/connect-cloudflare-d1
