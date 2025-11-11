<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { cardAPI, deckAPI } from '@/services/api'

const router = useRouter()

// 搜尋相關
const searchKeyword = ref('')
const searchResults = ref([])
const isSearching = ref(false)

// 牌組相關
const deckCards = ref([])
const isSaving = ref(false)
const saveMessage = ref('')

// 預覽功能
const previewCard = ref(null)
const previewPosition = ref({ x: 0, y: 0 })
const showPreview = ref(false)

// 計算總卡片數
const totalCards = computed(() => {
  return deckCards.value.reduce((sum, card) => sum + card.quantity, 0)
})

// 是否可以送出（必須是 60 張）
const canSubmit = computed(() => {
  return totalCards.value === 60
})

// 顯示預覽大圖
const handleMouseEnter = (card, event) => {
  previewCard.value = card
  showPreview.value = true
  updatePreviewPosition(event)
}

// 隱藏預覽大圖
const handleMouseLeave = () => {
  showPreview.value = false
  previewCard.value = null
}

// 更新預覽位置
const updatePreviewPosition = (event) => {
  const offset = 20
  previewPosition.value = {
    x: event.clientX + offset,
    y: event.clientY + offset
  }
}

// 滑鼠移動時更新位置
const handleMouseMove = (event) => {
  if (showPreview.value) {
    updatePreviewPosition(event)
  }
}

// 搜尋卡片
const handleSearch = async () => {
  if (!searchKeyword.value.trim()) {
    alert('請輸入搜尋關鍵字')
    return
  }
  
  isSearching.value = true
  
  try {
    const response = await cardAPI.search(searchKeyword.value)
    
    if (response.data.success) {
      searchResults.value = response.data.cards
    } else {
      alert('搜尋失敗')
    }
  } catch (error) {
    console.error('搜尋錯誤：', error)
    alert('搜尋時發生錯誤')
  } finally {
    isSearching.value = false
  }
}

// 加入卡片到牌組
const addCardToDeck = (card) => {
  const quantity = prompt(`請輸入要加入的 ${card.name} 數量（1-60）：`, '1')
  
  if (quantity === null) return
  
  const quantityNum = parseInt(quantity)
  
  if (isNaN(quantityNum) || quantityNum <= 0) {
    alert('請輸入有效的數量')
    return
  }
  
  const existingCard = deckCards.value.find(
    c => c.card_unique_id === card.card_unique_id
  )
  
  if (existingCard) {
    existingCard.quantity = quantityNum
  } else {
    deckCards.value.push({
      card_unique_id: card.card_unique_id,
      name: card.name,
      img_url: card.img_url,
      card_type: card.card_type,
      hp: card.hp,
      stage: card.stage,
      quantity: quantityNum
    })
  }
  
  saveMessage.value = `已加入 ${quantityNum} 張 ${card.name}`
  setTimeout(() => {
    saveMessage.value = ''
  }, 2000)
}

// 從牌組移除卡片
const removeCardFromDeck = (cardUniqueId) => {
  deckCards.value = deckCards.value.filter(
    card => card.card_unique_id !== cardUniqueId
  )
}

// 更新卡片數量
const updateCardQuantity = (cardUniqueId, newQuantity) => {
  const card = deckCards.value.find(c => c.card_unique_id === cardUniqueId)
  if (card) {
    card.quantity = parseInt(newQuantity)
  }
}

// 儲存牌組
const saveDeck = async () => {
  if (!canSubmit.value) {
    alert(`牌組必須有 60 張卡片（目前：${totalCards.value} 張）`)
    return
  }
  
  isSaving.value = true
  
  try {
    const cardsData = deckCards.value.map(card => ({
      card_unique_id: card.card_unique_id,
      quantity: card.quantity
    }))
    
    const response = await deckAPI.saveDeck(cardsData)
    
    if (response.data.success) {
      alert('牌組儲存成功！')
      router.push({ name: 'GameLobby' })
    } else {
      alert('儲存失敗：' + response.data.error)
    }
  } catch (error) {
    console.error('儲存錯誤：', error)
    alert('儲存時發生錯誤：' + (error.response?.data?.error || error.message))
  } finally {
    isSaving.value = false
  }
}

// 返回大廳
const handleBack = () => {
  if (deckCards.value.length > 0) {
    if (!confirm('確定要離開？未儲存的變更將會遺失。')) {
      return
    }
  }
  router.push({ name: 'GameLobby' })
}
</script>

<template>
  <div class="deck-builder">
    <!-- 頂部導航 -->
    <header class="builder-header">
      <button class="back-btn" @click="handleBack">
        ← 返回大廳
      </button>
      <h1 class="header-title">牌組編輯器</h1>
      <div class="deck-info">
        <span class="card-count" :class="{ 'complete': canSubmit }">
          {{ totalCards }} / 60 張
        </span>
      </div>
    </header>

    <div class="builder-content">
      <!-- 左側：搜尋區域 -->
      <div class="search-section">
        <div class="search-box">
          <input
            v-model="searchKeyword"
            type="text"
            placeholder="搜尋卡片名稱（例如：皮卡丘）"
            class="search-input"
            @keyup.enter="handleSearch"
          />
          <button 
            class="search-btn" 
            @click="handleSearch"
            :disabled="isSearching"
          >
            {{ isSearching ? '搜尋中...' : '搜尋' }}
          </button>
        </div>

        <!-- 搜尋結果 -->
        <div class="search-results">
          <div v-if="searchResults.length === 0 && !isSearching" class="empty-state">
            輸入卡片名稱開始搜尋
          </div>
          
          <div v-if="isSearching" class="loading-state">
            搜尋中...
          </div>

          <div 
            v-for="card in searchResults" 
            :key="card.card_unique_id" 
            class="card-item"
            @mouseenter="(e) => handleMouseEnter(card, e)"
            @mouseleave="handleMouseLeave"
            @mousemove="handleMouseMove"
          >
            <img 
              :src="card.img_url" 
              :alt="card.name"
              class="card-image"
              @error="(e) => e.target.src = 'https://via.placeholder.com/150?text=No+Image'"
            />
            <div class="card-info">
              <h3 class="card-name">{{ card.name }}</h3>
              <p class="card-meta">{{ card.card_type }} | HP: {{ card.hp || 'N/A' }}</p>
            </div>
            <button class="add-btn" @click="addCardToDeck(card)">
              加入
            </button>
          </div>
        </div>
      </div>

      <!-- 右側：目前牌組 -->
      <div class="deck-section">
        <h2 class="section-title">目前牌組</h2>
        
        <div v-if="saveMessage" class="save-message">
          {{ saveMessage }}
        </div>

        <div v-if="deckCards.length === 0" class="empty-deck">
          目前牌組是空的，開始加入卡片吧！
        </div>

        <div v-else class="deck-list">
          <div 
            v-for="card in deckCards" 
            :key="card.card_unique_id" 
            class="deck-card"
            @mouseenter="(e) => handleMouseEnter(card, e)"
            @mouseleave="handleMouseLeave"
            @mousemove="handleMouseMove"
          >
            <img 
              :src="card.img_url" 
              :alt="card.name"
              class="deck-card-image"
            />
            <div class="deck-card-info">
              <h4 class="deck-card-name">{{ card.name }}</h4>
              <p class="deck-card-meta">{{ card.card_type }}</p>
            </div>
            <div class="deck-card-actions">
              <input 
                type="number" 
                :value="card.quantity"
                @change="(e) => updateCardQuantity(card.card_unique_id, e.target.value)"
                min="1"
                max="60"
                class="quantity-input"
              />
              <button 
                class="remove-btn" 
                @click="removeCardFromDeck(card.card_unique_id)"
              >
                ✕
              </button>
            </div>
          </div>
        </div>

        <!-- 儲存按鈕 -->
        <button 
          class="save-btn" 
          @click="saveDeck"
          :disabled="!canSubmit || isSaving"
          :class="{ 'disabled': !canSubmit }"
        >
          {{ isSaving ? '儲存中...' : canSubmit ? '儲存牌組' : `還需要 ${60 - totalCards} 張卡片` }}
        </button>
      </div>
    </div>

    <!-- 預覽大圖 -->
    <Transition name="fade">
      <div 
        v-if="showPreview && previewCard"
        class="card-preview"
        :style="{
          left: previewPosition.x + 'px',
          top: previewPosition.y + 'px'
        }"
      >
        <img 
          :src="previewCard.img_url" 
          :alt="previewCard.name"
          class="preview-image"
        />
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.deck-builder {
  min-height: 100vh;
  background: #f7fafc;
}

/* 頂部導航 */
.builder-header {
  background: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: 16px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: sticky;
  top: 0;
  z-index: 100;
}

.back-btn {
  padding: 10px 20px;
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #718096;
  cursor: pointer;
  transition: all 0.3s;
}

.back-btn:hover {
  background: #f7fafc;
  border-color: #cbd5e0;
}

.header-title {
  font-size: 24px;
  font-weight: 700;
  color: #2d3748;
}

.deck-info {
  display: flex;
  align-items: center;
  gap: 16px;
}

.card-count {
  font-size: 18px;
  font-weight: 700;
  color: #e53e3e;
  padding: 8px 16px;
  background: #fed7d7;
  border-radius: 8px;
}

.card-count.complete {
  color: #38a169;
  background: #c6f6d5;
}

/* 主要內容 */
.builder-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  padding: 24px;
  max-width: 1600px;
  margin: 0 auto;
}

/* 搜尋區域 */
.search-section {
  background: white;
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.search-box {
  display: flex;
  gap: 12px;
  margin-bottom: 24px;
}

.search-input {
  flex: 1;
  padding: 12px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 16px;
  transition: all 0.3s;
}

.search-input:focus {
  outline: none;
  border-color: #667eea;
}

.search-btn {
  padding: 12px 24px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.search-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.search-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* 搜尋結果 */
.search-results {
  max-height: calc(100vh - 250px);
  overflow-y: auto;
}

.empty-state, .loading-state {
  text-align: center;
  color: #a0aec0;
  padding: 40px 20px;
  font-size: 16px;
}

.card-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  margin-bottom: 12px;
  transition: all 0.3s;
  cursor: pointer;
}

.card-item:hover {
  border-color: #667eea;
  background: #f7fafc;
}

.card-image {
  width: 60px;
  height: 84px;
  object-fit: cover;
  border-radius: 8px;
  transition: transform 0.3s ease;
}

.card-item:hover .card-image {
  transform: scale(1.05);
}

.card-info {
  flex: 1;
}

.card-name {
  font-size: 16px;
  font-weight: 600;
  color: #2d3748;
  margin-bottom: 4px;
}

.card-meta {
  font-size: 14px;
  color: #718096;
}

.add-btn {
  padding: 8px 16px;
  background: #667eea;
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.add-btn:hover {
  background: #5568d3;
}

/* 牌組區域 */
.deck-section {
  background: white;
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  display: flex;
  flex-direction: column;
}

.section-title {
  font-size: 20px;
  font-weight: 700;
  color: #2d3748;
  margin-bottom: 16px;
}

.save-message {
  padding: 12px;
  background: #c6f6d5;
  color: #22543d;
  border-radius: 8px;
  margin-bottom: 16px;
  text-align: center;
}

.empty-deck {
  text-align: center;
  color: #a0aec0;
  padding: 40px 20px;
  flex: 1;
}

.deck-list {
  flex: 1;
  max-height: calc(100vh - 350px);
  overflow-y: auto;
  margin-bottom: 16px;
}

.deck-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  margin-bottom: 12px;
  cursor: pointer;
  transition: all 0.3s;
}

.deck-card:hover {
  border-color: #667eea;
  background: #f7fafc;
}

.deck-card-image {
  width: 50px;
  height: 70px;
  object-fit: cover;
  border-radius: 6px;
  transition: transform 0.3s ease;
}

.deck-card:hover .deck-card-image {
  transform: scale(1.05);
}

.deck-card-info {
  flex: 1;
}

.deck-card-name {
  font-size: 14px;
  font-weight: 600;
  color: #2d3748;
  margin-bottom: 4px;
}

.deck-card-meta {
  font-size: 12px;
  color: #718096;
}

.deck-card-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.quantity-input {
  width: 60px;
  padding: 6px;
  border: 2px solid #e2e8f0;
  border-radius: 6px;
  text-align: center;
  font-size: 14px;
}

.remove-btn {
  width: 32px;
  height: 32px;
  background: #fc8181;
  border: none;
  border-radius: 6px;
  color: white;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.3s;
}

.remove-btn:hover {
  background: #f56565;
}

.save-btn {
  width: 100%;
  padding: 16px;
  background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 18px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s;
}

.save-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(72, 187, 120, 0.4);
}

.save-btn:disabled {
  background: #cbd5e0;
  cursor: not-allowed;
  transform: none;
}

/* 預覽大圖 */
.card-preview {
  position: fixed;
  z-index: 9999;
  pointer-events: none;
  filter: drop-shadow(0 8px 16px rgba(0, 0, 0, 0.3));
}

.preview-image {
  width: 250px;
  height: auto;
  border-radius: 12px;
  border: 3px solid white;
}

/* 淡入淡出動畫 */
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
}

/* 響應式設計 */
@media (max-width: 1024px) {
  .builder-content {
    grid-template-columns: 1fr;
  }
  
  .preview-image {
    width: 200px;
  }
}

@media (max-width: 768px) {
  .header-title {
    font-size: 18px;
  }
  
  .card-count {
    font-size: 14px;
    padding: 6px 12px;
  }
  
  .preview-image {
    width: 180px;
  }
}
</style>
