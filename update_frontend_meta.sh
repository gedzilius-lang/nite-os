#!/bin/bash

FRONT_FILE="/opt/nite-os/frontend/src/views/RadioView.vue"

echo "--- 🎵 PHASE 10: FRONTEND DISPLAY ---"

cat <<EOF > \$FRONT_FILE
<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import axios from 'axios'

const nowPlaying = ref({ artist: 'Loading...', title: '' })
let pollInterval: any = null

async function fetchMeta() {
  try {
    const res = await axios.get('/api/radio/now-playing')
    if (res.data && res.data.title) {
      nowPlaying.value = res.data
    }
  } catch (e) {
    console.error("Meta fetch failed", e)
  }
}

onMounted(() => {
  fetchMeta()
  // Poll every 10 seconds
  pollInterval = setInterval(fetchMeta, 10000)
})

onUnmounted(() => {
  if (pollInterval) clearInterval(pollInterval)
})
</script>

<template>
  <div class="radio-page">
    <div class="header-section">
      <h1>Live Stream</h1>
      <div class="now-playing">
        <span class="pulse">●</span> 
        <span class="artist">{{ nowPlaying.artist }}</span>
        <span class="separator" v-if="nowPlaying.title">-</span>
        <span class="track">{{ nowPlaying.title }}</span>
      </div>
    </div>

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

.header-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
  padding: 0 10px;
}

h1 { margin: 0; color: #42b883; }

.now-playing {
  background: #222;
  padding: 8px 16px;
  border-radius: 20px;
  border: 1px solid #333;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 8px;
}

.pulse { color: #ff4444; animation: blink 2s infinite; }
.artist { font-weight: bold; color: #fff; }
.track { color: #aaa; }

@keyframes blink { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }

.iframe-container {
  flex-grow: 1;
  width: 100%;
  min-height: 600px;
  background: #000;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #333;
}

iframe { width: 100%; height: 100%; border: none; }
.subtext { margin-top: 10px; font-size: 0.9rem; color: #666; }
</style>
EOF

# Rebuild
cd /opt/nite-os/frontend
npm run build
systemctl reload nginx

echo "✅ Frontend updated with Now Playing widget."
