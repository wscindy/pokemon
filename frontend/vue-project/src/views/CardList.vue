<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import PokemonCard from '../components/PokemonCard.vue'

const pokemonCards = ref([])
const loading = ref(true)
const error = ref(null)
const selectedCard = ref(null)

const loadCards = async () => {
  try {
    loading.value = true
    
    const cardPaths = [
      '/data_tc/EXp.png/001.json',
      '/data_tc/EXp.png/002.json',
      '/data_tc/EXp.png/003.json'
    ]
    
    const promises = cardPaths.map(async (path) => {
      try {
        const response = await axios.get(path)
        console.log('成功載入:', response.data.name)
        return response.data
      } catch (err) {
        console.error(`載入 ${path} 失敗:`, err.message)
        return null
      }
    })
    
    const results = await Promise.all(promises)
    pokemonCards.value = results.filter(card => card !== null)
    
    if (pokemonCards.value.length === 0) {
      error.value = '沒有成功載入卡片，請檢查檔案路徑'
    }
    
  } catch (err) {
    error.value = '載入卡片時發生錯誤'
    console.error(err)
  } finally {
    loading.value = false
  }
}

const showCardDetail = (card) => {
  selectedCard.value = card
}

const closeCardDetail = () => {
  selectedCard.value = null
}

onMounted(() => {
  loadCards()
})
</script>

<template>
  <div class="battle-arena">
    <!-- 對戰場背景 -->
    <div class="arena-background"></div>
    
    <!-- 卡片網格 -->
    <div class="card-collection">
      <div v-if="loading" class="loading">
        <div class="pokeball-spinner"></div>
        <p>載入中...</p>
      </div>
      
      <div v-else-if="error" class="error">
        <p>{{ error }}</p>
        <button @click="loadCards" class="retry-btn">重新載入</button>
      </div>
      
      <div v-else class="card-grid">
        <PokemonCard
          v-for="(card, index) in pokemonCards"
          :key="card.number || index"
          :image="card.img"
          @click="showCardDetail(card)"
        />
      </div>
    </div>
    
    <!-- Hover 大圖 Modal -->
    <Teleport to="body">
      <div v-if="selectedCard" class="card-modal" @click="closeCardDetail">
        <div class="modal-content" @click.stop>
          <button class="close-btn" @click="closeCardDetail">×</button>
          <img :src="selectedCard.img" :alt="selectedCard.name" class="full-card-image" />
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
/* 寶可夢 TCG 對戰場風格背景 */
.battle-arena {
  min-height: 100vh;
  position: relative;
  overflow: hidden;
}

.arena-background {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: 
    radial-gradient(circle at 30% 50%, rgba(59, 130, 246, 0.15) 0%, transparent 50%),
    radial-gradient(circle at 70% 50%, rgba(239, 68, 68, 0.15) 0%, transparent 50%),
    linear-gradient(180deg, #e8f4f8 0%, #f0f4f8 50%, #e8f4f8 100%);
  z-index: -1;
}

.card-collection {
  padding: 40px 20px;
  max-width: 1400px;
  margin: 0 auto;
}

/* 卡片網格 */
.card-grid {
  display: grid;
  gap: 30px;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  justify-items: center;
  padding: 20px;
}

/* 載入動畫 */
.loading {
  text-align: center;
  padding: 100px 20px;
}

.pokeball-spinner {
  width: 60px;
  height: 60px;
  margin: 0 auto 20px;
  border: 4px solid #e0e0e0;
  border-top: 4px solid #ef5350;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.loading p {
  font-size: 18px;
  color: #546e7a;
  font-weight: 500;
}

.error {
  text-align: center;
  padding: 100px 20px;
}

.error p {
  font-size: 18px;
  color: #e53935;
  margin-bottom: 20px;
}

.retry-btn {
  background: #3b82f6;
  color: white;
  border: none;
  padding: 12px 32px;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.retry-btn:hover {
  background: #2563eb;
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(59, 130, 246, 0.4);
}

/* Modal 大圖 */
.card-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  cursor: pointer;
  animation: fadeIn 0.2s ease;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.modal-content {
  position: relative;
  max-width: 90%;
  max-height: 90vh;
  cursor: default;
  animation: zoomIn 0.3s ease;
}

@keyframes zoomIn {
  from {
    transform: scale(0.8);
    opacity: 0;
  }
  to {
    transform: scale(1);
    opacity: 1;
  }
}

.full-card-image {
  max-width: 100%;
  max-height: 90vh;
  height: auto;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
}

.close-btn {
  position: absolute;
  top: -15px;
  right: -15px;
  width: 40px;
  height: 40px;
  background: white;
  border: none;
  border-radius: 50%;
  font-size: 28px;
  line-height: 1;
  cursor: pointer;
  color: #333;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  transition: all 0.2s;
  z-index: 10000;
}

.close-btn:hover {
  background: #ef5350;
  color: white;
  transform: rotate(90deg);
}

/* 平板版 */
@media (max-width: 1024px) {
  .card-grid {
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 24px;
    padding: 16px;
  }
}

/* 手機版 */
@media (max-width: 640px) {
  .card-collection {
    padding: 20px 12px;
  }
  
  .card-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 16px;
    padding: 12px;
  }
  
  .full-card-image {
    max-width: 95%;
    max-height: 80vh;
  }
  
  .close-btn {
    top: 10px;
    right: 10px;
  }
}

/* 超小手機 */
@media (max-width: 400px) {
  .card-grid {
    grid-template-columns: 1fr;
  }
}
</style>
