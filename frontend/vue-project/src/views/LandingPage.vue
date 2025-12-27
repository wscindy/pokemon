<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import authService from '@/services/auth'
import websocketService from '@/services/websocket'

const router = useRouter()
const isLoading = ref(false)
const FRONTEND_URL = import.meta.env.VITE_FRONTEND_URL

// Google 登入處理（改用彈窗流程）
const handleGoogleLogin = () => {
  isLoading.value = true
  
  // 使用 Google OAuth 2.0 彈窗流程
  const clientId = '492452439420-92olit1oung11aun1qh5kaagsr8hi83u.apps.googleusercontent.com'
  const redirectUri = `${FRONTEND_URL}/auth/callback`
  const scope = 'email profile'
  
  const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
    `client_id=${clientId}&` +
    `redirect_uri=${encodeURIComponent(redirectUri)}&` +
    `response_type=token id_token&` +
    `scope=${encodeURIComponent(scope)}&` +
    `nonce=${generateNonce()}&` +
    `prompt=select_account`
  
  // 開啟彈窗
  const width = 500
  const height = 600
  const left = window.screen.width / 2 - width / 2
  const top = window.screen.height / 2 - height / 2
  
  const popup = window.open(
    authUrl,
    'Google Login',
    `width=${width},height=${height},left=${left},top=${top}`
  )
  
  // 監聽彈窗回傳的訊息
  window.addEventListener('message', handleAuthCallback)
}

// 生成 nonce
const generateNonce = () => {
  return Math.random().toString(36).substring(2, 15)
}

// 處理認證回調
const handleAuthCallback = async (event) => {
  // 安全檢查：確認訊息來源
  if (event.origin !== window.location.origin) {
    return
  }
  
  if (event.data.type === 'google-auth-success') {
    try {
      const idToken = event.data.idToken
      
      // 呼叫後端 API 驗證
      const result = await authService.loginWithGoogle(idToken)
      
      console.log('Login successful:', result.user)
      

      
      // 判斷是新用戶還是舊用戶
      const isNewUser = !result.user.name || result.user.name === result.user.email
      
      if (isNewUser) {
        router.push({ name: 'ProfileSetup' })
      } else {
        router.push({ name: 'GameLobby' })
      }
    } catch (error) {
      console.error('Login error:', error)
      alert('登入失敗，請稍後再試')
    } finally {
      isLoading.value = false
      window.removeEventListener('message', handleAuthCallback)
    }
  }
}

onMounted(() => {
  // 不需要載入 Google Identity Services
})
</script>


<template>
  <div class="landing-page">
    <!-- 背景裝飾 -->
    <div class="background-gradient"></div>
    <div class="pokeball-decoration pokeball-1"></div>
    <div class="pokeball-decoration pokeball-2"></div>
    <div class="pokeball-decoration pokeball-3"></div>
    
    <!-- 主要內容 -->
    <div class="content-container">
      <!-- Logo 區域 -->
      <div class="logo-section">
        <h1 class="game-title">
          <span class="title-pokemon">POKÉMON</span>
          <span class="title-tcg">Trading Card Game</span>
        </h1>
        <p class="game-subtitle">Online Battle Arena</p>
      </div>
      
      <!-- 登入區域 -->
      <div class="login-section">
        <div class="welcome-card">
          <h2 class="welcome-title">歡迎來到對戰世界</h2>
          <p class="welcome-text">
            使用 Google 帳號登入，開始你的寶可夢卡牌對戰之旅
          </p>
          
          <!-- Google 登入按鈕 -->
          <button 
            class="google-login-btn" 
            @click="handleGoogleLogin"
            :disabled="isLoading"
          >
            <div class="btn-content">
              <svg class="google-icon" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              <span v-if="!isLoading">使用 Google 帳號登入</span>
              <span v-else>登入中...</span>
            </div>
          </button>
          
          <p class="terms-text">
            登入即表示您同意我們的服務條款和隱私政策
          </p>
        </div>
      </div>
      
      <!-- 特色說明 -->
      <div class="features-section">
        <div class="feature-item">
          <div class="feature-icon">🎴</div>
          <p class="feature-text">收集卡牌</p>
        </div>
        <div class="feature-item">
          <div class="feature-icon">⚔️</div>
          <p class="feature-text">即時對戰</p>
        </div>
        <div class="feature-item">
          <div class="feature-icon">🏆</div>
          <p class="feature-text">競技排名</p>
        </div>
      </div>
    </div>
  </div>
  <div><a class="feature-text" href="https://www.flaticon.com/free-icons/pokemon" title="pokemon icons">Pokemon icons created by Roundicons Freebies - Flaticon</a></div>
</template>

<style scoped>
.landing-page {
  min-height: 100vh;
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

/* 背景設計 */
.background-gradient {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, 
    #667eea 0%, 
    #764ba2 50%, 
    #f093fb 100%
  );
  z-index: -2;
}

.pokeball-decoration {
  position: fixed;
  width: 200px;
  height: 200px;
  border-radius: 50%;
  background: radial-gradient(circle at 30% 30%, 
    rgba(255, 255, 255, 0.3), 
    rgba(255, 255, 255, 0.05)
  );
  z-index: -1;
  animation: float 6s ease-in-out infinite;
}

.pokeball-1 {
  top: 10%;
  left: 5%;
  animation-delay: 0s;
}

.pokeball-2 {
  top: 60%;
  right: 10%;
  width: 150px;
  height: 150px;
  animation-delay: 2s;
}

.pokeball-3 {
  bottom: 10%;
  left: 15%;
  width: 120px;
  height: 120px;
  animation-delay: 4s;
}

@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-20px); }
}

/* 主要內容 */
.content-container {
  max-width: 500px;
  width: 100%;
  z-index: 1;
}

/* Logo 區域 */
.logo-section {
  text-align: center;
  margin-bottom: 40px;
  animation: fadeInDown 0.8s ease;
}

@keyframes fadeInDown {
  from {
    opacity: 0;
    transform: translateY(-30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.game-title {
  margin-bottom: 12px;
}

.title-pokemon {
  display: block;
  font-size: 48px;
  font-weight: 900;
  color: #FFCB05;
  text-shadow: 
    3px 3px 0 #2A75BB,
    -1px -1px 0 #2A75BB,
    1px -1px 0 #2A75BB,
    -1px 1px 0 #2A75BB,
    4px 4px 8px rgba(0, 0, 0, 0.3);
  letter-spacing: 2px;
}

.title-tcg {
  display: block;
  font-size: 20px;
  font-weight: 600;
  color: white;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
  letter-spacing: 4px;
  margin-top: 8px;
}

.game-subtitle {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.95);
  font-weight: 500;
  text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.2);
}

/* 登入區域 */
.login-section {
  animation: fadeInUp 0.8s ease 0.2s backwards;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.welcome-card {
  background: white;
  border-radius: 20px;
  padding: 40px 32px;
  box-shadow: 
    0 20px 60px rgba(0, 0, 0, 0.3),
    0 0 0 1px rgba(255, 255, 255, 0.1);
}

.welcome-title {
  font-size: 28px;
  font-weight: 700;
  color: #2d3748;
  margin-bottom: 12px;
  text-align: center;
}

.welcome-text {
  font-size: 15px;
  color: #718096;
  text-align: center;
  margin-bottom: 32px;
  line-height: 1.6;
}

/* Google 登入按鈕 */
.google-login-btn {
  width: 100%;
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px 24px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 16px;
  font-weight: 600;
  color: #2d3748;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.google-login-btn:hover:not(:disabled) {
  background: #f7fafc;
  border-color: #cbd5e0;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
}

.google-login-btn:active:not(:disabled) {
  transform: translateY(0);
}

.google-login-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-content {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
}

.google-icon {
  width: 24px;
  height: 24px;
}

.terms-text {
  font-size: 12px;
  color: #a0aec0;
  text-align: center;
  margin-top: 24px;
  line-height: 1.5;
}

/* 特色說明 */
.features-section {
  display: flex;
  justify-content: center;
  gap: 32px;
  margin-top: 40px;
  animation: fadeInUp 0.8s ease 0.4s backwards;
}

.feature-item {
  text-align: center;
}

.feature-icon {
  font-size: 32px;
  margin-bottom: 8px;
  filter: drop-shadow(2px 2px 4px rgba(0, 0, 0, 0.2));
}

.feature-text {
  font-size: 14px;
  color: white;
  font-weight: 600;
  text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.3);
}

/* 響應式設計 */
@media (max-width: 640px) {
  .title-pokemon {
    font-size: 36px;
  }
  
  .title-tcg {
    font-size: 16px;
  }
  
  .welcome-card {
    padding: 32px 24px;
  }
  
  .welcome-title {
    font-size: 24px;
  }
  
  .features-section {
    gap: 24px;
  }
  
  .feature-icon {
    font-size: 28px;
  }
  
  .pokeball-decoration {
    width: 120px;
    height: 120px;
  }
}

@media (max-width: 400px) {
  .content-container {
    padding: 0 12px;
  }
  
  .title-pokemon {
    font-size: 32px;
  }
  
  .welcome-card {
    padding: 24px 20px;
  }
}
</style>
