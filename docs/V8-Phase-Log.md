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

