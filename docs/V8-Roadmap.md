# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)
## Phase 1 – Backend Skeleton (DONE)
## Phase 2 – Core Entities (DONE)
## Phase 3 – Market + POS Logic (DONE)

## Phase 4 – Auth & Roles (DONE)
- JWT Authentication implemented (Passport + JWT).
- Roles: USER, STAFF, VENUE_ADMIN, NITECORE_ADMIN.
- Secured \`/api/pos/*\` endpoints with \`JwtAuthGuard\` and \`RolesGuard\`.
- Added Password support for Staff users.

---

## Phase 5 – Redis + Mongo (NEXT)
Goal: Performance & Observability.
- Redis: Session store & Rate limiting.
- Mongo: Analytics Logs.

## Phase 6 – Frontend SPA
