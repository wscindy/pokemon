// src/services/api.js
import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL

// 🔥 建立兩個不同的 axios instance
// 1. 用於 Cookie-based Auth（Google 登入）
const cookieApi = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
})

// 2. 用於 JWT Token Auth（遊戲 API）
const tokenApi = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
})

// 🔥 只對 tokenApi 加上 JWT 攔截器
tokenApi.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    console.log('📤 API Request:', config.method.toUpperCase(), config.url)
    return config
  },
  (error) => {
    console.error('❌ Request Error:', error)
    return Promise.reject(error)
  }
)

// 響應攔截器
tokenApi.interceptors.response.use(
  (response) => {
    console.log('📥 API Response:', response.config.url, response.status)
    return response
  },
  (error) => {
    console.error('❌ Response Error:', {
      url: error.config?.url,
      status: error.response?.status,
      data: error.response?.data
    })
    return Promise.reject(error)
  }
)

// cookieApi 的攔截器（只記錄，不加 JWT）
cookieApi.interceptors.request.use(
  (config) => {
    console.log('📤 Cookie API Request:', config.method.toUpperCase(), config.url)
    return config
  }
)

cookieApi.interceptors.response.use(
  (response) => {
    console.log('📥 Cookie API Response:', response.config.url, response.status)
    return response
  },
  (error) => {
    console.error('❌ Cookie API Error:', error.response?.data)
    return Promise.reject(error)
  }
)

// 卡片相關 API（使用 tokenApi）
export const cardAPI = {
  search(keyword) {
    return tokenApi.get('/cards/search', {
      params: { q: keyword }
    })
  },
  
  getCard(cardUniqueId) {
    return tokenApi.get(`/cards/${cardUniqueId}`)
  }
}

// 牌組相關 API（使用 tokenApi）
export const deckAPI = {
  getDeck() {
    return tokenApi.get('/deck')
  },
  
  saveDeck(cards) {
    return tokenApi.post('/deck', { cards })
  },
  
  validateDeck(cards) {
    return tokenApi.post('/deck/validate', { cards })
  },
  
  deleteDeck() {
    return tokenApi.delete('/deck')
  }
}

// 遊戲相關 API（使用 tokenApi）
export const gameAPI = {
  initializeGame() {
    return tokenApi.post('/games/initialize')
  },

  setupGame(roomId) {
    console.log('🎴 發牌請求 Room ID:', roomId)
    return tokenApi.post(`/games/${roomId}/setup`)
  },

  getGameState(roomId) {
    console.log('🎮 查詢遊戲狀態 Room ID:', roomId)
    return tokenApi.get(`/games/${roomId}`)
  },

  playCard(roomId, cardId, zone) {
    return tokenApi.post(`/games/${roomId}/play_card`, {
      card_id: cardId,
      zone: zone
    })
  },

  attachEnergy(roomId, energyCardId, targetPokemonId) {
    return tokenApi.post(`/games/${roomId}/attach_energy`, {
      card_id: energyCardId,
      target_card_id: targetPokemonId
    })
  },

  moveCard(roomId, cardId, toZone, toPosition = null) {
    return tokenApi.post(`/games/${roomId}/move_card`, {
      card_id: cardId,
      to_zone: toZone,
      to_position: toPosition
    })
  },

  stackCard(roomId, cardId, targetCardId) {
    return tokenApi.post(`/games/${roomId}/stack_card`, {
      card_id: cardId,
      target_card_id: targetCardId
    })
  },

  updateDamage(roomId, pokemonId, damageValue) {
    return tokenApi.post(`/games/${roomId}/update_damage`, {
      pokemon_id: pokemonId,
      damage_taken: damageValue
    })
  },

  transferEnergy(roomId, energyId, fromPokemonId, toPokemonId = null, toZone = null) {
    return tokenApi.post(`/games/${roomId}/transfer_energy`, {
      energy_id: energyId,
      from_pokemon_id: fromPokemonId,
      to_pokemon_id: toPokemonId,
      to_zone: toZone
    })
  },

  endTurn(roomId) {
    return tokenApi.post(`/games/${roomId}/end_turn`)
  },

  drawCards(roomId, count) {
    return tokenApi.post(`/games/${roomId}/draw_cards`, { count })
  },

  pickFromDiscard(roomId, count) {
    return tokenApi.post(`/games/${roomId}/pick_from_discard`, { count })
  },

  takePrize(roomId) {
    return tokenApi.post(`/games/${roomId}/take_prize`)
  },

  moveStadiumCard(roomId, stadiumCardId, targetPlayerId, targetZone) {
    return tokenApi.post(`/games/${roomId}/move_stadium_card`, {
      card_id: stadiumCardId,
      player_id: targetPlayerId,
      target_zone: targetZone
    })
  },

  joinRoom(roomId) {
    return tokenApi.post(`/rooms/${roomId}/join`)
  },
  
  setPrizeCards(roomId, count) {
    return tokenApi.post(`/games/${roomId}/set_prize_cards`, { count })
  }
}

// 🔥 預設 export 使用 cookieApi（給 auth.js 使用）
export default cookieApi
