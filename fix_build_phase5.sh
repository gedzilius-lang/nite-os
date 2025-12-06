#!/bin/bash

BASE_DIR="/opt/nite-os/backend"

echo "--- 🔧 FIXING BUILD: PHASE 5 ---"

# 1. Stop Backend
pm2 delete nite-backend 2>/dev/null || true

# 2. Install Missing Dependency
echo "1. Installing 'cache-manager-ioredis'..."
cd $BASE_DIR
npm install cache-manager-ioredis
npm install -D @types/cache-manager-ioredis

# 3. Rebuild
echo "2. Rebuilding backend..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ BUILD FAILED AGAIN. Please check logs."
    exit 1
fi

# 4. Start Backend
echo "3. Starting Backend..."
# Ensure DBs are up
systemctl start redis-server
systemctl start mongod 2>/dev/null || systemctl start mongodb 2>/dev/null

pm2 start dist/main.js --name nite-backend
echo "   Waiting 15s for full boot..."
sleep 15

# 5. Verify Logic (Seed -> Login -> Checkout -> Logs)
echo "--- VERIFYING PHASE 5 ---"

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

# C. Checkout (Trigger Log)
echo "C. Checkout..."
CHECKOUT_RES=$(curl -s -X POST http://127.0.0.1:3000/api/pos/1/checkout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{ "nitetapId": "TAP-TEST", "items": [{"itemId": 1, "count": 1}] }')

if [[ "$CHECKOUT_RES" == *"success\":true"* ]]; then
    echo "   ✅ Checkout Success."
else
    echo "   ❌ Checkout Failed: $CHECKOUT_RES"
    exit 1
fi

# D. Check Mongo Logs
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
