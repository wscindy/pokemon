// frontend/vue-project/src/services/websocket.js
import { createConsumer } from '@rails/actioncable'
import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL

class WebSocketService {
  constructor() {
    this.consumer = null
    this.subscription = null
    this.callbacks = {}
  }

  async connect(roomId) {
    if (this.subscription) {
      console.log('⚠️ 已經連線，先斷線')
      this.disconnect()
    }

    try {
      // 🔥 重點：先取得 WebSocket token
      const tokenResponse = await axios.get(`${API_BASE_URL}/api/v1/auth/ws_token`, {
        withCredentials: true
      })
      
      const wsToken = tokenResponse.data.token
      
      // 建立 WebSocket 連線，帶上 token
      const wsUrl = import.meta.env.VITE_WS_URL
      this.consumer = createConsumer(`${wsUrl}?token=${wsToken}`)

      console.log(`🔌 連接 WebSocket: game_${roomId}`)

      // 訂閱頻道
      this.subscription = this.consumer.subscriptions.create(
        {
          channel: 'GameChannel',
          room_id: roomId
        },
        {
          connected: () => {
            console.log('✅ WebSocket 連線成功')
            this.trigger('connected')
          },

          disconnected: () => {
            console.log('❌ WebSocket 斷線')
            this.trigger('disconnected')
          },

          received: (data) => {
            console.log('📨 收到訊息:', data)
            
            // 根據訊息類型觸發不同的回調
            if (data.type === 'game_update') {
              this.trigger('gameUpdate', data)
            } else if (data.type === 'player_joined') {
              this.trigger('playerJoined', data)
            } else if (data.type === 'player_left') {
              this.trigger('playerLeft', data)
            }
          }
        }
      )

      return this.subscription
    } catch (error) {
      console.error('❌ WebSocket 連線失敗:', error)
      throw error
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
    
    if (this.consumer) {
      this.consumer.disconnect()
      this.consumer = null
    }
    
    this.callbacks = {}
    console.log('🔌 WebSocket 已斷線')
  }

  // 註冊事件回調
  on(event, callback) {
    if (!this.callbacks[event]) {
      this.callbacks[event] = []
    }
    this.callbacks[event].push(callback)
  }

  // 移除事件回調
  off(event, callback) {
    if (!this.callbacks[event]) return
    
    if (callback) {
      this.callbacks[event] = this.callbacks[event].filter(cb => cb !== callback)
    } else {
      delete this.callbacks[event]
    }
  }

  // 觸發事件
  trigger(event, data) {
    if (!this.callbacks[event]) return
    
    this.callbacks[event].forEach(callback => {
      try {
        callback(data)
      } catch (error) {
        console.error(`事件 ${event} 回調錯誤:`, error)
      }
    })
  }
}

// 單例模式
export default new WebSocketService()
