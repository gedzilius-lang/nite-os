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
- \`users\` – Entity created. API Stubbed.
- \`venues\`, \`nitecoin\`, \`market\`, \`pos\`, \`feed\`, \`auth\`, \`analytics\` – Stubbed.

### 3.2 Frontend (Vue 3 + Vite SPA)
- Location: \`/frontend\`
- Core screens: Feed, Market, Profile, Radio (external).

### 3.3 Infrastructure
- Nginx: Reverse proxy.
- PostgreSQL: Main DB.
- pm2: Backend process manager.

---

## 4. Documentation Rules
1. \`docs/V8-Fundamentals.md\` - Architecture source of truth.
2. \`docs/V8-Phase-Log.md\` - Changelog.
