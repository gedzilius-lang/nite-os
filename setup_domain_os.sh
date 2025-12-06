#!/bin/bash

echo "--- 🌐 CONFIGURING DOMAIN: os.peoplewelike.club ---"

# 1. Update Nginx Config
# We add 'os.peoplewelike.club' to the server_name directive.
# We also keep the IP address and localhost for flexibility.
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

# 2. Reload Nginx to apply changes
echo "Reloading Nginx..."
if systemctl reload nginx; then
    echo "✅ Nginx updated successfully."
    echo "You can now visit: http://os.peoplewelike.club"
else
    echo "❌ Nginx reload failed. Checking logs..."
    systemctl status nginx --no-pager
fi
