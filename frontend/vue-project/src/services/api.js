// src/services/api.js
import axios from 'axios'

// 從環境變數讀取 API 網址
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api/v1'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 卡片相關 API
export const cardAPI = {
  // 搜尋卡片
  search(keyword) {
    return api.get('/cards/search', {
      params: { q: keyword }
    })
  },
  
  // 取得單一卡片詳細資訊
  getCard(cardUniqueId) {
    return api.get(`/cards/${cardUniqueId}`)
  }
}

// 牌組相關 API
export const deckAPI = {
  // 取得使用者的牌組
  getDeck() {
    return api.get('/deck')
  },
  
  // 儲存牌組
  saveDeck(cards) {
    return api.post('/deck', { cards })
  },
  
  // 驗證牌組
  validateDeck(cards) {
    return api.post('/deck/validate', { cards })
  },
  
  // 刪除牌組
  deleteDeck() {
    return api.delete('/deck')
  }
}

  // 遊戲相關 API (新增)
export const gameAPI = {
  // 初始化遊戲
  initializeGame() {
    return api.post('/games/initialize')
  },

  // 發牌
  setupGame(gameStateId) {
    return api.post(`/games/${gameStateId}/setup`)
  },

  // 查詢遊戲狀態
  getGameState(gameStateId) {
    return api.get(`/games/${gameStateId}/state`)
  },

  // 之後可以加入更多遊戲操作
  // 抽牌
  drawCard(gameStateId) {
    return api.post(`/games/${gameStateId}/draw`)
  },
  
  // 出牌
  playCard(gameStateId, cardId, position) {
    return api.post(`/games/${gameStateId}/play`, { 
      card_id: cardId, 
      position 
    })
  },
  
  // 攻擊
  attack(gameStateId, attackerId, defenderId, attackIndex) {
    return api.post(`/games/${gameStateId}/attack`, {
      attacker_id: attackerId,
      defender_id: defenderId,
      attack_index: attackIndex
    })
  },
  
  // 結束回合
  endTurn(gameStateId) {
    return api.post(`/games/${gameStateId}/end_turn`)
  }
}

export default api
