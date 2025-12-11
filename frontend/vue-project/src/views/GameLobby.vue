<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { gameAPI } from '@/services/api'
import authService from '@/services/auth'  // 加入這行

const router = useRouter()

const userProfile = ref({
  nickname: '',
  avatarId: null,
  avatar_url: ''
})

// 新增 loading 狀態
const isStartingBattle = ref(false)
const isLoading = ref(true)

// 預設頭像列表（與 ProfileSetup 相同）
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
  // 如果有 avatar_url（emoji），直接顯示
  if (userProfile.value.avatar_url) {
    return userProfile.value.avatar_url
  }
  // 否則根據 avatarId 找
  const avatar = avatars.find(a => a.id === userProfile.value.avatarId)
  return avatar?.emoji || '👤'
}

onMounted(async () => {
  try {
    // 從後端 API 取得當前用戶資料
    const user = await authService.getCurrentUser()
    
    console.log('Current user:', user)
    
    userProfile.value = {
      nickname: user.name || '訓練家',
      avatarId: null,
      avatar_url: user.avatar_url
    }
  } catch (error) {
    console.error('Failed to get user profile:', error)
    // 如果取得失敗，導回登入頁
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
    // 即使 API 失敗也清除前端狀態
    router.push({ name: 'Landing' })
  }
}

// 修改這個函數
const handleStartBattle = async () => {
  isStartingBattle.value = true
  
  try {
    // 1. 初始化遊戲
    const initResponse = await gameAPI.initializeGame()
    const gameStateId = initResponse.data.game_state_id
    
    // 2. 發牌
    await gameAPI.setupGame(gameStateId)
    
    // 3. 跳轉到遊戲畫面
    router.push({ 
      name: 'GameBoard',
      params: { id: gameStateId }
    })
    
  } catch (error) {
    console.error('開始對戰失敗:', error)
    alert('開始對戰失敗: ' + (error.response?.data?.error || error.message))
  } finally {
    isStartingBattle.value = false
  }
}

const handleSpectate = () => {
  alert('觀戰功能開發中...')
}

const handleDeckManagement = () => {
  router.push({ name: 'DeckBuilder' })
}
</script>

<template>
  <div class="game-lobby">
    <!-- Loading 狀態 -->
    <div v-if="isLoading" class="loading-screen">
      <div class="spinner"></div>
      <p>載入中...</p>
    </div>
    
    <!-- 主要內容 -->
    <template v-else>
      <!-- 頂部導航 -->
      <header class="lobby-header">
        <div class="header-content">
          <div class="logo">
            <h1 class="logo-text">POKÉMON TCG</h1>
          </div>
          
          <div class="user-section">
            <div class="user-info">
              <div class="user-avatar">{{ getUserAvatar() }}</div>
              <span class="user-nickname">{{ userProfile.nickname }}</span>
            </div>
            <button class="logout-btn" @click="handleLogout">登出</button>
          </div>
        </div>
      </header>
      
      <!-- 主要內容 -->
      <main class="lobby-main">
        <div class="main-content">
          <h2 class="welcome-title">歡迎回來，{{ userProfile.nickname }}！</h2>
          <p class="welcome-subtitle">選擇你的下一步行動</p>
          
          <!-- 主要功能按鈕 -->
          <div class="action-grid">
            <button 
              class="action-card primary" 
              @click="handleStartBattle"
              :disabled="isStartingBattle"
            >
              <div class="action-icon">⚔️</div>
              <h3 class="action-title">
                {{ isStartingBattle ? '準備中...' : '開始對戰' }}
              </h3>
              <p class="action-description">尋找對手進行即時對戰</p>
            </button>
            
            <button class="action-card" @click="handleSpectate">
              <div class="action-icon">👁️</div>
              <h3 class="action-title">觀戰</h3>
              <p class="action-description">觀看其他玩家的對戰</p>
            </button>
            
            <button class="action-card" @click="handleDeckManagement">
              <div class="action-icon">🎴</div>
              <h3 class="action-title">牌組管理</h3>
              <p class="action-description">建立和編輯你的牌組</p>
            </button>
            
            <button class="action-card" disabled>
              <div class="action-icon">🏆</div>
              <h3 class="action-title">排行榜</h3>
              <p class="action-description">即將推出</p>
            </button>
          </div>
        </div>
      </main>
    </template>
  </div>
</template>

<style scoped>
.game-lobby {
  min-height: 100vh;
  background: linear-gradient(180deg, #e8f4f8 0%, #f0f4f8 50%, #e8f4f8 100%);
}

/* Loading 畫面 */
.loading-screen {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid rgba(102, 126, 234, 0.2);
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* 頂部導航 */
.lobby-header {
  background: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 16px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo-text {
  font-size: 24px;
  font-weight: 900;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.user-section {
  display: flex;
  align-items: center;
  gap: 16px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  background: #f7fafc;
  border-radius: 12px;
}

.user-avatar {
  width: 40px;
  height: 40px;
  /* background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); */
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
}

.user-nickname {
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

/* 主要內容 */
.lobby-main {
  padding: 60px 20px;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
}

.welcome-title {
  font-size: 36px;
  font-weight: 700;
  color: #2d3748;
  text-align: center;
  margin-bottom: 8px;
}

.welcome-subtitle {
  font-size: 18px;
  color: #718096;
  text-align: center;
  margin-bottom: 48px;
}

/* 功能卡片網格 */
.action-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 24px;
}

.action-card {
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 16px;
  padding: 32px 24px;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.action-card:hover:not(:disabled) {
  border-color: #667eea;
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(102, 126, 234, 0.2);
}

.action-card:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.action-card.primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  color: white;
}

.action-card.primary .action-title,
.action-card.primary .action-description {
  color: white;
}

.action-icon {
  font-size: 48px;
  margin-bottom: 16px;
  filter: drop-shadow(2px 2px 4px rgba(0, 0, 0, 0.1));
}

.action-title {
  font-size: 22px;
  font-weight: 700;
  color: #2d3748;
  margin-bottom: 8px;
}

.action-description {
  font-size: 14px;
  color: #718096;
  line-height: 1.5;
}

/* 響應式設計 */
@media (max-width: 768px) {
  .header-content {
    padding: 12px 16px;
  }
  
  .logo-text {
    font-size: 20px;
  }
  
  .user-nickname {
    display: none;
  }
  
  .welcome-title {
    font-size: 28px;
  }
  
  .welcome-subtitle {
    font-size: 16px;
  }
  
  .action-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }
}

@media (max-width: 400px) {
  .lobby-main {
    padding: 40px 16px;
  }
  
  .welcome-title {
    font-size: 24px;
  }
  
  .action-card {
    padding: 24px 20px;
  }
  
  .action-icon {
    font-size: 40px;
  }
  
  .action-title {
    font-size: 20px;
  }
}
</style>
