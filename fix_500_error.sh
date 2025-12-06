#!/bin/bash

echo "--- 🔧 FIXING 500 ERROR ---"

# 1. FIX PERMISSIONS (Most likely cause)
# Nginx runs as 'www-data' and needs read/execute access to the path.
echo "1. Adjusting Permissions..."
chown -R root:www-data /opt/nite-os/frontend/dist
chmod -R 755 /opt/nite-os/frontend/dist
# Ensure parent directories are executable (traversable)
chmod 755 /opt/nite-os
chmod 755 /opt

# 2. CHECK CONFIG SYNTAX
echo "2. Checking Nginx Syntax..."
nginx -t

if [ $? -eq 0 ]; then
    echo "   ✅ Syntax OK. Reloading..."
    systemctl reload nginx
else
    echo "   ❌ Syntax Error found!"
    exit 1
fi

# 3. DIAGNOSTICS
echo "3. Checking Error Logs (Last 20 lines)..."
echo "---------------------------------------------------"
tail -n 20 /var/log/nginx/error.log
echo "---------------------------------------------------"

echo "4. Checking Backend Status..."
if pm2 status nite-backend | grep -q "online"; then
    echo "   ✅ Backend is ONLINE."
else
    echo "   ❌ Backend is OFFLINE."
    pm2 logs nite-backend --lines 10 --nostream
fi

echo "--- DONE. Try refreshing the site now. ---"
