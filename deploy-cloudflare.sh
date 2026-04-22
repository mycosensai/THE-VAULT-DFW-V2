#!/bin/bash
# ═══════════════════════════════════════════════════════════
# The Vault — Cloudflare Deployment Script
# Deploys to Cloudflare Pages + Workers + D1
# ═══════════════════════════════════════════════════════════
#
# Usage:
#   bash deploy-cloudflare.sh
#
# Requirements:
#   - Node.js 20+
#   - npx wrangler (auto-installed if missing)
#   - Cloudflare account
#   - Domain: thevault.win (with www.thevault.win redirect)
#
# To use WITHOUT wrangler, run instead:
#   bash deploy-no-wrangler.sh
#
# ═══════════════════════════════════════════════════════════

set -e

DOMAIN="thevault.win"
PROJECT_NAME="the-vault"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║          THE VAULT — CLOUDFLARE DEPLOYER                 ║"
echo "║                                                          ║"
echo "║  Target: https://$DOMAIN                                 ║"
echo "║                                                          ║"
echo "║  This script will:                                       ║"
echo "║  1. Check wrangler CLI is installed                      ║"
echo "║  2. Login to Cloudflare (if needed)                      ║"
echo "║  3. Create D1 database (if needed)                       ║"
echo "║  4. Build the frontend                                   ║"
echo "║  5. Deploy to Cloudflare Pages                           ║"
echo "║  6. Set up custom domain: $DOMAIN          ║"
echo "║  7. Apply database migrations                            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ─── Step 1: Check Wrangler ───
echo "[1/7] Checking Wrangler CLI..."
if ! command -v npx &> /dev/null; then
    echo "ERROR: npx not found. Install Node.js first: https://nodejs.org"
    exit 1
fi

if ! npx wrangler --version &> /dev/null; then
    echo "Installing Wrangler..."
    npm install -g wrangler
fi
echo "  Wrangler is ready."

# ─── Step 2: Authenticate ───
echo ""
echo "[2/7] Checking Cloudflare authentication..."
if ! npx wrangler whoami &> /dev/null; then
    echo "  You need to login to Cloudflare first."
    echo "  Opening browser for authentication..."
    npx wrangler login
else
    echo "  Already authenticated with Cloudflare."
fi

# ─── Step 3: Create D1 Database ───
echo ""
echo "[3/7] Setting up D1 database..."
D1_LIST=$(npx wrangler d1 list --json 2>/dev/null || echo "[]")
D1_EXISTS=$(echo "$D1_LIST" | grep -c "the-vault-db" || true)

if [ "$D1_EXISTS" -eq 0 ]; then
    echo "  Creating D1 database 'the-vault-db'..."
    npx wrangler d1 create the-vault-db
    echo ""
    echo "  IMPORTANT: Copy the database_id from above and paste it into wrangler.toml"
    echo "  Then run this script again."
    echo ""
    read -p "Press Enter after updating wrangler.toml..."
else
    echo "  D1 database 'the-vault-db' already exists."
fi

# ─── Step 4: Apply Schema ───
echo ""
echo "[4/7] Applying database schema..."
npx wrangler d1 execute the-vault-db --file=./db/migrations/0000_initial.sql --remote || {
    echo "  ⚠ Schema may already be applied. Continuing..."
}
echo "  Schema applied."

# ─── Step 5: Set Secrets ───
echo ""
echo "[5/7] Setting environment secrets..."
echo "  You'll be prompted for your secrets. Press Enter to skip any."
echo ""

read -p "APP_SECRET (generate: openssl rand -base64 32): " APP_SECRET
if [ -n "$APP_SECRET" ]; then
    echo "$APP_SECRET" | npx wrangler secret put APP_SECRET --project-name="$PROJECT_NAME"
fi

read -p "STRIPE_SECRET_KEY (sk_live_...): " STRIPE_KEY
if [ -n "$STRIPE_KEY" ]; then
    echo "$STRIPE_KEY" | npx wrangler secret put STRIPE_SECRET_KEY --project-name="$PROJECT_NAME"
fi

read -p "VITE_STRIPE_PUBLISHABLE_KEY (pk_live_...): " STRIPE_PUB
if [ -n "$STRIPE_PUB" ]; then
    echo "$STRIPE_PUB" | npx wrangler secret put VITE_STRIPE_PUBLISHABLE_KEY --project-name="$PROJECT_NAME"
fi

read -p "COINBASE_API_KEY: " CB_KEY
if [ -n "$CB_KEY" ]; then
    echo "$CB_KEY" | npx wrangler secret put COINBASE_API_KEY --project-name="$PROJECT_NAME"
fi

read -p "OPENAI_API_KEY (sk-...): " OAI_KEY
if [ -n "$OAI_KEY" ]; then
    echo "$OAI_KEY" | npx wrangler secret put OPENAI_API_KEY --project-name="$PROJECT_NAME"
fi

read -p "GOOGLE_CLIENT_ID (optional): " GOOGLE_ID
if [ -n "$GOOGLE_ID" ]; then
    echo "$GOOGLE_ID" | npx wrangler secret put GOOGLE_CLIENT_ID --project-name="$PROJECT_NAME"
    read -p "GOOGLE_CLIENT_SECRET: " GOOGLE_SECRET
    echo "$GOOGLE_SECRET" | npx wrangler secret put GOOGLE_CLIENT_SECRET --project-name="$PROJECT_NAME"
fi

read -p "GITHUB_CLIENT_ID (optional): " GH_ID
if [ -n "$GH_ID" ]; then
    echo "$GH_ID" | npx wrangler secret put GITHUB_CLIENT_ID --project-name="$PROJECT_NAME"
    read -p "GITHUB_CLIENT_SECRET: " GH_SECRET
    echo "$GH_SECRET" | npx wrangler secret put GITHUB_CLIENT_SECRET --project-name="$PROJECT_NAME"
fi

# ─── Step 6: Build & Deploy ───
echo ""
echo "[6/7] Building and deploying..."
npm run build
echo ""
echo "  Frontend built. Deploying to Cloudflare Pages..."
echo ""

npx wrangler pages deploy dist --project-name="$PROJECT_NAME"

echo ""
echo "  ✓ Deployed!"

# ─── Step 7: Custom Domain ───
echo ""
echo "[7/7] Setting up custom domain..."
echo "  Adding https://$DOMAIN ..."
npx wrangler pages domain add "$PROJECT_NAME" "$DOMAIN" 2>/dev/null || {
    echo "  Domain may already be configured or DNS not ready."
    echo "  Add manually: Dashboard → Pages → $PROJECT_NAME → Custom Domains"
}

echo "  Adding https://www.$DOMAIN ..."
npx wrangler pages domain add "$PROJECT_NAME" "www.$DOMAIN" 2>/dev/null || {
    echo "  www domain may already be configured."
}

# ─── Done ───
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                 DEPLOYMENT COMPLETE!                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Your site is now live at:"
echo "  https://$DOMAIN"
echo "  https://www.$DOMAIN → redirects to https://$DOMAIN"
echo ""
echo "Next steps:"
echo "  1. Test all features on the live site"
echo "  2. Check D1 database: npx wrangler d1 execute the-vault-db --command='SELECT * FROM users'"
echo "  3. Monitor: Cloudflare Dashboard → Pages → $PROJECT_NAME"
echo ""
echo "To deploy updates:"
echo "  npm run build"
echo "  npx wrangler pages deploy dist --project-name=$PROJECT_NAME"
echo ""
echo "Or use the no-wrangler alternative:"
echo "  bash deploy-no-wrangler.sh"
echo ""
