import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL

axios.defaults.withCredentials = true

class AuthService {
  // Google 登入
  async loginWithGoogle(credential) {
    try {
      const response = await axios.post(`${API_BASE_URL}/auth/google`, {
        credential: credential
      })
      return response.data
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    }
  }

  // 取得當前用戶資訊
  async getCurrentUser() {
    try {
      const response = await axios.get(`${API_BASE_URL}/auth/me`)
      return response.data.user
    } catch (error) {
      if (error.response?.status === 401) {
        try {
          await this.refreshToken()
          const response = await axios.get(`${API_BASE_URL}/auth/me`)
          return response.data.user
        } catch (refreshError) {
          throw refreshError
        }
      }
      throw error
    }
  }

  // 取得 WebSocket Token
  async getWebSocketToken() {
    try {
      const response = await axios.get(`${API_BASE_URL}/auth/ws_token`)
      return response.data.token
    } catch (error) {
      console.error('Get WS token failed:', error)
      throw error
    }
  }

  // 更新個人資料
  async updateProfile(profileData) {
    try {
      const response = await axios.patch(`${API_BASE_URL}/users/profile`, {
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
      const response = await axios.post(`${API_BASE_URL}/auth/refresh`)
      return response.data
    } catch (error) {
      console.error('Token refresh failed:', error)
      throw error
    }
  }

  // 登出
  async logout() {
    try {
      await axios.delete(`${API_BASE_URL}/auth/logout`)
    } catch (error) {
      console.error('Logout failed:', error)
      throw error
    }
  }
}

export default new AuthService()
