#!/bin/bash

echo "--- 🧹 CLEANING NGINX & FIXING PATHS ---"

# 1. DIAGNOSE PATH
# We need to see exactly what is inside the dist folder.
echo "1. verifying build directory..."
if [ -f "/opt/nite-os/frontend/dist/index.html" ]; then
    echo "   ✅ Found: /opt/nite-os/frontend/dist/index.html"
else
    echo "   ❌ MISSING: /opt/nite-os/frontend/dist/index.html"
    echo "   Listing /opt/nite-os/frontend:"
    ls -F /opt/nite-os/frontend/
    echo "   Listing /opt/nite-os/frontend/dist (if exists):"
    ls -F /opt/nite-os/frontend/dist/ 2>/dev/null
    
    # Attempt rapid rebuild if missing
    echo "   ⚠️ Attempting emergency rebuild..."
    cd /opt/nite-os/frontend
    npm run build
fi

# 2. FIX PERMISSIONS (Force www-data ownership)
echo "2. Setting Permissions..."
chown -R www-data:www-data /opt/nite-os/frontend/dist
chmod -R 755 /opt/nite-os/frontend/dist

# 3. NUKE CONFLICTS (Remove all active sites to clear the conflict)
echo "3. Clearing Nginx conflicts..."
rm -f /etc/nginx/sites-enabled/*

# 4. WRITE SINGLE CLEAN CONFIG
echo "4. Writing fresh config..."
cat <<EOF > /etc/nginx/sites-available/nite-os_final
server {
    listen 80 default_server;
    server_name os.peoplewelike.club 31.97.126.86 _;

    root /opt/nite-os/frontend/dist;
    index index.html;

    # Serve Static Files
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Proxy API
    location /api/ {
        proxy_pass http://127.0.0.1:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# 5. ENABLE & RELOAD
echo "5. Activating new config..."
ln -s /etc/nginx/sites-available/nite-os_final /etc/nginx/sites-enabled/nite-os_final

# Test Syntax
nginx -t
if [ $? -eq 0 ]; then
    systemctl restart nginx
    echo "   ✅ Nginx Restarted Successfully."
    echo "   Please refresh http://os.peoplewelike.club"
else
    echo "   ❌ Nginx Syntax Error. Config was not applied."
fi
