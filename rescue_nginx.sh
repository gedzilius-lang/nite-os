#!/bin/bash
echo "--- 🚑 NGINX EMERGENCY RESCUE ---"

# Stop Nginx
systemctl stop nginx
pkill -9 nginx 2>/dev/null

# Remove all configs to clear conflicts
rm -f /etc/nginx/sites-enabled/*
rm -f /etc/nginx/sites-available/nite-os
rm -f /etc/nginx/sites-available/nite-os_final

# Write a single, correct config
cat <<EOF > /etc/nginx/sites-available/nite-os
server {
    listen 80 default_server;
    server_name os.peoplewelike.club 31.97.126.86 _;

    root /opt/nite-os/frontend/dist;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

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

# Enable and Start
ln -s /etc/nginx/sites-available/nite-os /etc/nginx/sites-enabled/nite-os
chown -R www-data:www-data /opt/nite-os/frontend/dist
chmod -R 755 /opt/nite-os/frontend/dist

nginx -t
if [ $? -eq 0 ]; then
    systemctl start nginx
    echo "✅ Nginx started successfully. Site should be live."
else
    echo "❌ Nginx Config Error:"
    nginx -t
fi
