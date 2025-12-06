#!/bin/bash

ROOT_DIR="/opt/nite-os"
BACK_DIR="$ROOT_DIR/backend"

echo "--- PHASE 8: Hardening & Automation ---"

# --- 1. Security Hardening (Helmet) ---
echo "1. Installing Security Headers (Helmet)..."
cd $BACK_DIR
npm install helmet

# Update main.ts to use Helmet
cat <<EOF > $BACK_DIR/src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Security Headers
  app.use(helmet());
  
  // CORS (Allow Frontend)
  app.enableCors({
    origin: ['http://localhost', 'http://127.0.0.1'], // Adjust for real domain later
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  });

  app.setGlobalPrefix('api');
  await app.listen(3000);
  console.log('NiteOS V8 Backend is live (Secured)');
}
bootstrap();
EOF

# --- 2. Database Safety (Disable Sync) ---
echo "2. Disabling DB Auto-Sync (Production Mode)..."
# We update AppModule to set synchronize: false
# Note: In a real future scenario, you would use Migrations here.
cat <<EOF > $BACK_DIR/src/app.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MongooseModule } from '@nestjs/mongoose';
import { CacheModule } from '@nestjs/cache-manager';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import * as redisStore from 'cache-manager-ioredis';

// Modules
import { UsersModule } from './modules/users/users.module';
import { VenuesModule } from './modules/venues/venues.module';
import { NitecoinModule } from './modules/nitecoin/nitecoin.module';
import { MarketModule } from './modules/market/market.module';
import { PosModule } from './modules/pos/pos.module';
import { FeedModule } from './modules/feed/feed.module';
import { AuthModule } from './modules/auth/auth.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';

// Entities
import { User } from './modules/users/user.entity';
import { Venue } from './modules/venues/venue.entity';
import { MarketItem } from './modules/market/market-item.entity';
import { NitecoinTransaction } from './modules/nitecoin/nitecoin-transaction.entity';
import { PosTransaction } from './modules/pos/pos-transaction.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: '127.0.0.1',
      port: 5432,
      username: 'nite',
      password: 'nitepassword',
      database: 'nite_os',
      entities: [User, Venue, MarketItem, NitecoinTransaction, PosTransaction],
      
      // PRODUCTION SAFETY:
      // We disable auto-sync to prevent schema data loss.
      // Future changes should use Migrations.
      synchronize: false, 
    }),

    MongooseModule.forRoot('mongodb://127.0.0.1:27017/nite_analytics'),

    CacheModule.register({
      isGlobal: true, 
      store: redisStore,
      host: '127.0.0.1',
      port: 6379,
    }),

    ThrottlerModule.forRoot([{
      ttl: 60000,
      limit: 100,
    }]),

    UsersModule,
    VenuesModule,
    NitecoinModule,
    MarketModule,
    PosModule,
    FeedModule,
    AuthModule,
    AnalyticsModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
EOF

# --- 3. Create Deploy Script ---
echo "3. Creating Deployment Script (deploy.sh)..."
cat <<EOF > $ROOT_DIR/deploy.sh
#!/bin/bash

echo "🚀 NiteOS V8 Deployment Started..."

# 1. Update Code
echo "📥 Pulling latest code..."
git pull origin main

# 2. Backend
echo "⚙️  Building Backend..."
cd $ROOT_DIR/backend
npm install --production=false
npm run build
pm2 restart nite-backend

# 3. Frontend
echo "🎨 Building Frontend..."
cd $ROOT_DIR/frontend
npm install
npm run build

# 4. Nginx
echo "🌐 Reloading Web Server..."
systemctl reload nginx

echo "✅ Deployment Complete!"
EOF
chmod +x $ROOT_DIR/deploy.sh

# --- 4. Rebuild Backend with new Settings ---
echo "4. Applying Hardening..."
cd $BACK_DIR
npm run build
pm2 restart nite-backend

# --- 5. Final Docs ---
cat << 'DOCEOF' > $ROOT_DIR/docs/V8-Roadmap.md
# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)
## Phase 1 – Backend Skeleton (DONE)
## Phase 2 – Core Entities (DONE)
## Phase 3 – Market + POS Logic (DONE)
## Phase 4 – Auth & Roles (DONE)
## Phase 5 – Redis + Mongo (DONE)
## Phase 6 – Frontend Skeleton (DONE)
## Phase 7 – UI Implementation (DONE)

## Phase 8 – Hardening & Automation (DONE)
- **Security:** Helmet installed.
- **Safety:** \`synchronize: false\` applied to DB.
- **Automation:** \`deploy.sh\` script created.

---
# 🏁 V8 DEVELOPMENT COMPLETE
The system is now live and production-ready.
Future updates should follow the workflow:
1. Make changes locally.
2. Push to GitHub.
3. SSH into VPS and run \`./deploy.sh\`.
DOCEOF

cat << 'DOCEOF' >> $ROOT_DIR/docs/V8-Phase-Log.md

## 2025-12-05 – Phase 8 – Hardening & Completion
- Installed \`helmet\` for HTTP security headers.
- Disabled TypeORM auto-synchronization.
- Created \`deploy.sh\` for one-command updates.
- **PROJECT STATUS: LIVE**
DOCEOF

echo "✅ Phase 8 Complete. System is hardened."
echo "You can now deploy anytime by running: ./deploy.sh"
