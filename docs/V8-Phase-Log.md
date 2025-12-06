# NiteOS V8 – Phase Log

## 2025-12-05 – Phase 0 – Preflight

- Old Nite OS folders removed from /opt.
- Fresh repo cloned to /opt/nite-os.
- Preflight script ran:
  - Base packages installed (git, nginx, postgresql, redis, ufw).
  - Node.js 20 and pm2 available.
  - UFW configured: allow 22/80/443, no radio ports.
  - Postgres role 'nite' and database 'nite_os' created.
- Ready to begin Phase 1 – Backend Skeleton.


## 2025-12-05 – Phase 1 – Backend Skeleton
- Initialized NestJS project in \`/backend\`.
- Set up \`app.module.ts\` with TypeORM connection to Postgres.
- Created \`User\` entity.
- Generated stub modules for all core features.
- Verified system health via \`curl\` on localhost:3000.

## 2025-12-05 – Phase 2 – Core Entities
- Implemented full Entity definitions for User, Venue, MarketItem, NitecoinTransaction, PosTransaction.
- Wired all modules to use \`TypeOrmModule.forFeature\`.
- Registered all entities in \`AppModule\`.
- Postgres tables successfully created/synced.

## 2025-12-05 – Phase 3 – Market & POS Logic
- Implemented \`GET /api/market/:venueId/items\`.
- Implemented \`POST /api/pos/:venueId/checkout\`.
- Added logic to deduct Nitecoin balance and log transactions.
- Added dependency injection between POS, Users, Market, and Nitecoin modules.

## 2025-12-05 – Phase 4 – Auth & Roles
- Installed \`@nestjs/jwt\`, \`passport\`, \`bcryptjs\`.
- Updated User entity with \`username\` and \`password\`.
- Implemented \`AuthModule\` with \`/auth/login\`.
- Added global \`RolesGuard\` and \`JwtAuthGuard\`.
- Secured POS Checkout: requires valid JWT + STAFF role + Venue Match.

## 2025-12-05 – Phase 5 – Redis + Mongo
- Installed Redis/Mongo dependencies.
- Configured \`MongooseModule\` and \`CacheModule\`.
- Implemented \`AnalyticsService\` to write to Mongo.
- Wired POS service to log sales to Analytics.
- Enabled Global Rate Limiting.

## 2025-12-05 – Phase 7 – UI Implementation
- Backend: Exposed user profile endpoint.
- Frontend: Implemented Pinia Auth Store.
- Frontend: Built Login, Profile, and Market views.
- Wired frontend to backend API using JWT tokens.
