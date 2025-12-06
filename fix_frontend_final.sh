#!/bin/bash

FRONT_DIR="/opt/nite-os/frontend"
cd $FRONT_DIR

echo "--- 🔧 FINAL FRONTEND FIX ---"

# 1. Create TypeScript Definitions for Vue
# (Fixes "Cannot find module ... .vue")
cat <<EOF > src/vite-env.d.ts
/// <reference types="vite/client" />

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}
EOF

# 2. Restore HomeView.vue
# (Fixes import error in router)
cat <<EOF > src/views/HomeView.vue
<script setup lang="ts">
</script>

<template>
  <div class="home">
    <h1>Welcome to NiteOS V8</h1>
    <p>The Modular Monolith for Nightlife.</p>
    <div class="actions">
      <router-link to="/login" class="btn">Login</router-link>
      <router-link to="/market" class="btn">View Market</router-link>
    </div>
  </div>
</template>

<style scoped>
.home { margin-top: 50px; }
h1 { font-size: 3rem; color: #42b883; margin-bottom: 10px; }
p { font-size: 1.2rem; color: #888; margin-bottom: 30px; }
.actions { display: flex; justify-content: center; gap: 20px; }
.btn {
  background: #333;
  padding: 10px 20px;
  border-radius: 5px;
  color: white;
  text-decoration: none;
  font-weight: bold;
  border: 1px solid #444;
}
.btn:hover { background: #444; }
</style>
EOF

# 3. Fix Router (Remove unused variable)
# (Fixes " 'from' is declared but its value is never read")
cat <<EOF > src/router/index.ts
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import HomeView from '../views/HomeView.vue'
import LoginView from '../views/LoginView.vue'
import ProfileView from '../views/ProfileView.vue'
import MarketView from '../views/MarketView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: HomeView },
    { path: '/login', component: LoginView },
    { path: '/market', component: MarketView },
    { 
      path: '/profile', 
      component: ProfileView,
      meta: { requiresAuth: true }
    },
    { path: '/radio', component: { template: '<h1>Radio</h1><p>Stream URL Player</p>' } },
    { path: '/feed', component: { template: '<h1>Feed</h1><p>Coming Soon</p>' } }
  ]
})

// Removed 'from' parameter to fix lint error
router.beforeEach((to, _from, next) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    next('/login')
  } else {
    next()
  }
})

export default router
EOF

# 4. Rebuild
echo "Building Frontend..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build SUCCESS!"
    systemctl reload nginx
    echo "Access your site at: http://$(curl -s ifconfig.me)"
else
    echo "❌ Build FAILED. See errors above."
    exit 1
fi
