#!/bin/bash

ROOT_DIR="/opt/nite-os"
BACK_DIR="$ROOT_DIR/backend"
FRONT_DIR="$ROOT_DIR/frontend"

echo "--- PHASE 7: UI Implementation ---"

# ==========================================
# PART 1: BACKEND UPDATES (Profile Endpoint)
# ==========================================
echo "1. Updating Backend (Auth Profile)..."

# 1. Update AuthService to fetch full profile
cat <<EOF > $BACK_DIR/src/modules/auth/auth.service.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private jwtService: JwtService,
  ) {}

  async validateUser(username: string, pass: string): Promise<any> {
    const user = await this.usersRepository.findOne({ 
        where: { username },
        select: ['id', 'username', 'password', 'role', 'venueId'] 
    });
    
    if (user && user.password && await bcrypt.compare(pass, user.password)) {
      const { password, ...result } = user;
      return result;
    }
    return null;
  }

  async login(user: any) {
    const payload = { 
        username: user.username, 
        sub: user.id, 
        role: user.role,
        venueId: user.venueId
    };
    return {
      access_token: this.jwtService.sign(payload),
      user: payload
    };
  }

  async getProfile(userId: number) {
    return this.usersRepository.findOne({ where: { id: userId } });
  }
}
EOF

# 2. Update AuthController to expose /profile
cat <<EOF > $BACK_DIR/src/modules/auth/auth.controller.ts
import { Controller, Post, Body, Get, UseGuards, Request, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  async login(@Body() loginDto: any) {
    const user = await this.authService.validateUser(loginDto.username, loginDto.password);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return this.authService.login(user);
  }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  getProfile(@Request() req) {
    // req.user is populated by JwtStrategy (has userId)
    return this.authService.getProfile(req.user.userId);
  }
}
EOF

# 3. Rebuild Backend
echo "   Rebuilding Backend..."
cd $BACK_DIR
npm run build
pm2 restart nite-backend

# ==========================================
# PART 2: FRONTEND IMPLEMENTATION
# ==========================================
echo "2. Implementing Frontend Logic..."
cd $FRONT_DIR

# 1. Create Auth Store
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

# 2. Login View
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

# 3. Profile View
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

# 4. Market View
cat <<EOF > src/views/MarketView.vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

const items = ref([] as any[])
const loading = ref(true)

onMounted(async () => {
  try {
    // Hardcoded Venue 1 for Phase 7
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

# 5. App.vue (Navigation & Logout)
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

# 6. Router Setup
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
    // Radio & Feed stubs
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

# 7. Main Entry Update (Use router file)
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

# ==========================================
# PART 3: BUILD & DEPLOY
# ==========================================
echo "3. Building Frontend..."
npm run build
systemctl reload nginx

# ==========================================
# PART 4: DOCS
# ==========================================
cat << 'DOCEOF' > $ROOT_DIR/docs/V8-Roadmap.md
# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)
## Phase 1 – Backend Skeleton (DONE)
## Phase 2 – Core Entities (DONE)
## Phase 3 – Market + POS Logic (DONE)
## Phase 4 – Auth & Roles (DONE)
## Phase 5 – Redis + Mongo (DONE)
## Phase 6 – Frontend Skeleton (DONE)

## Phase 7 – UI Implementation (DONE)
- Implemented \`auth.store.ts\` (Pinia).
- Added \`/api/auth/profile\` to backend.
- Views: Login, Profile, Market.
- Connected Frontend to API (Axios + JWT).

---

## Phase 8 – Hardening & CI (NEXT)
Goal: Production Ready.
- Disable \`synchronize: true\`.
- Security headers.
- Deploy scripts.
DOCEOF

cat << 'DOCEOF' >> $ROOT_DIR/docs/V8-Phase-Log.md

## 2025-12-05 – Phase 7 – UI Implementation
- Backend: Exposed user profile endpoint.
- Frontend: Implemented Pinia Auth Store.
- Frontend: Built Login, Profile, and Market views.
- Wired frontend to backend API using JWT tokens.
DOCEOF

echo "✅ Phase 7 Complete. Frontend Updated."
