#!/bin/bash

echo "--- 🌐 CONFIGURING DOMAIN: os.peoplewelike.club ---"

# 1. Update Nginx Config
# We add the domain to 'server_name' so Nginx knows it's authoritative for it.
cat <<EOF > /etc/nginx/sites-available/nite-os
server {
    listen 80;
    server_name os.peoplewelike.club 31.97.126.86 _;

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

# 2. Reload Nginx
echo "Reloading Nginx..."
if systemctl reload nginx; then
    echo "✅ Nginx updated successfully."
    echo "👉 PLEASE NOTE: You must update your DNS A Record for 'os.peoplewelike.club' to point to 31.97.126.86"
else
    echo "❌ Nginx reload failed. Checking logs..."
    systemctl status nginx --no-pager
fi
