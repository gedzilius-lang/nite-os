#!/bin/bash

FRONT_DIR="/opt/nite-os/frontend"
cd $FRONT_DIR

echo "--- 📻 UPDATING RADIO FRONTEND (IFRAME MODE) ---"

# 1. Create the Radio View Component
echo "1. Creating src/views/RadioView.vue..."
cat <<EOF > src/views/RadioView.vue
<script setup lang="ts">
</script>

<template>
  <div class="radio-page">
    <h1>Live Stream</h1>
    <div class="iframe-container">
      <iframe 
        src="https://radio.peoplewelike.club" 
        title="Nite Radio"
        allow="autoplay; encrypted-media; picture-in-picture" 
        allowfullscreen
      ></iframe>
    </div>
    <p class="subtext">
      Broadcasting from 
      <a href="https://radio.peoplewelike.club" target="_blank">radio.peoplewelike.club</a>
    </p>
  </div>
</template>

<style scoped>
.radio-page {
  display: flex;
  flex-direction: column;
  height: 100%;
  padding-bottom: 20px;
}

h1 {
  margin-bottom: 15px;
  color: #42b883;
}

.iframe-container {
  flex-grow: 1;
  width: 100%;
  min-height: 600px; /* Tall enough for video + chat */
  background: #000;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #333;
}

iframe {
  width: 100%;
  height: 100%;
  border: none;
}

.subtext {
  margin-top: 10px;
  font-size: 0.9rem;
  color: #666;
}
</style>
EOF

# 2. Update Router to use the new View
echo "2. Updating Router Configuration..."
cat <<EOF > src/router/index.ts
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import HomeView from '../views/HomeView.vue'
import LoginView from '../views/LoginView.vue'
import ProfileView from '../views/ProfileView.vue'
import MarketView from '../views/MarketView.vue'
import RadioView from '../views/RadioView.vue'

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
    { path: '/radio', component: RadioView },
    { path: '/feed', component: { template: '<h1>Feed</h1><p>Coming Soon</p>' } }
  ]
})

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

# 3. Rebuild
echo "3. Rebuilding Frontend..."
npm run build

echo "4. Reloading Nginx..."
systemctl reload nginx

echo "✅ Radio Tab Updated."
echo "👉 Check it at: https://os.peoplewelike.club/radio"
