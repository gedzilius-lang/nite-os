#!/bin/bash

FRONT_DIR="/opt/nite-os/frontend"

echo "--- 🔧 REPAIRING PHASE 6 (FRONTEND) ---"

# 1. Build Frontend
echo "1. Building Frontend Assets..."
if [ -d "$FRONT_DIR" ]; then
    cd $FRONT_DIR
    # Install deps if missing
    if [ ! -d "node_modules" ]; then
        echo "   Installing dependencies..."
        npm install
    fi
    
    # Run Build
    echo "   Running 'npm run build'..."
    npm run build
    
    # Verify Build
    if [ -f "$FRONT_DIR/dist/index.html" ]; then
        echo "   ✅ Build Successful. 'dist/index.html' exists."
    else
        echo "   ❌ Build Failed. 'dist' folder is missing."
        exit 1
    fi
else
    echo "   ❌ Frontend directory not found at $FRONT_DIR"
    exit 1
fi

# 2. Configure Nginx
echo "2. Configuring Nginx..."
cat <<EOF > /etc/nginx/sites-available/nite-os
server {
    listen 80;
    server_name _;

    # Frontend (Static Files)
    location / {
        root /opt/nite-os/frontend/dist;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API (Reverse Proxy)
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

# Link and Test
ln -sf /etc/nginx/sites-available/nite-os /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo "3. Restarting Nginx..."
# Stop first to clear any hung processes
systemctl stop nginx
systemctl start nginx

# Check Status
if systemctl status nginx | grep -q "active (running)"; then
    echo "   ✅ Nginx is running."
else
    echo "   ❌ Nginx failed to start. Logs:"
    journalctl -u nginx --no-pager | tail -n 10
    exit 1
fi

# 4. Final Verification
echo "4. Testing HTTP Connection..."
HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}\n" http://127.0.0.1)

if [ "$HTTP_CODE" == "200" ]; then
    echo "   ✅ SUCCESS: Site returns HTTP 200 OK."
    echo "   You can now view the site at http://$(curl -s ifconfig.me)"
else
    echo "   ❌ Verification Failed. HTTP Code: $HTTP_CODE"
    exit 1
fi
