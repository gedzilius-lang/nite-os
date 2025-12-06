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
