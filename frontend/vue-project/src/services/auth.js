import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL

// 創建 axios instance
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true
})

// 🔥 Token 管理工具
const TokenManager = {
  setTokens(accessToken, refreshToken) {
    localStorage.setItem('access_token', accessToken)
    localStorage.setItem('refresh_token', refreshToken)
    console.log('✅ Tokens saved to localStorage')
  },
  
  getAccessToken() {
    return localStorage.getItem('access_token')
  },
  
  getRefreshToken() {
    return localStorage.getItem('refresh_token')
  },
  
  clearTokens() {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    console.log('🗑️ Tokens cleared from localStorage')
  }
}

// 🔥 Request Interceptor - 自動加入 Authorization header
apiClient.interceptors.request.use(
  (config) => {
    const token = TokenManager.getAccessToken()
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 🔥 Response Interceptor - 自動處理 401 和 refresh
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true
      
      const refreshToken = TokenManager.getRefreshToken()
      if (!refreshToken) {
        console.error('❌ No refresh token, redirecting to login...')
        TokenManager.clearTokens()
        window.location.href = '/login'
        return Promise.reject(error)
      }
      
      try {
        console.log('🔄 Token expired, refreshing...')
        
        const response = await axios.post(
          `${API_BASE_URL}/auth/refresh`,
          { refresh_token: refreshToken },
          { withCredentials: true }
        )
        
        const { access_token, refresh_token } = response.data
        TokenManager.setTokens(access_token, refresh_token)
        
        console.log('✅ Token refreshed successfully')
        
        // 用新 token 重試原請求
        originalRequest.headers.Authorization = `Bearer ${access_token}`
        return apiClient(originalRequest)
        
      } catch (refreshError) {
        console.error('❌ Token refresh failed:', refreshError)
        TokenManager.clearTokens()
        window.location.href = '/login'
        return Promise.reject(refreshError)
      }
    }
    
    return Promise.reject(error)
  }
)

class AuthService {
  // Google 登入
  async loginWithGoogle(credential) {
    try {
      const response = await apiClient.post('/auth/google', {
        credential: credential
      })
      
      // 🔥 儲存 tokens
      const { access_token, refresh_token } = response.data
      TokenManager.setTokens(access_token, refresh_token)
      
      console.log('✅ Login successful')
      
      return response.data
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    }
  }

  // 取得當前用戶資訊
  async getCurrentUser() {
    try {
      const response = await apiClient.get('/auth/me')
      return response.data.user
    } catch (error) {
      console.error('Get current user failed:', error)
      throw error
    }
  }

  // 取得 WebSocket Token
  async getWebSocketToken() {
    try {
      const response = await apiClient.get('/auth/ws_token')
      return response.data.token
    } catch (error) {
      console.error('Get WS token failed:', error)
      throw error
    }
  }

  // 更新個人資料
  async updateProfile(profileData) {
    try {
      const response = await apiClient.patch('/users/profile', {
        user: profileData
      })
      return response.data
    } catch (error) {
      console.error('Profile update failed:', error)
      throw error
    }
  }

  // Refresh Token
  async refreshToken() {
    try {
      const refreshToken = TokenManager.getRefreshToken()
      if (!refreshToken) {
        throw new Error('No refresh token available')
      }
      
      const response = await apiClient.post('/auth/refresh', {
        refresh_token: refreshToken
      })
      
      const { access_token, refresh_token } = response.data
      TokenManager.setTokens(access_token, refresh_token)
      
      return response.data
    } catch (error) {
      console.error('Token refresh failed:', error)
      TokenManager.clearTokens()
      throw error
    }
  }

  // 登出
  async logout() {
    try {
      await apiClient.delete('/auth/logout')
      TokenManager.clearTokens()
    } catch (error) {
      console.error('Logout failed:', error)
      TokenManager.clearTokens()
      throw error
    }
  }
  
  // 🔥 新增：檢查是否已登入
  isAuthenticated() {
    return !!TokenManager.getAccessToken()
  }
  
  // 🔥 新增：手動清除認證
  clearAuth() {
    TokenManager.clearTokens()
  }
}

export default new AuthService()
