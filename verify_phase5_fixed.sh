#!/bin/bash

echo "--- 📊 PHASE 5 VERIFICATION: REDIS & MONGO (FIXED) ---"

# 1. Seed Admin User & Test Data (CRITICAL STEP FIRST)
echo "1. Seeding Admin User..."
SEED_RES=$(curl -s -X POST http://localhost:3000/api/users/demo)
if [[ "$SEED_RES" == *"admin"* ]]; then
    echo "   ✅ Seed Success."
else
    echo "   ⚠️ Seed response unexpected: $SEED_RES"
fi

# 2. Login as Admin
echo "2. Logging in..."
LOGIN_RES=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}')

TOKEN=$(echo $LOGIN_RES | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login Failed. Response: $LOGIN_RES"
  exit 1
fi
echo "   ✅ Token acquired."

# 3. Perform Checkout (Triggers Log)
echo "3. Performing Checkout..."
CHECKOUT_RES=$(curl -s -X POST http://localhost:3000/api/pos/1/checkout \
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

# 4. Fetch Logs from Mongo
echo "4. Fetching Analytics Logs..."
sleep 2 # Give async logging a moment

LOGS_RES=$(curl -s -X GET http://localhost:3000/api/analytics/logs \
  -H "Authorization: Bearer $TOKEN")

# Check if we see the checkout action
if [[ "$LOGS_RES" == *"CHECKOUT"* ]]; then
    echo "   ✅ Log Found in Mongo!"
    echo "   Latest Log snippet: $(echo $LOGS_RES | cut -c 1-100)..."
else
    echo "   ❌ Log NOT found in Mongo."
    echo "   Response: $LOGS_RES"
    exit 1
fi

echo "--- Phase 5 Verification Complete ---"
