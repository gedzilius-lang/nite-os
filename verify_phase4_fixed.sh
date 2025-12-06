#!/bin/bash

echo "--- 🔐 PHASE 4 VERIFICATION (FIXED) ---"

# 1. CREATE/SEED the Admin User FIRST
echo "1. Seeding Admin User & Test Data..."
SEED_RES=$(curl -s -X POST http://localhost:3000/api/users/demo)

if [[ "$SEED_RES" == *"admin"* ]]; then
    echo "   ✅ Seed Success. Admin user 'admin' ensures."
else
    echo "   ⚠️ Seed response unexpected (might still work if user exists): $SEED_RES"
fi

# 2. Login as Admin to get JWT
echo "2. Logging in as 'admin'..."
LOGIN_RES=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}')

# Extract Token
TOKEN=$(echo $LOGIN_RES | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login Failed. Response: $LOGIN_RES"
  exit 1
else
  echo "   ✅ Login Success. Token captured."
fi

# 3. Perform Checkout with Token
echo "3. Attempting Checkout (Authorized)..."
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

echo "--- 4. Testing Unauthorized Access (Expected Failure) ---"
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
