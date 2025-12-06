#!/bin/bash

echo "🚀 NiteOS V8 Deployment Started..."

# 1. Update Code
echo "📥 Pulling latest code..."
git pull origin main

# 2. Backend
echo "⚙️  Building Backend..."
cd /opt/nite-os/backend
npm install --production=false
npm run build
pm2 restart nite-backend

# 3. Frontend
echo "🎨 Building Frontend..."
cd /opt/nite-os/frontend
npm install
npm run build

# 4. Nginx
echo "🌐 Reloading Web Server..."
systemctl reload nginx

echo "✅ Deployment Complete!"
