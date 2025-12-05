# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)
- Cleaned /opt, installed packages.
- Configured UFW and Postgres DB.

## Phase 1 – Backend Skeleton (DONE)
- Created \`/backend\` NestJS app.
- Configured TypeORM with Postgres (\`nite_os\`).
- Implemented modules: users, venues, market, pos, nitecoin, feed, auth, analytics.
- Implemented basic health endpoints.
- Defined \`User\` entity.
- **Status:** Running on port 3000 via PM2.

## Phase 2 – Real Entities & Data (NEXT)
Goal: Define the main tables and ensure schema stability.
- Entities: User, Venue, NitecoinTransaction, MarketItem, PosTransaction.

## Phase 3 – Market + POS Logic
## Phase 4 – Auth & Roles
## Phase 5 – Redis + Mongo Integration
## Phase 6 – Frontend SPA
