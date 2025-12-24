// src/services/gameApi.js
import { apiClient } from './authService'  // 🔥 改成從 authService 導入

export default {
  // 初始化遊戲
  initializeGame() {
    console.log('🎮 初始化遊戲')
    return apiClient.post('/games/initialize')
  },

  // 發牌
  setupGame(gameStateId) {
    console.log('🎴 發牌請求 Room ID:', gameStateId)
    return apiClient.post(`/games/${gameStateId}/setup`)
  },

  // 查詢遊戲狀態
  getGameState(gameStateId) {
    console.log('🔍 查詢遊戲狀態 Room ID:', gameStateId)
    return apiClient.get(`/games/${gameStateId}/state`)
  },

  // 之後可以加入更多 API
  // drawCard(gameStateId) {
  //   return apiClient.post(`/games/${gameStateId}/draw`)
  // },
  
  // playCard(gameStateId, cardId, position) {
  //   return apiClient.post(`/games/${gameStateId}/play`, { cardId, position })
  // }
}
