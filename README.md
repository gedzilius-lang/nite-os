# NiteOS V8 – Core Operating System

**Status:** Planning / Early Implementation  
**Repo:** `gedzilius-lang/nite-os`  

NiteOS V8 is a **modular monolith** for nightlife venues.  
It replaces the old microservice chaos with a single, clean codebase that handles:

- Users, NiteTap IDs, XP and levels  
- Nitecoin balances and transactions  
- Venue + Market + POS logic  
- Feed / announcements  
- Admin + analytics

This VPS runs **only NiteOS**.  
All **radio / streaming** is external (remote URL only).  
No Liquidsoap, Icecast, RTMP/HLS, or any radio engine must run on this machine.

---

## High-Level Architecture (Target)

**Backend (NestJS + TypeORM)**  
- Location: `/backend`  
- Exposes REST API under `/api/*`  
- Uses PostgreSQL as the primary database  
- Uses Redis for caching / sessions (later)  
- Uses MongoDB for analytics / logs (later)  

Planned modules under `backend/src/modules`:

- `users` – profiles, NiteTap link, XP, level, Nitecoin balance  
- `venues` – venue entity, status, city, configuration  
- `nitecoin` – ledger of all Nitecoin transactions  
- `market` – market items per venue (CHF + Nitecoin pricing)  
- `pos` – checkout endpoints, POS transaction records  
- `feed` – posts / announcements / event teasers  
- `auth` – JWT / roles (user, staff, venue admin, Nitecore admin)  
- `analytics` – Mongo-based event logs + simple stats

**Frontend (Vue 3 + Vite SPA)**  
- Location: `/frontend`  
- Built as a single-page app and served by Nginx  
- Core screens:
  - **Feed** – venue posts and announcements  
  - **Market** – venue items, prices in CHF / Nitecoin  
  - **Profile** – NiteTap ID, XP, Nitecoin balance, recent activity  
  - **Radio** – **external** radio player (just consumes a URL, no local streaming stack)

**Infrastructure**

- Nginx reverse proxy for:
  - SPA frontend at `/`
  - Backend API at `/api/*`
- Databases and services:
  - PostgreSQL: `nite_os` database, `nite` application role  
  - Redis: sessions, rate limits, live counts (later)  
  - MongoDB: analytics / event logs (later)  
- Process manager: `pm2` for backend Node process

---

## Hard Rules for This VPS

1. **No Radio Stack**  
   - No Liquidsoap, Icecast, RTMP, HLS generation, or Auto-DJ on this host.  
   - This server only **consumes** radio via external URLs in the frontend.

2. **Single Repo, Single Deploy**  
   - One repo: `nite-os`  
   - Backend + frontend + infra scripts live together.  
   - Deploy flow is: pull → build → restart services.

3. **Postgres First**  
   - All core entities (User, Venue, NitecoinTransaction, MarketItem, PosTransaction) live in PostgreSQL via TypeORM.  
   - Later phases introduce Redis and Mongo, but the backbone is Postgres.

4. **Modular Monolith, Not Microservices**  
   - Everything in one NestJS app, using modules for separation.  
   - No separate user-service, pos-service, etc. at this stage.

---

## Roadmap (Phases)

The implementation is split into phases. Each phase must be documented in `docs/V8-Phase-Log.md`.

**Phase 0 – Pre-Flight (Server Prep)**  
- Clean old v5/v6/v7 directories into `/opt/nite-legacy-*`  
- Confirm **no radio services** are running  
- Install base packages (git, curl, nginx, postgresql, redis-server, ufw, etc.)  
- Configure UFW (22, 80, 443 only)  
- Ensure Postgres has DB `nite_os` and user `nite` with password `nitepassword` (dev only)  
- Create `/root/nite-preflight-v8.sh` (idempotent)

**Phase 1 – Backend Skeleton**  
- Basic NestJS app in `/backend`  
- AppModule, health endpoints  
- TypeORM connection to Postgres (`nite_os`) with `synchronize: true` for dev  
- Simple `/api/health` and stub `/api/users`, `/api/venues`, `/api/feed`

**Phase 2 – Core Entities**  
- Implement entities: `User`, `Venue`, `NitecoinTransaction`, `MarketItem`, `PosTransaction`  
- Seed utility or simple endpoints to create demo data  
- Verify schema and basic CRUD

**Phase 3 – Market + POS Logic**  
- `GET /api/market/:venueId/items`  
- `POST /api/pos/:venueId/checkout` with:
  - NiteTap ID
  - items, amounts
  - Nitecoin balance checks, transaction records

**Phase 4 – Auth + Roles**  
- JWT or session auth  
- Roles: User, Staff, Venue Admin, Nitecore Admin  
- Role-protected admin endpoints:
  - `/api/admin/market`
  - `/api/admin/pos`
  - `/api/admin/venues`

**Phase 5 – Redis + Mongo Integration**  
- Redis:
  - Sessions
  - Rate limiting per NiteTap / IP
  - Live counters  
- Mongo:
  - Event logs
  - Analytics snapshots

**Phase 6 – Frontend SPA**  
- Build the 4 primary screens (Feed, Market, Profile, Radio)  
- Connect to backend APIs  
- Radio screen uses an external HLS/stream URL (configurable)

**Phase 7 – Admin & Analytics UI**  
- Admin views for venues, market items, transactions  
- Simple analytics dashboards (Mongo data)

**Phase 8 – Hardening & CI/CD**  
- Turn off `synchronize: true`, move to migrations  
- Introduce non-root deploy user  
- CI/CD via GitHub Actions + deployment script  
- Security tightening (UFW rules, Nginx hardening, DB permissions)

---

## Development Workflow (Target)

1. **Clone**

```bash
git clone git@github.com:gedzilius-lang/nite-os.git
cd nite-os
