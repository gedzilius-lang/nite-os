# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)
## Phase 1 – Backend Skeleton (DONE)
## Phase 2 – Core Entities (DONE)

## Phase 3 – Market + POS Logic (DONE)
- Implemented \`MarketService\` to fetch venue items.
- Implemented \`PosService\` checkout logic:
  - Validates NiteTap ID.
  - Calculates totals.
  - Checks & deducts Nitecoin balance.
  - Records \`PosTransaction\` and \`NitecoinTransaction\`.
- Added Seeder endpoint for testing.

---

## Phase 4 – Auth & Roles (NEXT)
Goal: Secure the system.
- JWT-based auth.
- Roles: USER, STAFF, VENUE_ADMIN, NITECORE_ADMIN.

## Phase 5 – Redis + Mongo
## Phase 6 – Frontend SPA
