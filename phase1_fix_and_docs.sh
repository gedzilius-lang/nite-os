#!/bin/bash

# --- 1. Fix Database Host (localhost -> 127.0.0.1) ---
echo "Applying fix: forcing DB host to 127.0.0.1..."
sed -i "s/host: 'localhost'/host: '127.0.0.1'/g" /opt/nite-os/backend/src/app.module.ts

# --- 2. Rebuild and Restart ---
echo "Rebuilding backend..."
cd /opt/nite-os/backend
npm run build > /dev/null

echo "Restarting PM2..."
pm2 delete nite-backend 2>/dev/null || true
pm2 start dist/main.js --name nite-backend
pm2 save > /dev/null

# --- 3. Health Check ---
echo "Waiting 10s for boot..."
sleep 10

HEALTH_USER=$(curl -s http://127.0.0.1:3000/api/users/health)
echo "Health Check Result: $HEALTH_USER"

if [[ "$HEALTH_USER" == *"ok"* ]]; then
    echo "✅ Backend is ONLINE. Updating documentation automatically..."

    # --- 4. Auto-Update Documentation ---
    
    # Update V8-Fundamentals.md
    cat << 'DOCEOF' > /opt/nite-os/docs/V8-Fundamentals.md
# NiteOS V8 – Fundamentals

## 1. What NiteOS V8 Is

NiteOS V8 is a **modular monolith** platform for nightlife venues.
It provides:
- User profiles linked to **NiteTap** IDs
- XP and levels for gamification
- Nitecoin balances and transactions
- Venue + Market + POS logic
- Feed / announcements
- Admin and analytics views

This version replaces the old multi-service chaos (v5/v6/v7) with a **single, clean codebase**.

---

## 2. Hard Constraints for This VPS

This VPS hosts **only NiteOS V8**.
- **No radio stack here.** (No Liquidsoap, Icecast, etc.)
- The frontend can **embed an external radio stream URL**, but processing is external.
- One repo, one backend (NestJS), one frontend (Vue 3).

---

## 3. High-Level Architecture

### 3.1 Backend (NestJS + TypeORM)
- Location: \`/backend\`
- Exposes HTTP API under \`/api/*\`
- Primary database: PostgreSQL (\`nite_os\`)

**Current Modules (Phase 1 Status):**
- \`users\` – Entity created (NiteTap, XP, Balance). API Stubbed.
- \`venues\` – Stubbed.
- \`nitecoin\` – Stubbed.
- \`market\` – Stubbed.
- \`pos\` – Stubbed.
- \`feed\` – Stubbed.
- \`auth\` – Stubbed.
- \`analytics\` – Stubbed.

### 3.2 Frontend (Vue 3 + Vite SPA)
- Location: \`/frontend\`
- Core screens: Feed, Market, Profile, Radio (external).

### 3.3 Infrastructure
- Nginx: Reverse proxy.
- PostgreSQL: Main DB.
- pm2: Backend process manager.

---

## 4. Phased Roadmap
See \`V8-Roadmap.md\` for current progress.

## 5. Documentation Rules
1. \`docs/V8-Fundamentals.md\` (this file) - Architecture source of truth.
2. \`docs/V8-Phase-Log.md\` - Changelog.
DOCEOF

    # Update V8-Roadmap.md
    cat << 'DOCEOF' > /opt/nite-os/docs/V8-Roadmap.md
# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)
- Cleaned /opt, installed packages (git, nginx, pg, redis, node).
- Configured UFW and Postgres DB.

## Phase 1 – Backend Skeleton (DONE)
- Created \`/backend\` NestJS app.
- Configured TypeORM with Postgres (\`nite_os\`).
- Implemented modules: users, venues, market, pos, nitecoin, feed, auth, analytics.
- Implemented basic health endpoints.
- Defined \`User\` entity structure.
- **Status:** Running on port 3000 via PM2.

---

## Phase 2 – Real Entities & Data (NEXT)
Goal: Define the main tables and ensure schema stability.
- Entities: User, Venue, NitecoinTransaction, MarketItem, PosTransaction.
- Database relationship mapping.

## Phase 3 – Market + POS Logic
- "Pay with Nitecoin" flow.

## Phase 4 – Auth & Roles
- JWT-based auth and Role Guards.

## Phase 5 – Redis + Mongo Integration
- Sessions, Rate limits, Logs.

## Phase 6 – Frontend SPA
- Vue 3 + Vite implementation.
DOCEOF

    # Update V8-Phase-Log.md
    cat << 'DOCEOF' >> /opt/nite-os/docs/V8-Phase-Log.md

## 2025-12-05 – Phase 1 – Backend Skeleton
- Initialized NestJS project in \`/backend\`.
- Set up \`app.module.ts\` with TypeORM connection to Postgres.
- Created \`User\` entity with fields: id, externalId, nitetapId, xp, level, niteBalance, role.
- Generated stub modules for all core features.
- Verified system health via \`curl\` on localhost:3000.
DOCEOF

    echo "✅ Documentation successfully updated."
    echo "You can now run: git status && git add . && git commit -m 'Phase 1 Complete' && git push"

else
    echo "❌ Health check FAILED. Docs were NOT updated to prevent false info."
    echo "Printing last 30 error logs from PM2..."
    echo "----------------------------------------"
    pm2 logs nite-backend --lines 30 --nostream
    echo "----------------------------------------"
    echo "Please inspect the logs above to identify the crash reason."
fi
