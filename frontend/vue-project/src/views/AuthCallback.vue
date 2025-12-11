<template>
  <div class="auth-callback">
    <div class="loading">
      <div class="spinner"></div>
      <p>登入處理中...</p>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'

onMounted(() => {
  // 從 URL hash 取得 id_token
  const hash = window.location.hash.substring(1)
  const params = new URLSearchParams(hash)
  const idToken = params.get('id_token')
  
  if (idToken) {
    // 將 token 傳回父視窗
    if (window.opener) {
      window.opener.postMessage(
        { type: 'google-auth-success', idToken },
        window.location.origin
      )
      window.close()
    }
  } else {
    // 登入失敗
    if (window.opener) {
      window.opener.postMessage(
        { type: 'google-auth-error' },
        window.location.origin
      )
      window.close()
    }
  }
})
</script>

<style scoped>
.auth-callback {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.loading {
  text-align: center;
  color: white;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid rgba(255, 255, 255, 0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
