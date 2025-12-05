#!/bin/bash

BASE_DIR="/opt/nite-os/backend/src/modules"

echo "--- PHASE 3: Market & POS Logic ---"

# --- 1. Update Market Service (Fetch items & Seed) ---
cat <<EOF > $BASE_DIR/market/market.service.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MarketItem } from './market-item.entity';

@Injectable()
export class MarketService {
  constructor(
    @InjectRepository(MarketItem)
    private itemRepo: Repository<MarketItem>,
  ) {}

  // Fetch active items for a venue
  async getItemsByVenue(venueId: number) {
    return this.itemRepo.find({
      where: { venueId, active: true },
      order: { title: 'ASC' },
    });
  }

  // Temporary Seed Helper (for testing)
  async seedDemoData(venueId: number) {
    const items = [
      { title: 'Beer', priceChf: 8.0, priceNite: 50, venueId, active: true },
      { title: 'Long Drink', priceChf: 15.0, priceNite: 120, venueId, active: true },
      { title: 'Shot', priceChf: 5.0, priceNite: 30, venueId, active: true },
      { title: 'VIP Table', priceChf: 200.0, priceNite: 2000, venueId, active: true },
    ];
    // Clear old items for this venue to avoid dupes
    await this.itemRepo.delete({ venueId });
    return this.itemRepo.save(items);
  }
}
EOF

# --- 2. Update Market Controller ---
cat <<EOF > $BASE_DIR/market/market.controller.ts
import { Controller, Get, Param, Post } from '@nestjs/common';
import { MarketService } from './market.service';

@Controller('market')
export class MarketController {
  constructor(private readonly service: MarketService) {}

  @Get(':venueId/items')
  async getItems(@Param('venueId') venueId: string) {
    return this.service.getItemsByVenue(Number(venueId));
  }

  // Helper to generate data for manual testing
  @Post(':venueId/seed')
  async seed(@Param('venueId') venueId: string) {
    return this.service.seedDemoData(Number(venueId));
  }
}
EOF

# --- 3. Update POS Module (Import Dependencies) ---
# We need access to User, MarketItem, and NitecoinTransaction repositories.
cat <<EOF > $BASE_DIR/pos/pos.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PosController } from './pos.controller';
import { PosService } from './pos.service';
import { PosTransaction } from './pos-transaction.entity';

// Import other modules to access their Repositories
import { UsersModule } from '../users/users.module';
import { MarketModule } from '../market/market.module';
import { NitecoinModule } from '../nitecoin/nitecoin.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([PosTransaction]),
    UsersModule,    // Access to UserRepository
    MarketModule,   // Access to MarketItemRepository
    NitecoinModule, // Access to NitecoinTransactionRepository
  ],
  controllers: [PosController],
  providers: [PosService],
})
export class PosModule {}
EOF

# --- 4. Update POS Service (The Core Logic) ---
cat <<EOF > $BASE_DIR/pos/pos.service.ts
import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { PosTransaction } from './pos-transaction.entity';
import { User } from '../users/user.entity';
import { MarketItem } from '../market/market-item.entity';
import { NitecoinTransaction } from '../nitecoin/nitecoin-transaction.entity';

export interface CheckoutItemDto {
  itemId: number;
  count: number;
}

export interface CheckoutDto {
  nitetapId: string;
  items: CheckoutItemDto[];
  staffId: number; // In real app, this comes from JWT
}

@Injectable()
export class PosService {
  constructor(
    @InjectRepository(PosTransaction) private posRepo: Repository<PosTransaction>,
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(MarketItem) private itemRepo: Repository<MarketItem>,
    @InjectRepository(NitecoinTransaction) private nitecoinRepo: Repository<NitecoinTransaction>,
  ) {}

  async checkout(venueId: number, dto: CheckoutDto) {
    // 1. Find User
    const user = await this.userRepo.findOne({ where: { nitetapId: dto.nitetapId } });
    if (!user) {
      throw new NotFoundException('NiteTap ID not found');
    }

    // 2. Fetch Items
    const itemIds = dto.items.map((i) => i.itemId);
    const dbItems = await this.itemRepo.find({ where: { id: In(itemIds) } });
    
    // 3. Calculate Totals
    let totalChf = 0;
    let totalNite = 0;

    for (const reqItem of dto.items) {
      const dbItem = dbItems.find((i) => i.id === reqItem.itemId);
      if (!dbItem) continue; // Skip invalid IDs
      totalChf += Number(dbItem.priceChf) * reqItem.count;
      totalNite += Number(dbItem.priceNite) * reqItem.count;
    }

    if (totalNite === 0 && totalChf === 0) {
      throw new BadRequestException('No valid items found');
    }

    // 4. Check Balance
    if (user.niteBalance < totalNite) {
      throw new BadRequestException(\`Insufficient Nitecoin. Required: \${totalNite}, Has: \${user.niteBalance}\`);
    }

    // 5. Execute Transaction (Deduct Balance)
    user.niteBalance = Number(user.niteBalance) - totalNite;
    await this.userRepo.save(user);

    // 6. Log Nitecoin Spend
    if (totalNite > 0) {
      await this.nitecoinRepo.save({
        userId: user.id,
        venueId: venueId,
        amount: -totalNite,
        type: 'SPEND'
      });
    }

    // 7. Create POS Receipt
    const receipt = await this.posRepo.save({
      venueId: venueId,
      staffId: dto.staffId,
      userId: user.id,
      nitetapId: dto.nitetapId,
      totalChf: totalChf,
      totalNite: totalNite,
      status: 'COMPLETED'
    });

    return {
      success: true,
      newBalance: user.niteBalance,
      receiptId: receipt.id,
      totalNitePaid: totalNite
    };
  }
}
EOF

# --- 5. Update POS Controller ---
cat <<EOF > $BASE_DIR/pos/pos.controller.ts
import { Controller, Post, Body, Param, Get } from '@nestjs/common';
import { PosService, CheckoutDto } from './pos.service';

@Controller('pos')
export class PosController {
  constructor(private readonly service: PosService) {}

  @Post(':venueId/checkout')
  async checkout(
    @Param('venueId') venueId: string,
    @Body() dto: CheckoutDto
  ) {
    return this.service.checkout(Number(venueId), dto);
  }

  @Get('health')
  health() {
    return { status: 'ok', service: 'pos' };
  }
}
EOF

# --- 6. Rebuild & Restart ---
echo "Rebuilding backend..."
cd /opt/nite-os/backend
npm run build

echo "Restarting PM2..."
pm2 restart nite-backend

# --- 7. Update Docs ---
# Verify service is up before writing docs
sleep 5
if curl -s http://127.0.0.1:3000/api/pos/health | grep "ok"; then
    echo "✅ Phase 3 Logic Deployed."

    # Update Roadmap
    cat << 'DOCEOF' > /opt/nite-os/docs/V8-Roadmap.md
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
DOCEOF

    # Update Phase Log
    cat << 'DOCEOF' >> /opt/nite-os/docs/V8-Phase-Log.md

## 2025-12-05 – Phase 3 – Market & POS Logic
- Implemented \`GET /api/market/:venueId/items\`.
- Implemented \`POST /api/pos/:venueId/checkout\`.
- Added logic to deduct Nitecoin balance and log transactions.
- Added dependency injection between POS, Users, Market, and Nitecoin modules.
DOCEOF

    echo "✅ Docs updated."
    echo "Ready for testing!"
else
    echo "❌ Deployment failed. Check logs."
fi
