<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { gameAPI } from '@/services/api'
import authService from '@/services/auth'

const router = useRouter()

const userProfile = ref({
  nickname: '',
  avatarId: null,
  avatar_url: ''
})

const currentRoomId = ref(null)
const roomIdInput = ref('')
const isStartingBattle = ref(false)
const isLoading = ref(true)
const isJoining = ref(false)
const errorMessage = ref('')

// 預設頭像列表
const avatars = [
  { id: 1, emoji: '⚡' },
  { id: 2, emoji: '🔥' },
  { id: 3, emoji: '💧' },
  { id: 4, emoji: '🍃' },
  { id: 5, emoji: '🌟' },
  { id: 6, emoji: '👻' },
  { id: 7, emoji: '🐉' },
  { id: 8, emoji: '💎' },
  { id: 9, emoji: '🦋' },
]

const getUserAvatar = () => {
  if (userProfile.value.avatar_url) {
    return userProfile.value.avatar_url
  }
  const avatar = avatars.find(a => a.id === userProfile.value.avatarId)
  return avatar?.emoji || '👤'
}

onMounted(async () => {
  try {
    const user = await authService.getCurrentUser()
    console.log('Current user:', user)
    
    userProfile.value = {
      nickname: user.name || '訓練家',
      avatarId: null,
      avatar_url: user.avatar_url
    }
  } catch (error) {
    console.error('Failed to get user profile:', error)
    router.push({ name: 'Landing' })
  } finally {
    isLoading.value = false
  }
})

const handleLogout = async () => {
  try {
    await authService.logout()
    router.push({ name: 'Landing' })
  } catch (error) {
    console.error('Logout failed:', error)
    router.push({ name: 'Landing' })
  }
}

// 開始對戰（建立房間）
const handleStartBattle = async () => {
  isStartingBattle.value = true
  errorMessage.value = ''
  
  try {
    console.log('🎮 開始建立房間...')
    
    const initResponse = await gameAPI.initializeGame()
    console.log('✅ 初始化回應:', initResponse.data)
    
    const roomId = initResponse.data.room_id
    
    console.log('🎴 開始發牌...')
    await gameAPI.setupGame(roomId)
    console.log('✅ 發牌完成')
    
    currentRoomId.value = roomId
    
    console.log('🚀 跳轉到遊戲畫面:', roomId)
    router.push({ 
      name: 'GameBoard',
      params: { id: String(roomId) }
    })
    
  } catch (error) {
    console.error('❌ 開始對戰失敗:', error)
    errorMessage.value = error.response?.data?.error || '開始對戰失敗'
  } finally {
    isStartingBattle.value = false
  }
}

// 加入房間
const handleJoinRoom = async () => {
  if (!roomIdInput.value) {
    errorMessage.value = '請輸入房間號碼'
    return
  }
  
  isJoining.value = true
  errorMessage.value = ''
  
  try {
    console.log('🚪 加入房間:', roomIdInput.value)
    
    const response = await gameAPI.joinRoom(roomIdInput.value)
    console.log('✅ 加入房間成功:', response.data)
    
    console.log('🎴 開始發牌...')
    await gameAPI.setupGame(roomIdInput.value)
    console.log('✅ 發牌完成')
    
    console.log('🚀 跳轉到遊戲畫面:', roomIdInput.value)
    router.push({
      name: 'GameBoard',
      params: { id: String(roomIdInput.value) }
    })
    
  } catch (error) {
    console.error('❌ 加入房間失敗:', error)
    const errorMsg = error.response?.data?.error || '加入房間失敗'
    const hint = error.response?.data?.hint || ''
    
    errorMessage.value = hint ? `${errorMsg}\n\n💡 ${hint}` : errorMsg
  } finally {
    isJoining.value = false
  }
}

// 複製房間號碼
const copyRoomId = () => {
  navigator.clipboard.writeText(currentRoomId.value)
  alert('房間號碼已複製！')
}

const handleDeckManagement = () => {
  router.push({ name: 'DeckBuilder' })
}
</script>

<template>
  <div class="game-lobby">
    <!-- Loading 狀態 -->
    <div v-if="isLoading" class="loading-container">
      <div class="loading-spinner">載入中...</div>
    </div>

    <!-- 主要內容 -->
    <div v-else class="lobby-container">
      <!-- Header -->
      <header class="lobby-header">
        <div class="header-left">
          <h1 class="header-title">⚡ Pokémon TCG Online</h1>
        </div>
        
        <div class="header-right">
          <div class="user-profile">
            <div class="avatar">{{ getUserAvatar() }}</div>
            <span class="nickname">{{ userProfile.nickname }}</span>
          </div>
          <button @click="handleLogout" class="logout-btn">登出</button>
        </div>
      </header>

      <!-- 主要內容區域 -->
      <main class="lobby-content">
        <!-- 錯誤訊息 -->
        <div v-if="errorMessage" class="error-message">
          {{ errorMessage }}
        </div>

        <!-- 功能卡片區域 -->
        <div class="action-grid">
          <!-- 開始對戰 -->
          <div class="action-card">
            <div class="card-icon">🎮</div>
            <h3 class="card-title">開始對戰</h3>
            <p class="card-description">建立新房間並開始遊戲</p>
            
            <button 
              @click="handleStartBattle" 
              class="primary-btn"
              :disabled="isStartingBattle"
            >
              {{ isStartingBattle ? '建立中...' : '開始對戰' }}
            </button>
            
            <!-- 顯示房間號碼 -->
            <div v-if="currentRoomId" class="room-info">
              <div class="room-label">房間號碼</div>
              <div class="room-id">{{ currentRoomId }}</div>
              <button @click="copyRoomId" class="copy-btn">📋 複製</button>
            </div>
          </div>

          <!-- 加入房間 -->
          <div class="action-card">
            <div class="card-icon">🚪</div>
            <h3 class="card-title">加入房間</h3>
            <p class="card-description">輸入房間號碼加入對戰</p>
            
            <input 
              v-model="roomIdInput" 
              type="text" 
              placeholder="輸入房間號碼"
              class="room-input"
              @keyup.enter="handleJoinRoom"
            />
            
            <button 
              @click="handleJoinRoom" 
              class="primary-btn"
              :disabled="isJoining"
            >
              {{ isJoining ? '加入中...' : '加入房間' }}
            </button>
          </div>

          <!-- 牌組管理 -->
          <div class="action-card">
            <div class="card-icon">🎴</div>
            <h3 class="card-title">牌組管理</h3>
            <p class="card-description">編輯你的牌組</p>
            
            <button @click="handleDeckManagement" class="primary-btn">
              管理牌組
            </button>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<style scoped>
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

.game-lobby {
  min-height: 100vh;
  background: #f7fafc;
}

/* Loading */
.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
}

.loading-spinner {
  font-size: 24px;
  color: #667eea;
  font-weight: 600;
}

/* Header */
.lobby-header {
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

.header-left {
  display: flex;
  align-items: center;
}

.header-title {
  font-size: 24px;
  font-weight: 700;
  color: #2d3748;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.user-profile {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  background: #f7fafc;
  border-radius: 8px;
}

.avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  border: 2px solid #e2e8f0;
}

.nickname {
  font-size: 16px;
  font-weight: 600;
  color: #2d3748;
}

.logout-btn {
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

.logout-btn:hover {
  background: #f7fafc;
  border-color: #cbd5e0;
}

/* Main Content */
.lobby-content {
  padding: 40px 24px;
  max-width: 1200px;
  margin: 0 auto;
}

/* Error Message */
.error-message {
  background: #fed7d7;
  border: 2px solid #fc8181;
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 24px;
  color: #742a2a;
  white-space: pre-line;
  font-size: 14px;
  line-height: 1.6;
  font-weight: 600;
}

/* Action Grid */
.action-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 24px;
}

.action-card {
  background: white;
  border-radius: 16px;
  padding: 32px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.3s;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.action-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.12);
}

.card-icon {
  font-size: 64px;
  margin-bottom: 20px;
}

.card-title {
  font-size: 24px;
  font-weight: 700;
  color: #2d3748;
  margin-bottom: 12px;
}

.card-description {
  font-size: 14px;
  color: #718096;
  margin-bottom: 24px;
  line-height: 1.6;
}

/* Buttons */
.primary-btn {
  width: 100%;
  padding: 16px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s;
}

.primary-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(102, 126, 234, 0.4);
}

.primary-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

/* Room Input */
.room-input {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 16px;
  margin-bottom: 16px;
  transition: all 0.3s;
}

.room-input:focus {
  outline: none;
  border-color: #667eea;
}

/* Room Info */
.room-info {
  margin-top: 20px;
  padding: 16px;
  background: #f7fafc;
  border-radius: 8px;
  border: 2px solid #e2e8f0;
  width: 100%;
}

.room-label {
  font-size: 12px;
  color: #718096;
  margin-bottom: 8px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.room-id {
  font-size: 24px;
  font-weight: 700;
  color: #667eea;
  margin-bottom: 12px;
}

.copy-btn {
  width: 100%;
  padding: 10px;
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  color: #718096;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.copy-btn:hover {
  background: #f7fafc;
  border-color: #cbd5e0;
  color: #2d3748;
}

/* Responsive */
@media (max-width: 768px) {
  .lobby-header {
    flex-direction: column;
    gap: 16px;
    padding: 16px;
  }
  
  .header-title {
    font-size: 20px;
  }
  
  .header-right {
    width: 100%;
    justify-content: space-between;
  }
  
  .action-grid {
    grid-template-columns: 1fr;
  }
  
  .lobby-content {
    padding: 24px 16px;
  }
}

@media (max-width: 480px) {
  .header-title {
    font-size: 18px;
  }
  
  .card-icon {
    font-size: 48px;
  }
  
  .card-title {
    font-size: 20px;
  }
  
  .action-card {
    padding: 24px;
  }
}
</style>
