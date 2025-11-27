import apiClient from './api'

export default {
  // 初始化遊戲
  initializeGame() {
    return apiClient.post('/games/initialize')
  },

  // 發牌
  setupGame(gameStateId) {
    return apiClient.post(`/games/${gameStateId}/setup`)
  },

  // 查詢遊戲狀態
  getGameState(gameStateId) {
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
