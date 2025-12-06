#!/bin/bash

FRONT_DIR="/opt/nite-os/frontend"

echo "--- 🔧 REPAIRING PHASE 7 (FRONTEND) ---"

# 1. Prepare Directory & Dependencies
echo "1. Checking Directories & Installing Deps..."
if [ ! -d "$FRONT_DIR" ]; then
    echo "❌ Frontend directory missing!"
    exit 1
fi

cd $FRONT_DIR

# Ensure folders exist (Fixes 'No such file or directory' errors)
mkdir -p src/stores
mkdir -p src/views
mkdir -p src/router

# Install dependencies explicitly to fix 'Cannot find module'
npm install pinia axios vue-router@4

# 2. Re-create Frontend Files
echo "2. Re-writing Source Files..."

# --- Store ---
cat <<EOF > src/stores/auth.ts
import { defineStore } from 'pinia'
import axios from 'axios'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('token') || '',
    user: null as any,
  }),
  getters: {
    isAuthenticated: (state) => !!state.token,
  },
  actions: {
    async login(username: string, password: string) {
      try {
        const res = await axios.post('/api/auth/login', { username, password })
        this.token = res.data.access_token
        localStorage.setItem('token', this.token)
        axios.defaults.headers.common['Authorization'] = \`Bearer \${this.token}\`
        await this.fetchProfile()
        return true
      } catch (e) {
        console.error(e)
        return false
      }
    },
    async fetchProfile() {
      if (!this.token) return
      axios.defaults.headers.common['Authorization'] = \`Bearer \${this.token}\`
      try {
        const res = await axios.get('/api/auth/profile')
        this.user = res.data
      } catch (e) {
        this.logout()
      }
    },
    logout() {
      this.token = ''
      this.user = null
      localStorage.removeItem('token')
      delete axios.defaults.headers.common['Authorization']
    }
  }
})
EOF

# --- Views ---
cat <<EOF > src/views/LoginView.vue
<script setup lang="ts">
import { ref } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'

const username = ref('')
const password = ref('')
const auth = useAuthStore()
const router = useRouter()
const error = ref('')

async function handleLogin() {
  const success = await auth.login(username.value, password.value)
  if (success) {
    router.push('/profile')
  } else {
    error.value = 'Invalid credentials'
  }
}
</script>

<template>
  <div class="login-card">
    <h2>Login</h2>
    <form @submit.prevent="handleLogin">
      <input v-model="username" placeholder="Username" required />
      <input v-model="password" type="password" placeholder="Password" required />
      <button type="submit">Enter Nightlife</button>
    </form>
    <p v-if="error" class="error">{{ error }}</p>
    <p class="hint">Try: admin / admin123</p>
  </div>
</template>

<style scoped>
.login-card {
  background: #222;
  padding: 2rem;
  border-radius: 8px;
  max-width: 300px;
  margin: 2rem auto;
}
input {
  display: block;
  width: 90%;
  margin: 10px auto;
  padding: 8px;
  background: #333;
  border: 1px solid #444;
  color: #fff;
  border-radius: 4px;
}
button {
  background: #42b883;
  color: #000;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
  width: 100%;
}
.error { color: #ff4444; margin-top: 10px; }
.hint { color: #666; font-size: 0.8rem; margin-top: 10px; }
</style>
EOF

cat <<EOF > src/views/ProfileView.vue
<script setup lang="ts">
import { onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()

onMounted(() => {
  auth.fetchProfile()
})
</script>

<template>
  <div v-if="auth.user" class="profile-card">
    <h1>{{ auth.user.username || 'User' }}</h1>
    <div class="stats">
      <div class="stat">
        <span class="label">Balance</span>
        <span class="value">{{ auth.user.niteBalance }} 🪙</span>
      </div>
      <div class="stat">
        <span class="label">Level</span>
        <span class="value">{{ auth.user.level }}</span>
      </div>
      <div class="stat">
        <span class="label">XP</span>
        <span class="value">{{ auth.user.xp }}</span>
      </div>
    </div>
    <div class="meta">
      <p>NiteTap ID: {{ auth.user.nitetapId || 'Not Linked' }}</p>
      <p>Role: {{ auth.user.role }}</p>
    </div>
    <button @click="auth.logout()" class="logout-btn">Logout</button>
  </div>
  <div v-else>Loading profile...</div>
</template>

<style scoped>
.profile-card {
  background: #222;
  padding: 2rem;
  border-radius: 12px;
  margin-top: 20px;
}
.stats {
  display: flex;
  justify-content: space-around;
  margin: 20px 0;
  background: #333;
  padding: 15px;
  border-radius: 8px;
}
.stat { display: flex; flex-direction: column; }
.label { font-size: 0.8rem; color: #aaa; }
.value { font-size: 1.5rem; font-weight: bold; color: #42b883; }
.logout-btn {
  background: #d32f2f;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  margin-top: 1rem;
}
</style>
EOF

cat <<EOF > src/views/MarketView.vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

const items = ref([] as any[])
const loading = ref(true)

onMounted(async () => {
  try {
    const res = await axios.get('/api/market/1/items')
    items.value = res.data
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div>
    <h1>Club Market</h1>
    <div v-if="loading">Loading items...</div>
    <div v-else class="items-grid">
      <div v-for="item in items" :key="item.id" class="item-card">
        <h3>{{ item.title }}</h3>
        <div class="prices">
          <span class="price-chf">{{ item.priceChf }} CHF</span>
          <span class="price-nite">{{ item.priceNite }} 🪙</span>
        </div>
      </div>
    </div>
    <p v-if="items.length === 0 && !loading">No items available.</p>
  </div>
</template>

<style scoped>
.items-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 20px;
  margin-top: 20px;
}
.item-card {
  background: #222;
  padding: 15px;
  border-radius: 8px;
  border: 1px solid #333;
}
.prices {
  display: flex;
  justify-content: space-between;
  margin-top: 10px;
  font-weight: bold;
}
.price-nite { color: #42b883; }
</style>
EOF

# --- Router ---
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

router.beforeEach((to, from, next) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    next('/login')
  } else {
    next()
  }
})

export default router
EOF

# --- Main & App ---
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
}
a { color: #888; text-decoration: none; font-weight: bold; }
a.router-link-active { color: #42b883; }
.auth-links { display: flex; gap: 15px; }
</style>
EOF

cat <<EOF > src/main.ts
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'
import router from './router'
import axios from 'axios'

// Restore token on load
const token = localStorage.getItem('token')
if (token) {
  axios.defaults.headers.common['Authorization'] = \`Bearer \${token}\`
}

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
EOF

# 3. Build & Deploy
echo "3. Building Frontend..."
npm run build

echo "4. Reloading Nginx..."
systemctl reload nginx

echo "✅ Phase 7 Repair Complete. Try accessing http://$(curl -s ifconfig.me)"
