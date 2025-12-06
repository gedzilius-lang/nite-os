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
