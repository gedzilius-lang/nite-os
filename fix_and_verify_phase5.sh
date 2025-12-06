#!/bin/bash

echo "--- 🔧 FIXING SERVICES & VERIFYING PHASE 5 ---"

# 1. Start Infrastructure Services
echo "1. Starting Redis and MongoDB..."
systemctl start redis-server
# Try both common service names for Mongo
systemctl start mongod 2>/dev/null || systemctl start mongodb 2>/dev/null

# 2. Restart Backend
echo "2. Restarting Backend..."
pm2 restart nite-backend > /dev/null
echo "   Waiting 10s for boot..."
sleep 10

# 3. Check App Status (Show Logs if crashed)
if pm2 status nite-backend | grep -q "online"; then
    echo "   Backend Status: ONLINE"
else
    echo "   ❌ Backend is OFFLINE. Showing logs:"
    pm2 logs nite-backend --lines 20 --nostream
    exit 1
fi

# 4. Run Verification Logic
echo "3. Seeding Admin User..."
# Force IPv4 127.0.0.1 to avoid localhost IPv6 issues
SEED_RES=$(curl -s -X POST http://127.0.0.1:3000/api/users/demo)

if [[ "$SEED_RES" == *"admin"* ]]; then
    echo "   ✅ Seed Success."
else
    echo "   ⚠️ Seed response unexpected: $SEED_RES"
    # If seed fails, dump logs to see why
    echo "   Dumping last 10 lines of logs:"
    pm2 logs nite-backend --lines 10 --nostream
fi

echo "4. Logging in..."
LOGIN_RES=$(curl -s -X POST http://127.0.0.1:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}')

TOKEN=$(echo $LOGIN_RES | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login Failed. Response: $LOGIN_RES"
  exit 1
fi
echo "   ✅ Token acquired."

echo "5. Performing Checkout (Triggers Log)..."
CHECKOUT_RES=$(curl -s -X POST http://127.0.0.1:3000/api/pos/1/checkout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nitetapId": "TAP-TEST",
    "items": [{"itemId": 1, "count": 1}]
  }')

if [[ "$CHECKOUT_RES" == *"success\":true"* ]]; then
    echo "   ✅ Checkout done."
else
    echo "   ❌ Checkout failed. Response: $CHECKOUT_RES"
    exit 1
fi

echo "6. Fetching Analytics Logs from Mongo..."
sleep 2
LOGS_RES=$(curl -s -X GET http://127.0.0.1:3000/api/analytics/logs \
  -H "Authorization: Bearer $TOKEN")

if [[ "$LOGS_RES" == *"CHECKOUT"* ]]; then
    echo "   ✅ Log Found in Mongo!"
else
    echo "   ❌ Log NOT found in Mongo. Response: $LOGS_RES"
    exit 1
fi

echo "--- ✅ PHASE 5 VERIFIED SUCCESS ---"
