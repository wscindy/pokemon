<script setup>
import { ref } from 'vue'
import PokemonCard from '../components/PokemonCard.vue'

const pokemonCards = ref([
  {
    id: 1,
    name: 'Pikachu',
    hp: 60,
    type: 'Electric',
    image: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png',
    attacks: [
      { name: 'Thunder Shock', damage: '10' },
      { name: 'Thunderbolt', damage: '30' }
    ]
  },
  {
    id: 2,
    name: 'Charizard',
    hp: 120,
    type: 'Fire',
    image: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png',
    attacks: [
      { name: 'Flamethrower', damage: '50' },
      { name: 'Fire Blast', damage: '80' }
    ]
  },
  {
    id: 3,
    name: 'Blastoise',
    hp: 100,
    type: 'Water',
    image: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/9.png',
    attacks: [
      { name: 'Water Gun', damage: '30' },
      { name: 'Hydro Pump', damage: '60' }
    ]
  }
])
</script>

<template>
  <div class="card-list-container">
    <h1>Pokemon Card Collection</h1>
    <div class="card-grid">
      <PokemonCard
        v-for="card in pokemonCards"
        :key="card.id"
        :name="card.name"
        :hp="card.hp"
        :type="card.type"
        :image="card.image"
        :attacks="card.attacks"
      />
    </div>
  </div>
</template>

<style scoped>
.card-list-container {
  padding: 40px 20px;
  max-width: 1200px;
  margin: 0 auto;
}

h1 {
  text-align: center;
  color: #333;
  margin-bottom: 40px;
  font-size: 36px;
}

.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 30px;
  justify-items: center;
}
</style>
