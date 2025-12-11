<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import authService from '@/services/auth'

const router = useRouter()

const selectedAvatar = ref(null)
const nickname = ref('')
const nicknameError = ref('')
const isSubmitting = ref(false)

// 預設頭像列表
const avatars = [
  { id: 1, emoji: '⚡', name: 'Pikachu' },
  { id: 2, emoji: '🔥', name: 'Charizard' },
  { id: 3, emoji: '💧', name: 'Squirtle' },
  { id: 4, emoji: '🍃', name: 'Bulbasaur' },
  { id: 5, emoji: '🌟', name: 'Eevee' },
  { id: 6, emoji: '👻', name: 'Gengar' },
  { id: 7, emoji: '🐉', name: 'Dragonite' },
  { id: 8, emoji: '💎', name: 'Ditto' },
  { id: 9, emoji: '🦋', name: 'Butterfree' },
]

const selectAvatar = (avatarId) => {
  selectedAvatar.value = avatarId
}

const validateNickname = () => {
  nicknameError.value = ''
  
  if (!nickname.value.trim()) {
    nicknameError.value = '請輸入暱稱'
    return false
  }
  
  if (nickname.value.length < 2) {
    nicknameError.value = '暱稱至少需要 2 個字元'
    return false
  }
  
  if (nickname.value.length > 12) {
    nicknameError.value = '暱稱不能超過 12 個字元'
    return false
  }
  
  return true
}

const handleSubmit = async () => {
  if (!selectedAvatar.value) {
    alert('請選擇頭像')
    return
  }
  
  if (!validateNickname()) {
    return
  }
  
  isSubmitting.value = true
  
  try {
    // 取得選中的頭像
    const avatar = avatars.find(a => a.id === selectedAvatar.value)
    
    // 呼叫 API 更新個人資料
    await authService.updateProfile({
      name: nickname.value,
      avatar_url: avatar.emoji  // 存 emoji 或其他識別碼
    })
    
    console.log('Profile updated successfully')
    
    // 前往遊戲大廳
    router.push({ name: 'GameLobby' })
  } catch (error) {
    console.error('Profile update failed:', error)
    alert('設定失敗，請稍後再試')
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="profile-setup">
    <div class="setup-container">
      <!-- 標題 -->
      <div class="header">
        <h1 class="title">建立你的訓練家檔案</h1>
        <p class="subtitle">選擇頭像並設定暱稱</p>
      </div>
      
      <!-- 頭像選擇 -->
      <div class="section">
        <h2 class="section-title">選擇頭像</h2>
        <div class="avatar-grid">
          <button
            v-for="avatar in avatars"
            :key="avatar.id"
            class="avatar-option"
            :class="{ selected: selectedAvatar === avatar.id }"
            @click="selectAvatar(avatar.id)"
          >
            <span class="avatar-emoji">{{ avatar.emoji }}</span>
            <div v-if="selectedAvatar === avatar.id" class="check-icon">✓</div>
          </button>
        </div>
      </div>
      
      <!-- 暱稱輸入 -->
      <div class="section">
        <h2 class="section-title">設定暱稱</h2>
        <div class="input-wrapper">
          <input
            v-model="nickname"
            type="text"
            class="nickname-input"
            :class="{ error: nicknameError }"
            placeholder="輸入你的暱稱"
            maxlength="12"
            @input="validateNickname"
          />
          <div class="char-count">{{ nickname.length }}/12</div>
        </div>
        <p v-if="nicknameError" class="error-message">{{ nicknameError }}</p>
      </div>
      
      <!-- 確認按鈕 -->
      <button
        class="submit-btn"
        :disabled="!selectedAvatar || !nickname.trim() || isSubmitting"
        @click="handleSubmit"
      >
        <span v-if="!isSubmitting">開始遊戲</span>
        <span v-else>設定中...</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.profile-setup {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.setup-container {
  background: white;
  border-radius: 24px;
  padding: 48px 40px;
  max-width: 600px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  animation: fadeIn 0.5s ease;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* 標題 */
.header {
  text-align: center;
  margin-bottom: 40px;
}

.title {
  font-size: 32px;
  font-weight: 700;
  color: #2d3748;
  margin-bottom: 8px;
}

.subtitle {
  font-size: 16px;
  color: #718096;
}

/* 區塊 */
.section {
  margin-bottom: 32px;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
  color: #2d3748;
  margin-bottom: 16px;
}

/* 頭像選擇 */
.avatar-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(80px, 1fr));
  gap: 12px;
}

.avatar-option {
  position: relative;
  aspect-ratio: 1;
  background: #f7fafc;
  border: 3px solid #e2e8f0;
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 40px;
  padding: 0;
}

.avatar-option:hover {
  background: #edf2f7;
  border-color: #cbd5e0;
  transform: translateY(-2px);
}

.avatar-option.selected {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-color: #5a67d8;
  transform: scale(1.05);
}

.avatar-emoji {
  filter: grayscale(30%);
  transition: filter 0.3s;
}

.avatar-option.selected .avatar-emoji {
  filter: grayscale(0%) drop-shadow(0 2px 4px rgba(0, 0, 0, 0.2));
}

.check-icon {
  position: absolute;
  top: 4px;
  right: 4px;
  width: 24px;
  height: 24px;
  background: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  color: #5a67d8;
  font-weight: bold;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

/* 暱稱輸入 */
.input-wrapper {
  position: relative;
}

.nickname-input {
  width: 100%;
  padding: 14px 60px 14px 16px;
  font-size: 16px;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  transition: all 0.3s;
  font-family: inherit;
}

.nickname-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.nickname-input.error {
  border-color: #f56565;
}

.char-count {
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 14px;
  color: #a0aec0;
  pointer-events: none;
}

.error-message {
  font-size: 14px;
  color: #f56565;
  margin-top: 8px;
}

/* 提交按鈕 */
.submit-btn {
  width: 100%;
  padding: 16px;
  font-size: 18px;
  font-weight: 600;
  color: white;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
  margin-top: 24px;
}

.submit-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(102, 126, 234, 0.5);
}

.submit-btn:active:not(:disabled) {
  transform: translateY(0);
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

/* 響應式設計 */
@media (max-width: 640px) {
  .setup-container {
    padding: 32px 24px;
  }
  
  .title {
    font-size: 26px;
  }
  
  .avatar-grid {
    grid-template-columns: repeat(3, 1fr);
  }
  
  .avatar-option {
    font-size: 32px;
  }
}

@media (max-width: 400px) {
  .setup-container {
    padding: 24px 20px;
  }
  
  .title {
    font-size: 24px;
  }
}
</style>
