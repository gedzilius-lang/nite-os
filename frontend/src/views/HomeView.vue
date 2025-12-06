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
