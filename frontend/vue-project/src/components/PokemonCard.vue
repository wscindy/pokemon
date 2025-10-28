<script setup>
defineProps({
  name: String,
  hp: Number,
  image: String,
  type: String,
  attacks: Array
})
</script>

<template>
  <div class="pokemon-card">
    <div class="card-header">
      <h3>{{ name }}</h3>
      <span class="hp">HP {{ hp }}</span>
    </div>
    <div class="card-image">
      <img :src="image" :alt="name" />
    </div>
    <div class="card-type">
      <span class="type-badge">{{ type }}</span>
    </div>
    <div class="card-attacks">
      <div v-for="(attack, index) in attacks" :key="index" class="attack">
        <span class="attack-name">{{ attack.name }}</span>
        <span class="attack-damage">{{ attack.damage }}</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.pokemon-card {
  width: 250px;
  border: 2px solid #ddd;
  border-radius: 12px;
  padding: 16px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s;
  cursor: pointer;
}

.pokemon-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 12px rgba(0, 0, 0, 0.2);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.card-header h3 {
  margin: 0;
  color: white;
  font-size: 20px;
}

.hp {
  color: #ffd700;
  font-weight: bold;
  font-size: 16px;
}

.card-image {
  background: white;
  border-radius: 8px;
  padding: 12px;
  text-align: center;
  margin-bottom: 12px;
}

.card-image img {
  width: 100%;
  height: auto;
  max-height: 180px;
  object-fit: contain;
}

.card-type {
  margin-bottom: 12px;
}

.type-badge {
  background: rgba(255, 255, 255, 0.3);
  color: white;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 14px;
  font-weight: bold;
}

.card-attacks {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  padding: 8px;
}

.attack {
  display: flex;
  justify-content: space-between;
  padding: 6px;
  color: white;
}

.attack-name {
  font-weight: 500;
}

.attack-damage {
  font-weight: bold;
  color: #ffd700;
}
</style>
