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

// 遊戲相關 API
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

  // 抽牌
  drawCard(gameStateId) {
    return api.post(`/games/${gameStateId}/draw`)
  },
  
  // 出牌到戰鬥場或備戰區
  playCard(gameStateId, cardId, position) {
    return api.post(`/games/${gameStateId}/play_card`, {
      card_id: cardId,
      position: position  // 'active' 或 'bench'
    })
  },
  
  // 附加能量
  attachEnergy(gameStateId, cardId, targetCardId) {
    return api.post(`/games/${gameStateId}/attach_energy`, {
      card_id: cardId,
      target_card_id: targetCardId
    })
  },

  // 🆕 移動卡牌(完全自由)
  moveCard(gameStateId, cardId, toZone, toPosition = null) {
    return api.post(`/games/${gameStateId}/move_card`, {
      card_id: cardId,
      to_zone: toZone,        // 'hand', 'discard', 'deck', 'active', 'bench'
      to_position: toPosition  // 如果是 bench,指定位置 0-4
    })
  },

  // 🆕 疊加卡牌(進化或其他)
  stackCard(gameStateId, cardId, targetCardId) {
    return api.post(`/games/${gameStateId}/stack_card`, {
      card_id: cardId,           // 要疊上去的卡
      target_card_id: targetCardId  // 目標寶可夢
    })
  },

  // 🆕 更新傷害值
  updateDamage(gameStateId, pokemonId, damageValue) {
    return api.post(`/games/${gameStateId}/update_damage`, {
      pokemon_id: pokemonId,
      damage_taken: damageValue
    })
  },

  // 🆕 轉移能量卡(完全自由)
  transferEnergy(gameStateId, energyId, fromPokemonId, toPokemonId = null, toZone = null) {
    return api.post(`/games/${gameStateId}/transfer_energy`, {
      energy_id: energyId,
      from_pokemon_id: fromPokemonId,
      to_pokemon_id: toPokemonId,  // 轉移到寶可夢
      to_zone: toZone              // 或是移到其他區域 'hand', 'discard', 'deck'
    })
  },

  // 🆕 結束回合
  endTurn(gameStateId) {
    return api.post(`/games/${gameStateId}/end_turn`)
  },

  // 攻擊(保留原有)
  attack(gameStateId, attackerId, defenderId, attackIndex) {
    return api.post(`/games/${gameStateId}/attack`, {
      attacker_id: attackerId,
      defender_id: defenderId,
      attack_index: attackIndex
    })
  }
}

export default api
