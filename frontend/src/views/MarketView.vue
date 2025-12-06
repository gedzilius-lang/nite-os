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
