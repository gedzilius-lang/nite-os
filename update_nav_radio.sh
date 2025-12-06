#!/bin/bash

FRONT_DIR="/opt/nite-os/frontend"
cd $FRONT_DIR

echo "--- 🧭 UPDATING NAVIGATION BAR ---"

# 1. Overwrite App.vue with the Radio Link included
cat <<EOF > src/App.vue
<script setup lang="ts">
import { useAuthStore } from './stores/auth'
const auth = useAuthStore()
</script>

<template>
  <div class="app-container">
    <nav>
      <router-link to="/">Home</router-link>
      <router-link to="/market">Market</router-link>
      <router-link to="/radio" class="radio-link">Radio 🔴</router-link>
      
      <div v-if="auth.isAuthenticated" class="auth-links">
        <router-link to="/profile">Profile</router-link>
      </div>
      <router-link v-else to="/login">Login</router-link>
    </nav>
    <main>
      <router-view />
    </main>
  </div>
</template>

<style>
body { margin: 0; background: #111; color: #eee; font-family: Inter, sans-serif; }
.app-container { max-width: 800px; margin: 0 auto; text-align: center; }
nav {
  padding: 20px;
  background: #222;
  margin-bottom: 20px;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 15px;
  border-bottom: 2px solid #333;
}
a { color: #888; text-decoration: none; font-weight: bold; transition: color 0.2s; }
a:hover { color: #fff; }
a.router-link-active { color: #42b883; }

/* Special style for the live radio link */
.radio-link { color: #ff4444 !important; }
.radio-link:hover { color: #ff6666 !important; }
.radio-link.router-link-active { color: #ff0000 !important; text-shadow: 0 0 10px rgba(255,0,0,0.5); }

.auth-links { display: flex; gap: 15px; }
</style>
EOF

# 2. Rebuild Frontend
echo "Building Frontend..."
npm run build

echo "✅ Navigation Updated. 'Radio' tab added."
