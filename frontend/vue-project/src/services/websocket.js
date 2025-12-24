// src/services/websocket.js
import { createConsumer } from '@rails/actioncable'
import { apiClient } from './auth'

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
      console.log('🔌 準備連接 WebSocket...')
      console.log('📍 傳入的 roomId:', roomId, '型別:', typeof roomId)
      
      // 🔥 1. 先取得 WebSocket token
      console.log('📡 請求 WS token...')
      const tokenResponse = await apiClient.get('/auth/ws_token')
      const wsToken = tokenResponse.data.token
      
      console.log('✅ 取得 WS token:', wsToken ? wsToken.substring(0, 20) + '...' : 'null')
      
      if (!wsToken) {
        throw new Error('無法取得 WebSocket token')
      }
      
      // 🔥 2. 建立 WebSocket URL
      const wsUrl = import.meta.env.VITE_WS_URL || 'wss://pokemonww-api.zeabur.app'
      const fullUrl = `${wsUrl}/cable?token=${wsToken}`
      
      console.log('🔗 WebSocket URL:', fullUrl.replace(wsToken, wsToken.substring(0, 20) + '...'))
      
      // 🔥 3. 建立 consumer
      this.consumer = createConsumer(fullUrl)
      
      console.log(`📺 訂閱頻道: GameChannel, room_id: ${roomId}`)
      console.log('📺 room_id 型別:', typeof roomId)

      // 🔥 4. 訂閱頻道
      this.subscription = this.consumer.subscriptions.create(
        {
          channel: 'GameChannel',
          room_id: roomId
        },
        {
          connected: () => {
            console.log('✅ WebSocket 連線成功')
            console.log('📍 已訂閱 room_id:', roomId) 
            this.trigger('connected')
          },

          disconnected: () => {
            console.log('❌ WebSocket 斷線')
            this.trigger('disconnected')
          },

          received: (data) => {
            console.log('📨 收到訊息:', data)
            
            // 根據訊息類型觸發不同的回調
            switch(data.type) {
              case 'game_update':
                this.trigger('gameUpdate', data)
                break
              case 'player_joined':
                this.trigger('playerJoined', data)
                break
              case 'player_left':
                this.trigger('playerLeft', data)
                break
              default:
                console.log('未知的訊息類型:', data.type)
            }
          }
        }
      )

      console.log('✅ WebSocket 設定完成')
      return this.subscription
      
    } catch (error) {
      console.error('❌ WebSocket 連線失敗:', error)
      console.error('錯誤詳情:', error.response?.data || error.message)
      throw error
    }
  }

  disconnect() {
    if (this.subscription) {
      console.log('🔌 取消訂閱...')
      this.subscription.unsubscribe()
      this.subscription = null
    }
    
    if (this.consumer) {
      console.log('🔌 斷開 consumer...')
      this.consumer.disconnect()
      this.consumer = null
    }
    
    this.callbacks = {}
    console.log('✅ WebSocket 已完全斷線')
  }

  // 註冊事件回調
  on(event, callback) {
    if (!this.callbacks[event]) {
      this.callbacks[event] = []
    }
    this.callbacks[event].push(callback)
    console.log(`📝 註冊事件: ${event}`)
  }

  // 移除事件回調
  off(event, callback) {
    if (!this.callbacks[event]) return
    
    if (callback) {
      this.callbacks[event] = this.callbacks[event].filter(cb => cb !== callback)
    } else {
      delete this.callbacks[event]
    }
    console.log(`🗑️ 移除事件: ${event}`)
  }

  // 觸發事件
  trigger(event, data) {
    if (!this.callbacks[event]) {
      console.log(`⚠️ 沒有監聽器: ${event}`)
      return
    }
    
    console.log(`🎯 觸發事件: ${event}, 監聽器數量: ${this.callbacks[event].length}`)
    
    this.callbacks[event].forEach(callback => {
      try {
        callback(data)
      } catch (error) {
        console.error(`❌ 事件 ${event} 回調錯誤:`, error)
      }
    })
  }
}

// 單例模式
export default new WebSocketService()
