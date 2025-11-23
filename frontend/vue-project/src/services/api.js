// src/services/api.js
import axios from 'axios'

const API_BASE_URL = 'http://localhost:3000/api/v1'

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
  
  // 刪除牌組（新增）
  deleteDeck() {
    return api.delete('/deck')
  }
}

export default api
