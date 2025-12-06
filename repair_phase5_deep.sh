#!/bin/bash

BASE_DIR="/opt/nite-os/backend"

echo "--- 🔧 DEEP REPAIR: PHASE 5 ---"

# 1. Stop Everything & Clean Up
echo "1. Stopping services and cleaning files..."
pm2 delete nite-backend 2>/dev/null || true
cd $BASE_DIR
rm -rf dist node_modules package-lock.json

# 2. Fresh Install
echo "2. Installing dependencies (this may take a minute)..."
# Explicitly installing the Phase 5 deps again to be 100% sure
npm install @nestjs/common @nestjs/core @nestjs/platform-express @nestjs/typeorm typeorm pg reflect-metadata rxjs class-validator class-transformer
npm install @nestjs/jwt @nestjs/passport passport passport-jwt bcryptjs
npm install @nestjs/mongoose mongoose @nestjs/cache-manager cache-manager ioredis @nestjs/throttler
npm install -D @nestjs/cli @nestjs/schematics @nestjs/testing @types/express @types/node @types/passport-jwt @types/bcryptjs @types/cache-manager ts-loader ts-node tsconfig-paths typescript eslint prettier

# 3. Rebuild
echo "3. Building backend..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ BUILD FAILED. Stopping here."
    exit 1
fi

# 4. Start Services
echo "4. Ensuring Infra is up..."
systemctl restart redis-server
systemctl restart mongod 2>/dev/null || systemctl restart mongodb 2>/dev/null

echo "5. Starting Backend..."
pm2 start dist/main.js --name nite-backend
echo "   Waiting 15s for full boot..."
sleep 15

# 5. Check Health
HEALTH=$(curl -s http://127.0.0.1:3000/api/users/health)
if [[ "$HEALTH" != *"ok"* ]]; then
    echo "❌ Health check failed. Logs:"
    pm2 logs nite-backend --lines 20 --nostream
    exit 1
fi
echo "   ✅ Backend is ONLINE."

# 6. Run Verification
echo "--- VERIFYING LOGIC ---"

# A. Seed Admin
echo "A. Seeding Admin..."
curl -s -X POST http://127.0.0.1:3000/api/users/demo > /dev/null

# B. Login
echo "B. Logging in..."
LOGIN_RES=$(curl -s -X POST http://127.0.0.1:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}')

TOKEN=$(echo $LOGIN_RES | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login Failed."
  exit 1
fi

# C. Checkout
echo "C. Checkout..."
curl -s -X POST http://127.0.0.1:3000/api/pos/1/checkout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{ "nitetapId": "TAP-TEST", "items": [{"itemId": 1, "count": 1}] }' > /dev/null

# D. Check Logs
echo "D. Checking Mongo Logs..."
sleep 2
LOGS=$(curl -s -X GET http://127.0.0.1:3000/api/analytics/logs -H "Authorization: Bearer $TOKEN")

if [[ "$LOGS" == *"CHECKOUT"* ]]; then
    echo "   ✅ SUCCESS: Log found in MongoDB!"
    echo "   Phase 5 is FULLY VERIFIED."
else
    echo "   ❌ Failed to find log. Response: $LOGS"
    exit 1
fi
