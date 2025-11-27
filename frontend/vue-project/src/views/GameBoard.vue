<script setup>
import { ref, onMounted,computed } from 'vue'
import { useRoute } from 'vue-router'
import { gameAPI } from '@/services/api'



const route = useRoute()
const gameStateId = ref(route.params.id)
const gameState = ref(null)
const loading = ref(true)
const error = ref(null)

// 排序後的手牌
const sortedHandCards = computed(() => {
  if (!gameState.value?.hand) return []
  
  // 按照 card_unique_id 排序
  return [...gameState.value.hand].sort((a, b) => {
    return a.card_unique_id.localeCompare(b.card_unique_id)
  })
})

// 載入遊戲狀態
const loadGameState = async () => {
  try {
    console.log('正在載入遊戲狀態...', gameStateId.value)
    const response = await gameAPI.getGameState(gameStateId.value)
    console.log('遊戲狀態:', response.data)
    gameState.value = response.data
  } catch (err) {
    console.error('載入遊戲狀態失敗:', err)
    error.value = err.message
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadGameState()
})
</script>

<template>
  <div class="game-board">
    <div v-if="loading" class="loading">
      載入遊戲中...
    </div>
    
    <div v-else-if="gameState" class="game-container">
      <!-- 遊戲資訊 -->
      <header class="game-header">
        <div class="game-info">
          <h2>遊戲 #{{ gameStateId }}</h2>
          <p>回合: {{ gameState.round_number }}</p>
        </div>
        <div class="stats">
          <div class="stat-item">
            <span class="stat-label">牌庫</span>
            <span class="stat-value">{{ gameState.deck_count }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">獎賞卡</span>
            <span class="stat-value">{{ gameState.prize_count }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">棄牌堆</span>
            <span class="stat-value">{{ gameState.discard_count }}</span>
          </div>
        </div>
      </header>

      <!-- 對手區域 -->
      <section class="opponent-area">
        <h3>對手</h3>
        <div class="pokemon-slots">
          <div class="active-slot">
            <p>主戰區</p>
            <!-- 之後顯示對手的主戰寶可夢 -->
          </div>
          <div class="bench-slots">
            <div class="bench-slot" v-for="i in 5" :key="i">
              <p>備戰 {{ i }}</p>
            </div>
          </div>
        </div>
      </section>

      <!-- 玩家區域 -->
      <section class="player-area">
        <h3>你的場地</h3>
        
        <!-- 主戰區 -->
        <div class="active-zone">
          <h4>主戰區</h4>
          <div v-if="gameState.active_pokemon" class="pokemon-card">
            <img :src="gameState.active_pokemon.img_url" :alt="gameState.active_pokemon.name">
            <p>{{ gameState.active_pokemon.name }}</p>
            <p>HP: {{ gameState.active_pokemon.hp - gameState.active_pokemon.damage_taken }}/{{ gameState.active_pokemon.hp }}</p>
          </div>
          <div v-else class="empty-slot">
            無主戰寶可夢
          </div>
        </div>

        <!-- 備戰區 -->
        <div class="bench-zone">
          <h4>備戰區</h4>
          <div class="bench-grid">
            <div 
              v-for="(pokemon, index) in gameState.bench" 
              :key="pokemon.id"
              class="pokemon-card small"
            >
              <img :src="pokemon.img_url" :alt="pokemon.name">
              <p>{{ pokemon.name }}</p>
            </div>
            <!-- 空位 -->
            <div 
              v-for="i in (5 - gameState.bench.length)" 
              :key="'empty-' + i"
              class="empty-slot small"
            >
              空位
            </div>
          </div>
        </div>

        <!-- 手牌 -->
        <div class="hand-zone">
          <h4>手牌 ({{ sortedHandCards.length }})</h4>
          <div class="hand-cards">
            <div 
              v-for="card in sortedHandCards" 
              :key="card.id"
              class="hand-card"
            >
              <img :src="card.img_url" :alt="card.name">
              <div class="card-info">
                <p class="card-name">{{ card.name }}</p>
                <p class="card-type">{{ card.card_type }}</p>
                <p v-if="card.hp" class="card-hp">HP: {{ card.hp }}</p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.game-board {
  min-height: 100vh;
  background: linear-gradient(180deg, #1a365d 0%, #2d3748 100%);
  color: white;
  padding: 20px;
}

.loading {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  font-size: 24px;
}

.game-container {
  max-width: 1400px;
  margin: 0 auto;
}

.game-header {
  background: rgba(255, 255, 255, 0.1);
  padding: 20px;
  border-radius: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
}

.stats {
  display: flex;
  gap: 30px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.stat-label {
  font-size: 14px;
  opacity: 0.8;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #fbbf24;
}

.opponent-area,
.player-area {
  background: rgba(255, 255, 255, 0.05);
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 20px;
}

.active-zone,
.bench-zone,
.hand-zone {
  margin: 20px 0;
}

h4 {
  margin-bottom: 15px;
  font-size: 18px;
  color: #fbbf24;
}

.pokemon-card {
  background: white;
  color: black;
  padding: 15px;
  border-radius: 12px;
  max-width: 200px;
}

.pokemon-card img {
  width: 100%;
  border-radius: 8px;
  margin-bottom: 10px;
}

.pokemon-card.small {
  max-width: 120px;
  padding: 10px;
}

.bench-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 15px;
}

.empty-slot {
  border: 2px dashed rgba(255, 255, 255, 0.3);
  border-radius: 12px;
  padding: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100px;
  opacity: 0.5;
}

.hand-cards {
  display: flex;
  gap: 15px;
  overflow-x: auto;
  padding: 10px 0;
}

.hand-card {
  background: white;
  color: black;
  padding: 12px;
  border-radius: 10px;
  min-width: 150px;
  cursor: pointer;
  transition: transform 0.2s;
  width: 200px;              /* 固定寬度 */
  flex-shrink: 0;            /* 防止縮小 */
}

.hand-card:hover {
  transform: translateY(-10px);
}

.hand-card img {
  width: 100%;
  border-radius: 8px;
  margin-bottom: 8px;
}

.card-info {
  font-size: 12px;
}

.card-name {
  font-weight: bold;
  margin-bottom: 4px;
}

.card-type {
  color: #666;
  margin-bottom: 4px;
}

.card-hp {
  color: #e53e3e;
  font-weight: bold;
}
</style>
