#!/bin/bash

BASE_DIR="/opt/nite-os/backend/src"

echo "--- PHASE 2: Core Entities & Wiring ---"

# --- 1. Define Entities ---

# User Entity (Updated)
echo "Updating User Entity..."
cat <<EOF > $BASE_DIR/modules/users/user.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  externalId: string; // e.g. Auth0 or generic external ID

  @Column({ unique: true, nullable: true })
  nitetapId: string; // Physical card ID

  @Column({ nullable: true })
  apiKey: string; // For programmatic access

  @Column({ default: 'USER' })
  role: string; // USER, STAFF, VENUE_ADMIN, NITECORE_ADMIN

  @Column({ nullable: true })
  venueId: number; // Linked venue (if staff/admin)

  @Column({ default: 0 })
  xp: number;

  @Column({ default: 1 })
  level: number;

  @Column({ type: 'decimal', default: 0 })
  niteBalance: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
EOF

# Venue Entity
echo "Creating Venue Entity..."
cat <<EOF > $BASE_DIR/modules/venues/venue.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('venues')
export class Venue {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  slug: string; // e.g. 'club-xy'

  @Column()
  title: string;

  @Column()
  city: string;

  @Column({ default: 'active' })
  status: string; // active, disabled

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
EOF

# MarketItem Entity
echo "Creating MarketItem Entity..."
cat <<EOF > $BASE_DIR/modules/market/market-item.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('market_items')
export class MarketItem {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  venueId: number; // FK to Venue

  @Column()
  title: string;

  @Column({ type: 'decimal' })
  priceChf: number;

  @Column({ type: 'decimal' })
  priceNite: number;

  @Column({ default: true })
  active: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
EOF

# NitecoinTransaction Entity
echo "Creating NitecoinTransaction Entity..."
cat <<EOF > $BASE_DIR/modules/nitecoin/nitecoin-transaction.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('nitecoin_transactions')
export class NitecoinTransaction {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  userId: number; // Who spent/earned

  @Column({ nullable: true })
  venueId: number; // Where it happened

  @Column({ type: 'decimal' })
  amount: number; // Positive = earn, Negative = spend

  @Column()
  type: string; // 'EARN', 'SPEND', 'ADJUSTMENT'

  @CreateDateColumn()
  createdAt: Date;
}
EOF

# PosTransaction Entity
echo "Creating PosTransaction Entity..."
cat <<EOF > $BASE_DIR/modules/pos/pos-transaction.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('pos_transactions')
export class PosTransaction {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  venueId: number;

  @Column()
  staffId: number; // User ID of staff member

  @Column({ nullable: true })
  userId: number; // User ID of customer (if known)

  @Column({ nullable: true })
  nitetapId: string; // Card ID presented

  @Column({ type: 'decimal', default: 0 })
  totalChf: number;

  @Column({ type: 'decimal', default: 0 })
  totalNite: number;

  @Column({ default: 'COMPLETED' })
  status: string;

  @CreateDateColumn()
  createdAt: Date;
}
EOF

# --- 2. Update Modules to Register Entities ---

# Users Module
cat <<EOF > $BASE_DIR/modules/users/users.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { User } from './user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [TypeOrmModule],
})
export class UsersModule {}
EOF

# Venues Module
cat <<EOF > $BASE_DIR/modules/venues/venues.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { VenuesController } from './venues.controller';
import { VenuesService } from './venues.service';
import { Venue } from './venue.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Venue])],
  controllers: [VenuesController],
  providers: [VenuesService],
  exports: [TypeOrmModule],
})
export class VenuesModule {}
EOF

# Market Module
cat <<EOF > $BASE_DIR/modules/market/market.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MarketController } from './market.controller';
import { MarketService } from './market.service';
import { MarketItem } from './market-item.entity';

@Module({
  imports: [TypeOrmModule.forFeature([MarketItem])],
  controllers: [MarketController],
  providers: [MarketService],
  exports: [TypeOrmModule],
})
export class MarketModule {}
EOF

# Nitecoin Module
cat <<EOF > $BASE_DIR/modules/nitecoin/nitecoin.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NitecoinController } from './nitecoin.controller';
import { NitecoinService } from './nitecoin.service';
import { NitecoinTransaction } from './nitecoin-transaction.entity';

@Module({
  imports: [TypeOrmModule.forFeature([NitecoinTransaction])],
  controllers: [NitecoinController],
  providers: [NitecoinService],
  exports: [TypeOrmModule],
})
export class NitecoinModule {}
EOF

# Pos Module
cat <<EOF > $BASE_DIR/modules/pos/pos.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PosController } from './pos.controller';
import { PosService } from './pos.service';
import { PosTransaction } from './pos-transaction.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PosTransaction])],
  controllers: [PosController],
  providers: [PosService],
  exports: [TypeOrmModule],
})
export class PosModule {}
EOF

# --- 3. Update App Module (Register All Entities) ---

echo "Updating App Module..."
cat <<EOF > $BASE_DIR/app.module.ts
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
      entities: [
        User, 
        Venue, 
        MarketItem, 
        NitecoinTransaction, 
        PosTransaction
      ],
      synchronize: true, // Auto-creates tables
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

# --- 4. Rebuild & Restart ---

echo "Rebuilding..."
cd /opt/nite-os/backend
npm run build

echo "Restarting PM2..."
pm2 restart nite-backend

echo "Waiting for DB Sync..."
sleep 10

# --- 5. Verify & Update Docs ---

if pm2 status nite-backend | grep -q "online"; then
  echo "✅ Phase 2 Success: Entities deployed and running."

  # Update V8-Roadmap.md
  cat << 'DOCEOF' > /opt/nite-os/docs/V8-Roadmap.md
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
DOCEOF

  # Update V8-Phase-Log.md
  cat << 'DOCEOF' >> /opt/nite-os/docs/V8-Phase-Log.md

## 2025-12-05 – Phase 2 – Core Entities
- Implemented full Entity definitions for User, Venue, MarketItem, NitecoinTransaction, PosTransaction.
- Wired all modules to use \`TypeOrmModule.forFeature\`.
- Registered all entities in \`AppModule\`.
- Postgres tables successfully created/synced.
DOCEOF

  echo "✅ Docs updated."
  echo "You can now run: git status && git add . && git commit -m 'Phase 2 Complete' && git push"

else
  echo "❌ Phase 2 Failed. Checking logs..."
  pm2 logs nite-backend --lines 20 --nostream
fi
