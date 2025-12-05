# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)

- Cleaned old Nite OS code from /opt.
- Cloned fresh repo into /opt/nite-os.
- Installed base packages: git, curl, nginx, ufw, postgresql, redis-server.
- Installed / verified Node.js 20 + pm2.
- Configured UFW:
  - allow: 22/tcp, 80/tcp, 443/tcp
  - removed: 1935/tcp, 8000/tcp, any radio-related ports.
- Created Postgres role + DB:
  - role: nite / password: nitepassword
  - database: nite_os (owner: nite)
- Confirmed: this VPS is **NiteOS only**, no radio stack.

---

## Phase 1 – Backend Skeleton (NEXT)

Goal: running NestJS backend as a **modular monolith** under `/backend` with stub APIs.

Requirements:

- Create `/backend` NestJS app (no microservices, single app).
- Configure TypeORM with Postgres:
  - host: localhost
  - port: 5432
  - database: nite_os
  - username: nite
  - password: nitepassword
  - synchronize: true (DEV ONLY)
- Implement modules under `backend/src/modules`:
  - users
  - venues
  - market
  - pos
  - nitecoin
  - feed
  - auth (stub)
  - analytics (stub)
- Implement basic health + stub endpoints (all return simple JSON):
  - GET /api/health
  - GET /api/users/ping
  - GET /api/venues
  - GET /api/market
  - GET /api/pos
  - GET /api/feed
- Start backend via pm2 as `nite-backend` on port 3000.
- No Redis/Mongo usage yet (wired later).

Success criteria:

- `pm2 ls` shows `nite-backend` online.
- `curl http://localhost:3000/api/health` returns JSON OK.
- Other stub endpoints respond (even with empty data).

---

## Phase 2 – Frontend Skeleton

Goal: Vue 3 + Vite SPA in `/frontend`.

- Pages:
  - `/feed` – shows static list from /api/feed
  - `/market` – static venue selector, calls /api/market
  - `/profile` – placeholder for NiteTap + Nitecoin
  - `/login` – future auth
  - `/admin` – placeholder
  - `/radio` – **external** radio iframe/URL, no streaming stack here
- Single-page app with router, basic layout, dark theme.

---

## Phase 3 – Nitecoin Economy + Market/POS Logic

- Implement real entities:
  - User, Venue, NitecoinTransaction, MarketItem, PosTransaction
- Implement:
  - GET /api/market/:venueId/items
  - POST /api/pos/:venueId/checkout
- Apply Nitecoin balance changes & basic validation.

---

## Phase 4 – Auth & Roles

- JWT-based auth:
  - roles: USER, STAFF, VENUE_ADMIN, NITECORE_ADMIN
- Protect admin endpoints:
  - /api/admin/venues
  - /api/admin/market
  - /api/admin/pos
- Enforce venue scoping for staff.

---

## Phase 5 – Redis + Mongo Integration

- Redis:
  - session store
  - rate limiting
  - live counters (active users, active venues)
- Mongo:
  - analytics event logs
  - error traces

---

## Phase 6 – CI/CD & Hardening

- Disable `synchronize: true` → use TypeORM migrations.
- Add GitHub Actions workflow:
  - build backend + frontend
  - deploy to VPS via SSH (deploy.sh)
- Harden Nginx + security headers.
- Add basic rate limiting + validation at API and Nginx.

