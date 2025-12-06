#!/bin/bash

BASE_DIR="/opt/nite-os/backend"
SRC_DIR="$BASE_DIR/src"

echo "--- PHASE 5: Redis & Mongo Integration ---"

# --- 1. Install Dependencies ---
echo "Installing Redis & Mongo packages..."
cd $BASE_DIR
npm install @nestjs/mongoose mongoose @nestjs/cache-manager cache-manager ioredis @nestjs/throttler
npm install -D @types/cache-manager

# --- 2. Create Analytics Schema (Mongo) ---
echo "Creating Mongo Schema..."
cat <<EOF > $SRC_DIR/modules/analytics/log.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type LogDocument = HydratedDocument<Log>;

@Schema({ timestamps: true })
export class Log {
  @Prop({ required: true })
  category: string; // e.g., 'POS', 'AUTH', 'SYSTEM'

  @Prop({ required: true })
  action: string; // e.g., 'CHECKOUT', 'LOGIN_FAIL'

  @Prop({ type: Object })
  meta: any; // Flexible JSON payload

  @Prop()
  userId: number; // Optional user ID linked to event
}

export const LogSchema = SchemaFactory.createForClass(Log);
EOF

# --- 3. Update Analytics Service (Write to Mongo) ---
echo "Updating Analytics Service..."
cat <<EOF > $SRC_DIR/modules/analytics/analytics.service.ts
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Log, LogDocument } from './log.schema';

@Injectable()
export class AnalyticsService {
  constructor(@InjectModel(Log.name) private logModel: Model<LogDocument>) {}

  getHealth() {
    return { status: 'ok', service: 'analytics', db: 'mongo' };
  }

  async logEvent(category: string, action: string, userId: number, meta: any = {}) {
    const newLog = new this.logModel({
      category,
      action,
      userId,
      meta,
    });
    return newLog.save();
  }

  async getRecentLogs(limit = 10) {
    return this.logModel.find().sort({ createdAt: -1 }).limit(limit).exec();
  }
}
EOF

# --- 4. Update Analytics Controller ---
cat <<EOF > $SRC_DIR/modules/analytics/analytics.controller.ts
import { Controller, Get, UseGuards } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

@Controller('analytics')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AnalyticsController {
  constructor(private readonly service: AnalyticsService) {}

  @Get('health')
  health() {
    return this.service.getHealth();
  }

  @Get('logs')
  @Roles('NITECORE_ADMIN', 'VENUE_ADMIN')
  async getLogs() {
    return this.service.getRecentLogs();
  }
}
EOF

# --- 5. Update Analytics Module (Register Mongo Feature) ---
cat <<EOF > $SRC_DIR/modules/analytics/analytics.module.ts
import { Module, Global } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { Log, LogSchema } from './log.schema';

@Global() // Global so POS module can use it easily
@Module({
  imports: [
    MongooseModule.forFeature([{ name: Log.name, schema: LogSchema }])
  ],
  controllers: [AnalyticsController],
  providers: [AnalyticsService],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}
EOF

# --- 6. Update POS Service to Log Events ---
# We inject AnalyticsService to log every sale
echo "Wiring POS to Analytics..."
cat <<EOF > $SRC_DIR/modules/pos/pos.service.ts
import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { PosTransaction } from './pos-transaction.entity';
import { User } from '../users/user.entity';
import { MarketItem } from '../market/market-item.entity';
import { NitecoinTransaction } from '../nitecoin/nitecoin-transaction.entity';
import { AnalyticsService } from '../analytics/analytics.service';

export interface CheckoutItemDto {
  itemId: number;
  count: number;
}

export interface CheckoutDto {
  nitetapId: string;
  items: CheckoutItemDto[];
}

@Injectable()
export class PosService {
  constructor(
    @InjectRepository(PosTransaction) private posRepo: Repository<PosTransaction>,
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(MarketItem) private itemRepo: Repository<MarketItem>,
    @InjectRepository(NitecoinTransaction) private nitecoinRepo: Repository<NitecoinTransaction>,
    private analytics: AnalyticsService,
  ) {}

  async checkout(venueId: number, dto: CheckoutDto, staffUser: any) {
    // Security Check
    if (staffUser.role !== 'NITECORE_ADMIN' && staffUser.venueId !== venueId) {
       throw new ForbiddenException('You are not authorized for this venue');
    }

    // 1. Find Customer
    const customer = await this.userRepo.findOne({ where: { nitetapId: dto.nitetapId } });
    if (!customer) throw new NotFoundException('NiteTap ID not found');

    // 2. Fetch Items
    const itemIds = dto.items.map((i) => i.itemId);
    const dbItems = await this.itemRepo.find({ where: { id: In(itemIds) } });
    
    // 3. Calc Totals
    let totalChf = 0;
    let totalNite = 0;

    for (const reqItem of dto.items) {
      const dbItem = dbItems.find((i) => i.id === reqItem.itemId);
      if (!dbItem) continue;
      totalChf += Number(dbItem.priceChf) * reqItem.count;
      totalNite += Number(dbItem.priceNite) * reqItem.count;
    }

    if (totalNite === 0 && totalChf === 0) throw new BadRequestException('No valid items');
    if (customer.niteBalance < totalNite) throw new BadRequestException(\`Insufficient Nitecoin\`);

    // 4. Execute
    customer.niteBalance = Number(customer.niteBalance) - totalNite;
    await this.userRepo.save(customer);

    if (totalNite > 0) {
      await this.nitecoinRepo.save({
        userId: customer.id,
        venueId: venueId,
        amount: -totalNite,
        type: 'SPEND'
      });
    }

    const receipt = await this.posRepo.save({
      venueId: venueId,
      staffId: staffUser.userId,
      userId: customer.id,
      nitetapId: dto.nitetapId,
      totalChf: totalChf,
      totalNite: totalNite,
      status: 'COMPLETED'
    });

    // 5. ASYNC ANALYTICS LOG (Fire & Forget)
    this.analytics.logEvent('POS', 'CHECKOUT', customer.id, {
        venueId,
        totalNite,
        receiptId: receipt.id
    });

    return {
      success: true,
      newBalance: customer.niteBalance,
      receiptId: receipt.id
    };
  }
}
EOF

# --- 7. Update App Module (Global Connections) ---
echo "Wiring App Module..."
cat <<EOF > $SRC_DIR/app.module.ts
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
    // 1. PostgreSQL (Relational Data)
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: '127.0.0.1',
      port: 5432,
      username: 'nite',
      password: 'nitepassword',
      database: 'nite_os',
      entities: [User, Venue, MarketItem, NitecoinTransaction, PosTransaction],
      synchronize: true,
    }),

    // 2. MongoDB (Analytics Logs)
    MongooseModule.forRoot('mongodb://127.0.0.1:27017/nite_analytics'),

    // 3. Redis (Cache & Rate Limits)
    CacheModule.register({
      isGlobal: true, 
      store: redisStore,
      host: '127.0.0.1',
      port: 6379,
    }),

    // 4. Throttler (Rate Limiting)
    ThrottlerModule.forRoot([{
      ttl: 60000, // 1 minute
      limit: 100, // 100 requests per minute per IP
    }]),

    // Feature Modules
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
      useClass: ThrottlerGuard, // Apply rate limiting globally
    },
  ],
})
export class AppModule {}
EOF

# --- 8. Rebuild & Restart ---
echo "Rebuilding backend..."
cd $BASE_DIR
npm run build

echo "Restarting PM2..."
pm2 restart nite-backend
sleep 5

# --- 9. Docs ---
if pm2 status nite-backend | grep -q "online"; then
    echo "✅ Phase 5 Deployed: Redis & Mongo Active."

    # Update Roadmap
    cat << 'DOCEOF' > /opt/nite-os/docs/V8-Roadmap.md
# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)
## Phase 1 – Backend Skeleton (DONE)
## Phase 2 – Core Entities (DONE)
## Phase 3 – Market + POS Logic (DONE)
## Phase 4 – Auth & Roles (DONE)

## Phase 5 – Redis + Mongo (DONE)
- **MongoDB**: Configured for Analytics.
- **Redis**: Configured for Caching.
- **Rate Limiting**: Applied globally (100 req/min).
- **Analytics**: Auto-logging POS transactions to Mongo.

---

## Phase 6 – Frontend SPA (NEXT)
Goal: Visible UI.
- Vue 3 + Vite.
- Feed, Market, Profile, Radio.
DOCEOF

    # Update Log
    cat << 'DOCEOF' >> /opt/nite-os/docs/V8-Phase-Log.md

## 2025-12-05 – Phase 5 – Redis + Mongo
- Installed Redis/Mongo dependencies.
- Configured \`MongooseModule\` and \`CacheModule\`.
- Implemented \`AnalyticsService\` to write to Mongo.
- Wired POS service to log sales to Analytics.
- Enabled Global Rate Limiting.
DOCEOF

    echo "✅ Docs updated."
else
    echo "❌ Deployment failed."
    pm2 logs nite-backend --lines 20 --nostream
fi
