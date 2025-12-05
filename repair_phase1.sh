#!/bin/bash

# Define base path
BASE_DIR="/opt/nite-os/backend"
mkdir -p $BASE_DIR

# --- 1. Clean Slate ---
echo "Cleaning old build artifacts..."
pm2 delete nite-backend 2>/dev/null || true
rm -rf $BASE_DIR/dist
rm -rf $BASE_DIR/src/modules
mkdir -p $BASE_DIR/src/modules

# --- 2. Configuration Files ---

# nest-cli.json (Ensures nest build works correctly)
cat <<EOF > $BASE_DIR/nest-cli.json
{
  "\$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "sourceRoot": "src",
  "compilerOptions": {
    "deleteOutDir": true
  }
}
EOF

# tsconfig.json (Standard NestJS config)
cat <<EOF > $BASE_DIR/tsconfig.json
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "es2017",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "strictNullChecks": false,
    "noImplicitAny": false,
    "strictBindCallApply": false,
    "forceConsistentCasingInFileNames": false,
    "noFallthroughCasesInSwitch": false
  },
  "exclude": ["node_modules", "dist"]
}
EOF

# --- 3. Core App Files ---

# src/main.ts
cat <<EOF > $BASE_DIR/src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');
  app.enableCors();
  await app.listen(3000);
  console.log('NiteOS V8 Backend is live on port 3000');
}
bootstrap();
EOF

# src/app.module.ts
cat <<EOF > $BASE_DIR/src/app.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './modules/users/users.module';
import { VenuesModule } from './modules/venues/venues.module';
import { NitecoinModule } from './modules/nitecoin/nitecoin.module';
import { MarketModule } from './modules/market/market.module';
import { PosModule } from './modules/pos/pos.module';
import { FeedModule } from './modules/feed/feed.module';
import { AuthModule } from './modules/auth/auth.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { User } from './modules/users/user.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: '127.0.0.1', 
      port: 5432,
      username: 'nite',
      password: 'nitepassword',
      database: 'nite_os',
      entities: [User],
      synchronize: true,
    }),
    UsersModule,
    VenuesModule,
    NitecoinModule,
    MarketModule,
    PosModule,
    FeedModule,
    AuthModule,
    AnalyticsModule,
  ],
})
export class AppModule {}
EOF

# --- 4. Feature Modules (Explicit Creation) ---

# Helper to create files
create_files() {
  local MOD=$1
  local CLASS=$2
  mkdir -p $BASE_DIR/src/modules/$MOD

  # Controller
  cat <<EOF > $BASE_DIR/src/modules/$MOD/$MOD.controller.ts
import { Controller, Get } from '@nestjs/common';
import { ${CLASS}Service } from './$MOD.service';

@Controller('$MOD')
export class ${CLASS}Controller {
  constructor(private readonly service: ${CLASS}Service) {}

  @Get('health')
  healthCheck() {
    return this.service.getHealth();
  }
}
EOF

  # Service
  cat <<EOF > $BASE_DIR/src/modules/$MOD/$MOD.service.ts
import { Injectable } from '@nestjs/common';

@Injectable()
export class ${CLASS}Service {
  getHealth() {
    return { status: 'ok', service: '$MOD', timestamp: new Date().toISOString() };
  }
}
EOF

  # Module
  cat <<EOF > $BASE_DIR/src/modules/$MOD/$MOD.module.ts
import { Module } from '@nestjs/common';
import { ${CLASS}Controller } from './$MOD.controller';
import { ${CLASS}Service } from './$MOD.service';

@Module({
  controllers: [${CLASS}Controller],
  providers: [${CLASS}Service],
})
export class ${CLASS}Module {}
EOF
}

# Generate all modules explicitly
create_files "users" "Users"
create_files "venues" "Venues"
create_files "nitecoin" "Nitecoin"
create_files "market" "Market"
create_files "pos" "Pos"
create_files "feed" "Feed"
create_files "auth" "Auth"
create_files "analytics" "Analytics"

# Create User Entity manually
cat <<EOF > $BASE_DIR/src/modules/users/user.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  externalId: string;

  @Column({ unique: true, nullable: true })
  nitetapId: string;

  @Column({ default: 0 })
  xp: number;

  @Column({ default: 1 })
  level: number;

  @Column({ default: 0 })
  niteBalance: number;

  @Column({ default: 'USER' })
  role: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
EOF

# --- 5. Build and Start ---

echo "Installing dependencies (just in case)..."
cd $BASE_DIR
npm install --silent

echo "Building backend..."
npm run build

if [ $? -eq 0 ]; then
  echo "Build SUCCESS. Starting PM2..."
  pm2 start dist/main.js --name nite-backend
  pm2 save
else
  echo "Build FAILED. Exiting."
  exit 1
fi

# --- 6. Verify and Update Docs ---

echo "Waiting 10s for boot..."
sleep 10

HEALTH_USER=$(curl -s http://127.0.0.1:3000/api/users/health)
echo "Health Check Result: $HEALTH_USER"

if [[ "$HEALTH_USER" == *"ok"* ]]; then
    echo "✅ Backend is ONLINE. Updating documentation automatically..."
    
    # --- UPDATE V8-Fundamentals.md ---
    cat << 'DOCEOF' > /opt/nite-os/docs/V8-Fundamentals.md
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
DOCEOF

    # --- UPDATE V8-Roadmap.md ---
    cat << 'DOCEOF' > /opt/nite-os/docs/V8-Roadmap.md
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
DOCEOF

    # --- UPDATE V8-Phase-Log.md ---
    cat << 'DOCEOF' >> /opt/nite-os/docs/V8-Phase-Log.md

## 2025-12-05 – Phase 1 – Backend Skeleton
- Initialized NestJS project in \`/backend\`.
- Set up \`app.module.ts\` with TypeORM connection to Postgres.
- Created \`User\` entity.
- Generated stub modules for all core features.
- Verified system health via \`curl\` on localhost:3000.
DOCEOF

    echo "✅ Documentation successfully updated."
    echo "You can now run: git status && git add . && git commit -m 'Phase 1 Complete' && git push"

else
    echo "❌ Health check FAILED. Docs were NOT updated."
    pm2 logs nite-backend --lines 30 --nostream
fi
