#!/bin/bash

echo "--- 📊 PHASE 5 VERIFICATION: REDIS & MONGO ---"

# 1. Login as Admin
echo "1. Logging in..."
LOGIN_RES=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}')

TOKEN=$(echo $LOGIN_RES | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login Failed."
  exit 1
fi
echo "   ✅ Token acquired."

# 2. Reset User & Perform Checkout (Triggers Log)
echo "2. Performing Checkout (to trigger log)..."
curl -s -X POST http://localhost:3000/api/users/demo > /dev/null

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
    echo "   ❌ Checkout failed."
    exit 1
fi

# 3. Fetch Logs from Mongo
echo "3. Fetching Analytics Logs..."
sleep 2 # Give async logging a moment

LOGS_RES=$(curl -s -X GET http://localhost:3000/api/analytics/logs \
  -H "Authorization: Bearer $TOKEN")

# Check if we see the checkout action
if [[ "$LOGS_RES" == *"CHECKOUT"* ]]; then
    echo "   ✅ Log Found in Mongo!"
    echo "   Latest Logs: $(echo $LOGS_RES | cut -c 1-100)..."
else
    echo "   ❌ Log NOT found. Mongo wiring might be broken."
    echo "   Response: $LOGS_RES"
    exit 1
fi

echo "--- Phase 5 Verification Complete ---"
