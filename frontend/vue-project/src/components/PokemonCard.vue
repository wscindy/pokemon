<script setup>
defineProps({
  image: String
})
</script>

<template>
  <div class="card-holder">
    <div class="card-frame">
      <img :src="image" alt="Pokemon Card" class="card-image" />
    </div>
  </div>
</template>

<style scoped>
.card-holder {
  width: 100%;
  max-width: 250px;
  cursor: pointer;
  transition: transform 0.2s ease;
}

.card-holder:hover {
  transform: translateY(-4px);
}

.card-frame {
  position: relative;
  width: 100%;
  aspect-ratio: 63 / 88;
  background: white;
  border-radius: 12px;
  padding: 8px;
  box-shadow: 
    0 2px 4px rgba(0, 0, 0, 0.1),
    0 4px 12px rgba(0, 0, 0, 0.1),
    inset 0 1px 2px rgba(255, 255, 255, 0.8);
  transition: all 0.3s ease;
}

.card-holder:hover .card-frame {
  box-shadow: 
    0 4px 8px rgba(0, 0, 0, 0.15),
    0 8px 24px rgba(0, 0, 0, 0.2),
    inset 0 1px 2px rgba(255, 255, 255, 0.8);
}

.card-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 8px;
  display: block;
}

/* 手機版 */
@media (max-width: 640px) {
  .card-holder {
    max-width: 100%;
  }
  
  .card-frame {
    padding: 6px;
  }
}
</style>
