import { createConsumer } from '@rails/actioncable'

class WebSocketService {
  constructor() {
    this.cable = null
    this.subscriptions = {}
  }

  // 連接 WebSocket（需要傳入 JWT token）
  connect(token) {
    if (this.cable) {
      this.disconnect()
    }

    this.cable = createConsumer(`ws://localhost:3000/cable?token=${token}`)
    console.log('WebSocket connected')
  }

  // 訂閱頻道
  subscribe(channelName, params = {}, callbacks = {}) {
    if (!this.cable) {
      console.error('WebSocket not connected')
      return null
    }

    const subscription = this.cable.subscriptions.create(
      { channel: channelName, ...params },
      {
        connected: () => {
          console.log(`Connected to ${channelName}`)
          callbacks.connected?.()
        },
        disconnected: () => {
          console.log(`Disconnected from ${channelName}`)
          callbacks.disconnected?.()
        },
        received: (data) => {
          callbacks.received?.(data)
        }
      }
    )

    this.subscriptions[channelName] = subscription
    return subscription
  }

  // 取消訂閱
  unsubscribe(channelName) {
    if (this.subscriptions[channelName]) {
      this.subscriptions[channelName].unsubscribe()
      delete this.subscriptions[channelName]
    }
  }

  // 斷開連接
  disconnect() {
    if (this.cable) {
      this.cable.disconnect()
      this.cable = null
      this.subscriptions = {}
      console.log('WebSocket disconnected')
    }
  }
}

export default new WebSocketService()
