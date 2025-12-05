# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)
- Server prepared, UFW/Postgres ready.

## Phase 1 – Backend Skeleton (DONE)
- NestJS app structure created.
- Basic Health endpoints live.

## Phase 2 – Core Entities (DONE)
- Defined TypeORM entities:
  - **User**: \`id, nitetapId, xp, level, niteBalance, role...\`
  - **Venue**: \`slug, title, city, status...\`
  - **MarketItem**: \`priceChf, priceNite, active...\`
  - **NitecoinTransaction**: \`amount, type, userId...\`
  - **PosTransaction**: \`totalChf, totalNite, staffId...\`
- Database tables auto-synced via TypeORM.

---

## Phase 3 – Market + POS Logic (NEXT)
Goal: Implement the "Pay with Nitecoin" flow.
- GET /api/market/:venueId/items
- POST /api/pos/:venueId/checkout
- Balance validation and transaction recording.

## Phase 4 – Auth & Roles
## Phase 5 – Redis + Mongo
## Phase 6 – Frontend SPA
