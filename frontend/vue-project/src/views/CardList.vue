<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import PokemonCard from '../components/PokemonCard.vue'

const pokemonCards = ref([])
const loading = ref(true)
const error = ref(null)
const hoveredCard = ref(null)
const mousePosition = ref({ x: 0, y: 0 })

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

const showCardPreview = (card) => {
  hoveredCard.value = card
}

const hideCardPreview = () => {
  hoveredCard.value = null
}

// 追蹤鼠標位置
const updateMousePosition = (event) => {
  mousePosition.value = {
    x: event.clientX,
    y: event.clientY
  }
}

onMounted(() => {
  loadCards()
  // 監聽全域鼠標移動
  window.addEventListener('mousemove', updateMousePosition)
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
          @mouseenter="showCardPreview(card)"
          @mouseleave="hideCardPreview"
        />
      </div>
    </div>
    
    <!-- Hover 大圖預覽（跟隨鼠標） -->
    <Teleport to="body">
      <Transition name="fade">
        <div 
          v-if="hoveredCard" 
          class="card-preview-floating"
          :style="{
            left: mousePosition.x + 20 + 'px',
            top: mousePosition.y + 20 + 'px'
          }"
        >
          <img :src="hoveredCard.img" :alt="hoveredCard.name" class="preview-image" />
        </div>
      </Transition>
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

/* Hover 大圖預覽（跟隨鼠標） */
.card-preview-floating {
  position: fixed;
  z-index: 9999;
  pointer-events: none;
  /* 讓大圖不會被鼠標擋住 */
}

.preview-image {
  width: 350px;
  height: auto;
  border-radius: 16px;
  box-shadow: 
    0 12px 40px rgba(0, 0, 0, 0.4),
    0 0 0 3px rgba(255, 255, 255, 0.2);
  /* 白色邊框讓卡片更清楚 */
}

/* 淡入淡出動畫 */
.fade-enter-active {
  transition: opacity 0.15s ease;
}

.fade-leave-active {
  transition: opacity 0.1s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* 平板版 */
@media (max-width: 1024px) {
  .card-grid {
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 24px;
    padding: 16px;
  }
  
  .preview-image {
    width: 280px;
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
  
  /* 手機版：大圖顯示在中間而不是跟隨鼠標 */
  .card-preview-floating {
    position: fixed !important;
    left: 50% !important;
    top: 50% !important;
    transform: translate(-50%, -50%);
  }
  
  .preview-image {
    width: 90vw;
    max-width: 350px;
  }
}

/* 超小手機 */
@media (max-width: 400px) {
  .card-grid {
    grid-template-columns: 1fr;
  }
}
</style>
