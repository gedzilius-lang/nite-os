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
