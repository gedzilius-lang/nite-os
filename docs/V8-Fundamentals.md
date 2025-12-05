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

- **No radio stack here.**
  - No Liquidsoap
  - No Icecast
  - No RTMP/HLS
  - No Auto-DJ services
- The frontend can **embed an external radio stream URL**, but the audio/video processing happens on a **separate radio VPS**, not on this box.

Other constraints:

- One repo: `gedzilius-lang/nite-os`
- One backend app: NestJS modular monolith
- One frontend app: Vue 3 + Vite SPA
- Single deployment flow: pull → build → restart

---

## 3. High-Level Architecture

### 3.1 Backend (NestJS + TypeORM)

- Location: `/backend`
- Exposes HTTP API under `/api/*`
- Primary database: PostgreSQL (`nite_os`)
- Additional services:
  - Redis (sessions, rate limits, live stats) – added in later phases
  - MongoDB (analytics, logs) – added in later phases

Target modules under `backend/src/modules`:

- `users` – NiteTap linkage, XP, level, Nitecoin balance
- `venues` – venue identity, city, status, configuration
- `nitecoin` – ledger of all Nitecoin transactions (earn/spend)
- `market` – market items per venue (CHF and Nitecoin pricing)
- `pos` – checkout endpoints and POS transaction records
- `feed` – posts and announcements
- `auth` – JWT-based auth and roles
- `analytics` – event logs, stats, dashboards

The backend is a **modular monolith**: one process, multiple feature modules.
If the project ever truly needs microservices, we can split modules later.

### 3.2 Frontend (Vue 3 + Vite SPA)

- Location: `/frontend`
- Built with Vite and served through Nginx
- Core screens:
  - **Feed** – venue posts & announcements
  - **Market** – items per venue, prices in CHF and Nitecoin, add-to-cart/checkout
  - **Profile** – user/NiteTap, XP, level, Nitecoin balance, recent activity
  - **Radio** – player for an **external** HLS/stream URL (configured via environment)

No SSR, no Next.js. A single SPA is enough.

### 3.3 Infrastructure

- Nginx:
  - Serves SPA at `/`
  - Proxies backend API at `/api/*`
- PostgreSQL:
  - Database name: `nite_os`
  - Application user: `nite` (dev password: `nitepassword`, will be hardened later)
- Redis:
  - For sessions, counters, rate limits (phased in later)
- MongoDB:
  - For analytics and event logs (phased in later)
- pm2:
  - For managing the backend Node process

---

## 4. Phased Roadmap

We build NiteOS V8 in clear phases.
Each phase gets logged in `docs/V8-Phase-Log.md`.

### Phase 0 – Pre-Flight (Server Prep)

Goal: clean and prepare the VPS.

- Move legacy v5/v6/v7 dirs under `/opt` into `/opt/nite-legacy-YYYYMMDD-HHMMSS/`
- Ensure **no radio services** are running on this box
- Configure UFW (22, 80, 443 only)
- Install base packages (git, curl, nginx, postgresql, redis, ufw, etc.)
- Create and verify:
  - DB `nite_os`
  - Role `nite` with LOGIN and password `nitepassword`
- Create `/root/nite-preflight-v8.sh` (idempotent)
- Log all of this in `V8-Phase-Log.md`

### Phase 1 – Backend Skeleton

Goal: have a minimal backend running on port 3000.

- Basic NestJS app at `/backend`
- TypeORM Postgres connection with `synchronize: true` (dev-only)
- Health endpoints:
  - `GET /api/health`
  - `GET /api/users/ping`
  - `GET /api/venues/ping`
  - `GET /api/feed/ping`
- pm2 config for the backend
- Log the phase

### Phase 2 – Core Entities

Goal: define the main tables and ensure schema stability.

Entities in Postgres:

- `User` – id, externalId, nitetapId, apiKey, role, venueId, xp, level, niteBalance, timestamps
- `Venue` – id, slug, title, city, status, timestamps
- `NitecoinTransaction` – id, userId, venueId, amount, type, createdAt
- `MarketItem` – id, venueId, title, priceChf, priceNite, active
- `PosTransaction` – id, venueId, staffId, userId, nitetapId, totalChf, totalNite, status, createdAt

TypeORM `synchronize: true` still on (dev-only), but entities must be clean and Postgres-safe.

### Phase 3 – Market + POS Logic

Goal: a working “pay with Nitecoin” flow.

Endpoints:

- `GET /api/market/:venueId/items`
  - Returns active items for that venue
- `POST /api/pos/:venueId/checkout`
  - Accepts NiteTap + items
  - Checks Nitecoin balance
  - Updates balance and writes Nitecoin + POS transactions
  - Returns new balance and receipt data

### Phase 4 – Auth + Roles

Goal: secure the system.

- JWT-based auth
- Roles:
  - user, staff, venueAdmin, nitecoreAdmin
- Protect endpoints:
  - `/api/admin/market/*`
  - `/api/admin/pos/*`
  - `/api/admin/venues/*`
- Enforce venue scoping (staff only sees own venue; Nitecore admin sees all)

### Phase 5 – Redis + Mongo

Goal: better performance and observability.

- Redis:
  - Session store
  - Rate limiting per IP / NiteTap
  - Live counters (active users, active venues, running promos)
- Mongo:
  - Event logs
  - Analytics snapshots

### Phase 6 – Frontend SPA

Goal: visible, usable UI.

- Implement Feed, Market, Profile, Radio pages in Vue 3
- Connect to backend API
- Radio page uses a configurable **external** stream URL (no local streaming)

### Phase 7 – Admin & Analytics UI

Goal: operational tools.

- Venue admin screens:
  - Market items management
  - POS transaction overview
- Nitecore admin screens:
  - Cross-venue stats
  - Basic analytics from Mongo

### Phase 8 – Hardening & CI/CD

Goal: production-safe system.

- Disable TypeORM `synchronize` and move to migrations
- Introduce non-root deploy user
- CI/CD via GitHub Actions and a deploy script
- Tighten security:
  - Nginx hardening
  - UFW review
  - Database role and password tightening

---

## 5. Documentation Rules

Two docs in this repo are mandatory:

1. `docs/V8-Fundamentals.md` (this file)  
   - Must always reflect the current **intended** architecture and constraints.

2. `docs/V8-Phase-Log.md`  
   - Must be updated after each completed phase with:
     - Date
     - Phase number + name
     - Short summary of changes
     - Important commands/decisions

If code or infrastructure changes in a way that conflicts with these docs, the change is wrong and must be corrected or documented.
