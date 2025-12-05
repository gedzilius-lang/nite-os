#!/bin/bash

BASE_DIR="/opt/nite-os/backend/src/modules/users"

echo "--- Preparing Test Environment ---"

# 1. Add createDemoUser to UsersService
cat <<EOF > $BASE_DIR/users.service.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}

  getHealth() {
    return { status: 'ok', service: 'users', timestamp: new Date().toISOString() };
  }

  async createDemoUser() {
    // Create or reset a demo user
    let user = await this.userRepo.findOne({ where: { nitetapId: 'TAP-TEST' } });
    if (!user) {
        user = this.userRepo.create({
            nitetapId: 'TAP-TEST',
            niteBalance: 1000, 
            xp: 100,
            level: 5,
            role: 'USER'
        });
    } else {
        user.niteBalance = 1000; // Reset balance
    }
    return this.userRepo.save(user);
  }
}
EOF

# 2. Expose it in UsersController
cat <<EOF > $BASE_DIR/users.controller.ts
import { Controller, Get, Post } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get('health')
  healthCheck() {
    return this.service.getHealth();
  }

  @Post('demo')
  async createDemo() {
    return this.service.createDemoUser();
  }
}
EOF

# 3. Restart Backend
echo "Rebuilding and restarting..."
cd /opt/nite-os/backend
npm run build > /dev/null
pm2 restart nite-backend > /dev/null
sleep 5 # Wait for boot

# 4. Run Simulation
echo "--- 🧪 STARTING SIMULATION ---"

echo "1. Seeding Market for Venue 1..."
curl -s -X POST http://localhost:3000/api/market/1/seed | grep "id" > /dev/null && echo "   ✅ Market Seeded" || echo "   ❌ Market Seed Failed"

echo "2. Creating Test User (TAP-TEST)..."
curl -s -X POST http://localhost:3000/api/users/demo > /dev/null && echo "   ✅ User Created (Balance: 1000)" || echo "   ❌ User Creation Failed"

echo "3. Fetching Items..."
# Get ID of first item (Beer)
ITEM_ID=$(curl -s http://localhost:3000/api/market/1/items | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
echo "   Found Item ID: $ITEM_ID"

echo "4. Performing Checkout (Buying 2 Beers)..."
# Buy 2 units of Item 1
RESPONSE=$(curl -s -X POST http://localhost:3000/api/pos/1/checkout \
  -H "Content-Type: application/json" \
  -d "{
    \"nitetapId\": \"TAP-TEST\", 
    \"staffId\": 99,
    \"items\": [{\"itemId\": $ITEM_ID, \"count\": 2}] 
  }")

echo "   Response: $RESPONSE"

if [[ "$RESPONSE" == *"success\":true"* ]]; then
    echo "   ✅ CHECKOUT SUCCESSFUL!"
    echo "   See receipt ID and new balance above."
else
    echo "   ❌ CHECKOUT FAILED."
fi

echo "--- Simulation Complete ---"
