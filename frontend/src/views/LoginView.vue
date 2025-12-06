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
