#!/bin/bash
# ═══════════════════════════════════════════════════════════
# The Vault — Cloudflare Dashboard Deployment (NO WRANGLER CLI!)
#
# This script builds your project locally and provides a
# drag-and-drop folder ready for Cloudflare Dashboard upload.
#
# NO Cloudflare login, NO API tokens, NO wrangler needed!
# You just drag the built folder into the Cloudflare web UI.
#
# Steps:
#   1. Run this script: bash deploy-no-wrangler.sh
#   2. Go to https://dash.cloudflare.com → Pages → Create
#   3. Drag the "cloudflare-upload/" folder into the browser
#   4. Your site is live!
#
# ═══════════════════════════════════════════════════════════

set -e

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║     THE VAULT — DASHBOARD DEPLOY (No Wrangler!)        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ─── Step 1: Build ───
echo "[1/4] Building application..."
npm run build
echo "  ✓ Build complete."

# ─── Step 2: Prepare upload folder ───
echo ""
echo "[2/4] Preparing Cloudflare upload package..."
mkdir -p cloudflare-upload

# Copy the built frontend
cp -r dist/* cloudflare-upload/ 2>/dev/null || cp -r dist cloudflare-upload/

# Copy Functions for edge API
cp -r functions cloudflare-upload/

# Copy D1 schema for reference
cp -r db cloudflare-upload/

# Copy wrangler config
cp wrangler.toml cloudflare-upload/ 2>/dev/null || true

echo "  ✓ Upload package ready in cloudflare-upload/"

# ─── Step 3: Validate ───
echo ""
echo "[3/4] Validating upload package..."
if [ ! -f "cloudflare-upload/index.html" ]; then
    echo "  ⚠ Warning: index.html not found in upload package"
else
    echo "  ✓ index.html found"
fi

if [ -d "cloudflare-upload/functions" ]; then
    echo "  ✓ Edge Functions included (Stripe, Coinbase, OpenAI, Auth)"
fi

echo ""
echo "Package contents:"
ls -la cloudflare-upload/
echo ""

# ─── Step 4: Output instructions ───
echo ""
echo "[4/4] Done! Here's how to deploy without wrangler:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  METHOD 1: Cloudflare Dashboard (EASIEST - No CLI!)"
echo "  ────────────────────────────────────────────────────────"
echo "  1. Open: https://dash.cloudflare.com"
echo "  2. Go to: Workers & Pages → Create → Pages"
echo "  3. Click: 'Upload assets' (NOT 'Connect to Git')"
echo "  4. Project name: the-vault"
echo "  5. Drag the ENTIRE 'cloudflare-upload/' folder into"
echo "     the browser window (or click 'Select folder')"
echo "  6. Click 'Deploy site'"
echo "  7. Done! Your site is live at:"
echo "     https://the-vault.pages.dev"
echo ""
echo "  METHOD 2: GitHub Auto-Deploy (BEST - Push to deploy!)"
echo "  ────────────────────────────────────────────────────────"
echo "  1. Push this project to a GitHub repository"
echo "  2. The GitHub Action in .github/workflows/ will"
echo "     automatically deploy on every push to main!"
echo "  3. Set these GitHub Secrets (Settings → Secrets):"
echo "     CLOUDFLARE_API_TOKEN"
echo "     CLOUDFLARE_ACCOUNT_ID"
echo "     D1_DATABASE_ID"
echo "     APP_SECRET"
echo "     STRIPE_SECRET_KEY"
echo "     VITE_STRIPE_PUBLISHABLE_KEY"
echo "     COINBASE_API_KEY"
echo "     OPENAI_API_KEY"
echo "  4. See CLOUDFLARE-DEPLOY.md for detailed setup"
echo ""
echo "  METHOD 3: Wrangler CLI (if you change your mind)"
echo "  ────────────────────────────────────────────────────────"
echo "  npx wrangler pages deploy cloudflare-upload \\"
echo "    --project-name=the-vault \\"
echo "    --branch=main"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠ IMPORTANT: After first deploy, set your secrets:"
echo "  1. Cloudflare Dashboard → Pages → the-vault"
echo "  2. Settings → Environment variables → Add variables"
echo "  3. Add each secret from .env.example:"
echo ""
echo "     APP_SECRET                  (JWT key)"
echo "     STRIPE_SECRET_KEY           (sk_test_...)"
echo "     VITE_STRIPE_PUBLISHABLE_KEY (pk_test_...)"
echo "     COINBASE_API_KEY            (your Coinbase key)"
echo "     OPENAI_API_KEY              (sk-...)"
echo ""
echo "  4. Settings → Functions → Add D1 binding:"
echo "     Variable name: DB"
echo "     Database: the-vault-db"
echo ""
echo "  5. Custom domains:"
echo "     Add: thevault.win"
echo "     Add: www.thevault.win (redirects to root)"
echo ""
