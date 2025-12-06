#!/bin/bash

echo "--- 🔐 PHASE 4 VERIFICATION ---"

# 1. Login as Admin to get JWT
echo "1. Logging in as 'admin'..."
LOGIN_RES=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}')

# Extract Token (simple grep/cut parsing to avoid jq dependency)
TOKEN=$(echo $LOGIN_RES | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login Failed. Response: $LOGIN_RES"
  exit 1
else
  echo "   ✅ Login Success. Token captured."
fi

# 2. Reset Balance for Test User (so checkout doesn't fail on funds)
curl -s -X POST http://localhost:3000/api/users/demo > /dev/null

# 3. Perform Checkout with Token
echo "2. Attempting Checkout (Authorized)..."
CHECKOUT_RES=$(curl -s -X POST http://localhost:3000/api/pos/1/checkout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nitetapId": "TAP-TEST",
    "items": [{"itemId": 1, "count": 1}]
  }')

if [[ "$CHECKOUT_RES" == *"success\":true"* ]]; then
    echo "   ✅ Checkout Successful!"
    echo "   Response: $CHECKOUT_RES"
else
    echo "   ❌ Checkout Failed."
    echo "   Response: $CHECKOUT_RES"
    exit 1
fi

echo "--- 3. Testing Unauthorized Access (Expected Failure) ---"
FAIL_RES=$(curl -s -X POST http://localhost:3000/api/pos/1/checkout \
  -H "Content-Type: application/json" \
  -d '{
    "nitetapId": "TAP-TEST",
    "items": [{"itemId": 1, "count": 1}]
  }')

if [[ "$FAIL_RES" == *"Unauthorized"* ]]; then
    echo "   ✅ Guard correctly blocked request without token."
else
    echo "   ❌ Guard Failed (Request was allowed?)"
    echo "   Response: $FAIL_RES"
fi

echo "--- Phase 4 Verification Complete ---"
