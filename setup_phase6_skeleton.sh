#!/bin/bash

# Define Paths
ROOT_DIR="/opt/nite-os"
FRONT_DIR="$ROOT_DIR/frontend"

echo "--- PHASE 6: Frontend Skeleton & Nginx ---"

# --- 1. Scaffolding Vue 3 ---
echo "Creating Vue 3 app..."
cd $ROOT_DIR
# Remove if exists to ensure clean state
rm -rf frontend

# Create Vite app (Vue, TypeScript)
# We use 'yes' to accept default prompts if any appear
npm create vite@latest frontend -- --template vue-ts
cd frontend

echo "Installing frontend dependencies..."
npm install
npm install vue-router@4 axios pinia

# --- 2. Vite Config (Proxy Setup) ---
echo "Configuring Vite Proxy..."
cat <<EOF > $FRONT_DIR/vite.config.ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:3000',
        changeOrigin: true,
        secure: false,
      }
    }
  }
})
EOF

# --- 3. Main Entry (Router & Pinia) ---
# Create directory structure
mkdir -p $FRONT_DIR/src/router
mkdir -p $FRONT_DIR/src/views
mkdir -p $FRONT_DIR/src/stores

# src/main.ts
cat <<EOF > $FRONT_DIR/src/main.ts
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import './style.css'
import App from './App.vue'

// Basic Views
import HomeView from './views/HomeView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: HomeView },
    { path: '/feed', component: () => import('./views/FeedView.vue') },
    { path: '/market', component: () => import('./views/MarketView.vue') },
    { path: '/profile', component: () => import('./views/ProfileView.vue') },
    { path: '/radio', component: () => import('./views/RadioView.vue') },
  ]
})

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
EOF

# --- 4. Basic App Layout ---
cat <<EOF > $FRONT_DIR/src/App.vue
<script setup lang="ts">
</script>

<template>
  <div class="app-container">
    <nav>
      <router-link to="/">Home</router-link>
      <router-link to="/feed">Feed</router-link>
      <router-link to="/market">Market</router-link>
      <router-link to="/profile">Profile</router-link>
      <router-link to="/radio">Radio</router-link>
    </nav>
    <main>
      <router-view />
    </main>
  </div>
</template>

<style>
body { margin: 0; background: #111; color: #eee; font-family: sans-serif; }
.app-container {
  max-width: 800px;
  margin: 0 auto;
  text-align: center;
}
nav {
  padding: 20px;
  background: #222;
  margin-bottom: 20px;
  display: flex;
  justify-content: center;
  gap: 15px;
}
a { color: #888; text-decoration: none; font-weight: bold; }
a.router-link-active { color: #42b883; }
main { padding: 0 20px; }
</style>
EOF

# Create Placeholder Views
echo "<template><h1>NiteOS V8</h1><p>Welcome to the modular monolith.</p></template>" > $FRONT_DIR/src/views/HomeView.vue
echo "<template><h1>Feed</h1><p>Announcements coming soon.</p></template>" > $FRONT_DIR/src/views/FeedView.vue
echo "<template><h1>Market</h1><p>Buy items with Nitecoin.</p></template>" > $FRONT_DIR/src/views/MarketView.vue
echo "<template><h1>Profile</h1><p>Your NiteTap stats.</p></template>" > $FRONT_DIR/src/views/ProfileView.vue
echo "<template><h1>Radio</h1><p>External Stream Player.</p></template>" > $FRONT_DIR/src/views/RadioView.vue

# --- 5. Nginx Configuration ---
echo "Configuring Nginx..."
cat <<EOF > /etc/nginx/sites-available/nite-os
server {
    listen 80;
    server_name _; # Responds to IP

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

# Enable Site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/nite-os /etc/nginx/sites-enabled/

# --- 6. Build and Deploy ---
echo "Building Frontend..."
cd $FRONT_DIR
npm run build

echo "Reloading Nginx..."
systemctl reload nginx

# --- 7. Update Docs ---
echo "Updating Docs..."
cat << 'DOCEOF' > /opt/nite-os/docs/V8-Roadmap.md
# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)
## Phase 1 – Backend Skeleton (DONE)
## Phase 2 – Core Entities (DONE)
## Phase 3 – Market + POS Logic (DONE)
## Phase 4 – Auth & Roles (DONE)
## Phase 5 – Redis + Mongo (DONE)

## Phase 6 – Frontend SPA (DONE)
- Scaffolding: Vue 3 + Vite + TypeScript.
- Routing: vue-router configured.
- Nginx: Serving static files + proxying /api to backend.
- **Status:** Basic skeleton live on port 80.

---

## Phase 7 – UI Implementation (NEXT)
Goal: Connect UI to API.
- Fetch Market items.
- Login screen.
- Profile data display.
DOCEOF

cat << 'DOCEOF' >> /opt/nite-os/docs/V8-Phase-Log.md

## 2025-12-05 – Phase 6 – Frontend Skeleton
- Scaffolded Vue 3 app in \`/frontend\`.
- Configured Nginx to serve frontend at root and proxy API.
- Implemented basic Router and Placeholder views.
DOCEOF

echo "✅ Phase 6 Complete: Frontend is live."
