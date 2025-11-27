<script setup>
import { ref } from 'vue'
import { gameAPI } from '@/services/api'

const loading = ref(false)
const result = ref(null)
const error = ref(null)
const gameStateId = ref(null)

// 測試初始化遊戲
const testInitGame = async () => {
  loading.value = true
  error.value = null
  result.value = null
  
  try {
    const response = await gameAPI.initializeGame()
    result.value = response.data
    gameStateId.value = response.data.game_state_id
    console.log('初始化成功:', response.data)
  } catch (err) {
    error.value = err.response?.data || err.message
    console.error('初始化失敗:', err)
  } finally {
    loading.value = false
  }
}

// 測試發牌
const testSetupGame = async () => {
  if (!gameStateId.value) {
    alert('請先初始化遊戲')
    return
  }
  
  loading.value = true
  error.value = null
  
  try {
    const response = await gameAPI.setupGame(gameStateId.value)
    result.value = response.data
    console.log('發牌成功:', response.data)
  } catch (err) {
    error.value = err.response?.data || err.message
    console.error('發牌失敗:', err)
  } finally {
    loading.value = false
  }
}

// 測試查詢遊戲狀態
const testGetGameState = async () => {
  if (!gameStateId.value) {
    alert('請先初始化遊戲')
    return
  }
  
  loading.value = true
  error.value = null
  
  try {
    const response = await gameAPI.getGameState(gameStateId.value)
    result.value = response.data
    console.log('查詢成功:', response.data)
  } catch (err) {
    error.value = err.response?.data || err.message
    console.error('查詢失敗:', err)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="game-test">
    <h1>遊戲 API 測試</h1>
    
    <div class="buttons">
      <button @click="testInitGame" :disabled="loading">
        1. 初始化遊戲
      </button>
      <button @click="testSetupGame" :disabled="loading || !gameStateId">
        2. 發牌
      </button>
      <button @click="testGetGameState" :disabled="loading || !gameStateId">
        3. 查詢遊戲狀態
      </button>
    </div>
    
    <div v-if="loading" class="loading">
      載入中...
    </div>
    
    <div v-if="error" class="error">
      <h3>錯誤:</h3>
      <pre>{{ error }}</pre>
    </div>
    
    <div v-if="result" class="result">
      <h3>結果:</h3>
      <pre>{{ JSON.stringify(result, null, 2) }}</pre>
    </div>
    
    <div v-if="gameStateId" class="info">
      <p>遊戲 ID: {{ gameStateId }}</p>
    </div>
  </div>
</template>

<style scoped>
.game-test {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.buttons {
  display: flex;
  gap: 10px;
  margin: 20px 0;
}

button {
  padding: 10px 20px;
  font-size: 16px;
  cursor: pointer;
  background: #42b983;
  color: white;
  border: none;
  border-radius: 4px;
}

button:disabled {
  background: #ccc;
  cursor: not-allowed;
}

button:hover:not(:disabled) {
  background: #35a372;
}

.loading {
  padding: 20px;
  background: #f0f0f0;
  border-radius: 4px;
}

.error {
  padding: 20px;
  background: #ffe6e6;
  border: 1px solid #ff0000;
  border-radius: 4px;
  margin: 20px 0;
}

.result {
  padding: 20px;
  background: #e6ffe6;
  border: 1px solid #00aa00;
  border-radius: 4px;
  margin: 20px 0;
}

.info {
  padding: 10px;
  background: #e6f3ff;
  border-radius: 4px;
  margin: 20px 0;
}

pre {
  white-space: pre-wrap;
  word-wrap: break-word;
  font-family: monospace;
  font-size: 14px;
}
</style>
