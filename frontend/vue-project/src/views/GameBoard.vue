<script setup>
import { ref, onMounted, computed, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { gameAPI } from '@/services/api'

const route = useRoute()
const gameStateId = ref(route.params.id)
const gameState = ref(null)
const loading = ref(true)
const error = ref(null)

// 選中的卡片和操作模式
const selectedCard = ref(null)
const selectedMode = ref(null)
const selectedPokemonOnField = ref(null)
const selectedEnergyCard = ref(null)
const operationMode = ref(null)
const targetPokemon = ref(null)

// 牌庫操作狀態
const selectedDeckZone = ref(null)
const drawCount = ref(1)

// 選中的競技場卡
const selectedStadiumCard = ref(null)

// 操作記錄
const actionLogs = ref([])
const isLogPanelExpanded = ref(true)
const logContainer = ref(null)

// 卡片彈出動畫
const popupCard = ref(null)
const showPopup = ref(false)

// 排序後的手牌
const sortedHandCards = computed(() => {
  if (!gameState.value?.hand) return []
  return [...gameState.value.hand].sort((a, b) => {
    return a.card_unique_id.localeCompare(b.card_unique_id)
  })
})

// ========== 操作記錄功能 ==========

const addLog = (message, type = 'info') => {
  const timestamp = new Date().toLocaleTimeString('zh-TW', { 
    hour: '2-digit', 
    minute: '2-digit',
    second: '2-digit'
  })
  
  actionLogs.value.push({
    id: Date.now(),
    message,
    type, // 'info', 'player', 'opponent', 'system'
    timestamp
  })
  
  // 自動滾動到最新
  nextTick(() => {
    if (logContainer.value) {
      logContainer.value.scrollTop = logContainer.value.scrollHeight
    }
  })
}

const toggleLogPanel = () => {
  isLogPanelExpanded.value = !isLogPanelExpanded.value
}

// ========== 卡片彈出動畫 ==========

const showCardPopup = (card, action = '使用') => {
  popupCard.value = { ...card, action }
  showPopup.value = true
  
  setTimeout(() => {
    showPopup.value = false
    popupCard.value = null
  }, 1400)
}

// ========== 按鈕禁用邏輯 ==========

const isActiveSlotFilled = computed(() => {
  return gameState.value?.active_pokemon != null
})

const isBenchFull = computed(() => {
  return gameState.value?.bench?.length >= 5
})

const canPlayToActive = computed(() => {
  if (!selectedCard.value) return false
  if (selectedCard.value.card_type !== 'Pokémon') return false
  return !isActiveSlotFilled.value
})

const canPlayToBench = computed(() => {
  if (!selectedCard.value) return false
  if (selectedCard.value.card_type !== 'Pokémon') return false
  return !isBenchFull.value
})

const canMoveToActive = computed(() => {
  if (!selectedPokemonOnField.value) return false
  if (selectedPokemonOnField.value.zone === 'active') return false
  return !isActiveSlotFilled.value
})

// ========== 取得要顯示的卡片 ==========

const getDisplayCard = (pokemon) => {
  if (!pokemon) return null
  
  if (pokemon.stacked_cards && pokemon.stacked_cards.length > 0) {
    const latestCard = pokemon.stacked_cards[0]
    return {
      name: latestCard.name,
      img_url: latestCard.img_url,
      hp: latestCard.hp || pokemon.hp,
      card_type: latestCard.card_type
    }
  }
  
  return pokemon
}

const getStackedCardsExceptLatest = (pokemon) => {
  if (!pokemon.stacked_cards || pokemon.stacked_cards.length === 0) {
    return []
  }
  return pokemon.stacked_cards.slice(1)
}

// ========== 載入遊戲狀態 ==========

const loadGameState = async () => {
  try {
    loading.value = true
    const response = await gameAPI.getGameState(gameStateId.value)
    
    gameState.value = {
      ...response.data,
      stadium_cards: response.data.stadium_cards || []
    }
    
    console.log('✅ 載入成功')
  } catch (err) {
    console.error('❌ 載入遊戲狀態失敗:', err)
    error.value = err.message
  } finally {
    loading.value = false
  }
}

// ========== 手牌操作 ==========

const handleCardClick = (card) => {
  selectedCard.value = card
  selectedMode.value = 'hand_card'
  operationMode.value = null
  selectedPokemonOnField.value = null
  selectedStadiumCard.value = null
  
  console.log('選中卡片:', card.name)
}

const playToActive = async () => {
  if (!selectedCard.value || !canPlayToActive.value) return
  
  try {
    await gameAPI.playCard(gameStateId.value, selectedCard.value.id, 'active')
    addLog(`你出牌：${selectedCard.value.name} → 戰鬥場`, 'player')
    await loadGameState()
    cancelSelection()
    alert('出牌成功!')
  } catch (err) {
    alert('出牌失敗: ' + (err.response?.data?.error || err.message))
  }
}

const playToBench = async () => {
  if (!selectedCard.value || !canPlayToBench.value) return
  
  try {
    await gameAPI.playCard(gameStateId.value, selectedCard.value.id, 'bench')
    addLog(`你出牌：${selectedCard.value.name} → 備戰區`, 'player')
    await loadGameState()
    cancelSelection()
    alert('出牌成功!')
  } catch (err) {
    alert('出牌失敗: ' + (err.response?.data?.error || err.message))
  }
}

const playStadiumCard = async () => {
  if (!selectedCard.value) return
  
  try {
    console.log('🏟️ 打出競技場卡:', selectedCard.value.name)
    showCardPopup(selectedCard.value, '打出')
    const response = await gameAPI.playCard(gameStateId.value, selectedCard.value.id, 'stadium')
    console.log('✅ 後端回應:', response.data)
    
    addLog(`你打出競技場卡：${selectedCard.value.name}`, 'player')
    await loadGameState()
    cancelSelection()
    alert('競技場卡已打出!')
  } catch (err) {
    console.error('❌ 打出失敗:', err)
    alert('打出失敗: ' + (err.response?.data?.error || err.message))
  }
}

const playSupporterCard = async () => {
  if (!selectedCard.value) return
  
  try {
    console.log('👤 使用支援者卡:', selectedCard.value.name)
    
    // 顯示彈出動畫
    showCardPopup(selectedCard.value, '使用')
    
    // 移到棄牌堆
    await gameAPI.moveCard(gameStateId.value, selectedCard.value.id, 'discard')
    
    addLog(`你使用了【${selectedCard.value.name}】`, 'player')
    await loadGameState()
    cancelSelection()
    alert('支援者卡已使用!')
  } catch (err) {
    console.error('❌ 使用失敗:', err)
    alert('使用失敗: ' + (err.response?.data?.error || err.message))
  }
}

const prepareAttachEnergy = () => {
  if (!selectedCard.value) return
  operationMode.value = 'attach'
  console.log('請選擇目標寶可夢')
}

const prepareStackCard = () => {
  if (!selectedCard.value) return
  operationMode.value = 'stack'
  console.log('請選擊場上的寶可夢來疊加卡片')
}

// ========== 場上寶可夢操作 ==========

const handleFieldPokemonClick = (pokemon) => {
  if (operationMode.value === 'attach') {
    attachEnergyToPokemon(selectedCard.value, pokemon)
    return
  }
  
  if (operationMode.value === 'stack') {
    stackCardOnPokemon(selectedCard.value, pokemon)
    return
  }
  
  if (operationMode.value === 'transfer_energy_target') {
    transferEnergyToPokemon(selectedEnergyCard.value, pokemon)
    return
  }
  
  selectedPokemonOnField.value = pokemon
  selectedMode.value = 'field_pokemon'
  operationMode.value = null
}

const attachEnergyToPokemon = async (energyCard, pokemon) => {
  try {
    await gameAPI.attachEnergy(
      gameStateId.value,
      energyCard.id,
      pokemon.id
    )
    addLog(`你附加了${energyCard.name}到${getDisplayCard(pokemon).name}`, 'player')
    await loadGameState()
    cancelSelection()
    alert('附加能量成功!')
  } catch (err) {
    alert('附加能量失敗: ' + (err.response?.data?.error || err.message))
  }
}

const stackCardOnPokemon = async (card, targetPokemon) => {
  try {
    await gameAPI.stackCard(gameStateId.value, card.id, targetPokemon.id)
    addLog(`你將${card.name}疊加到${getDisplayCard(targetPokemon).name}`, 'player')
    await loadGameState()
    cancelSelection()
    alert('疊加成功!')
  } catch (err) {
    alert('疊加失敗: ' + (err.response?.data?.error || err.message))
  }
}

const moveCardTo = async (card, toZone, toPosition = null) => {
  try {
    await gameAPI.moveCard(gameStateId.value, card.id, toZone, toPosition)
    
    const zoneNames = {
      'hand': '手牌',
      'discard': '棄牌堆',
      'deck': '牌堆',
      'active': '戰鬥場',
      'bench': '備戰區'
    }
    
    addLog(`你將${card.name}移至${zoneNames[toZone]}`, 'player')
    await loadGameState()
    cancelSelection()
    
    alert(`已移至${zoneNames[toZone]}`)
  } catch (err) {
    alert('移動失敗: ' + (err.response?.data?.error || err.message))
  }
}

const handleStadiumCardClick = (stadiumCard) => {
  selectedStadiumCard.value = stadiumCard
  selectedMode.value = 'stadium_card'
  operationMode.value = null
  console.log('選中競技場卡:', stadiumCard.name)
}

const moveStadiumCardTo = async (targetZone, targetPlayerId = null) => {
  if (!selectedStadiumCard.value) return
  
  try {
    const playerId = targetPlayerId || gameState.value.current_player_id
    
    console.log('🔄 移動競技場卡:', {
      cardId: selectedStadiumCard.value.id,
      playerId,
      targetZone
    })
    
    const response = await gameAPI.moveStadiumCard(
      gameStateId.value,
      selectedStadiumCard.value.id,
      playerId,
      targetZone
    )
    console.log('✅ 移動成功:', response.data)
    
    const zoneNames = {
      'hand': '手牌',
      'discard': '棄牌堆',
      'deck': '牌庫'
    }
    const playerName = playerId === gameState.value.current_player_id ? '你的' : '對手的'
    
    addLog(`競技場卡${selectedStadiumCard.value.name}移至${playerName}${zoneNames[targetZone]}`, 'system')
    await loadGameState()
    cancelSelection()
    
    alert(`已移至${playerName}${zoneNames[targetZone]}`)
  } catch (err) {
    console.error('❌ 移動失敗:', err)
    alert('移動失敗: ' + (err.response?.data?.error || err.message))
  }
}

// ========== 傷害操作 ==========

const adjustDamage = async (pokemon, amount) => {
  const newDamage = Math.max(0, pokemon.damage_taken + amount)
  try {
    await gameAPI.updateDamage(gameStateId.value, pokemon.id, newDamage)
    addLog(`${getDisplayCard(pokemon).name}受到${amount > 0 ? '+' : ''}${amount}傷害（總計${newDamage}）`, 'info')
    await loadGameState()
  } catch (err) {
    alert('更新傷害失敗: ' + (err.response?.data?.error || err.message))
  }
}

const updateDamage = async (pokemon) => {
  try {
    await gameAPI.updateDamage(gameStateId.value, pokemon.id, pokemon.damage_taken)
    await loadGameState()
  } catch (err) {
    alert('更新傷害失敗: ' + (err.response?.data?.error || err.message))
  }
}

// ========== 能量卡操作 ==========

const selectEnergyForTransfer = (energy, fromPokemon) => {
  selectedEnergyCard.value = { ...energy, fromPokemon }
  selectedMode.value = 'energy_transfer'
  operationMode.value = null
}

const transferEnergyToPokemon = async (energyData, toPokemon) => {
  try {
    await gameAPI.transferEnergy(
      gameStateId.value,
      energyData.id,
      energyData.fromPokemon.id,
      toPokemon.id,
      null
    )
    addLog(`${energyData.name}從${getDisplayCard(energyData.fromPokemon).name}轉移到${getDisplayCard(toPokemon).name}`, 'player')
    await loadGameState()
    cancelSelection()
    alert('能量轉移成功!')
  } catch (err) {
    alert('轉移失敗: ' + (err.response?.data?.error || err.message))
  }
}

const moveEnergyTo = async (energyData, toZone) => {
  try {
    await gameAPI.transferEnergy(
      gameStateId.value,
      energyData.id,
      energyData.fromPokemon.id,
      null,
      toZone
    )
    
    const zoneNames = {
      'hand': '手牌',
      'discard': '棄牌堆',
      'deck': '牌堆'
    }
    
    addLog(`${energyData.name}移至${zoneNames[toZone]}`, 'player')
    await loadGameState()
    cancelSelection()
    
    alert(`能量已移至${zoneNames[toZone]}`)
  } catch (err) {
    alert('移動失敗: ' + (err.response?.data?.error || err.message))
  }
}

// ========== 牌庫操作 ==========

const handleDeckClick = () => {
  selectedDeckZone.value = 'deck'
  selectedMode.value = 'deck_operation'
  drawCount.value = 1
}

const handleDiscardClick = () => {
  selectedDeckZone.value = 'discard'
  selectedMode.value = 'deck_operation'
  drawCount.value = 1
}

const handlePrizeClick = () => {
  selectedDeckZone.value = 'prize'
  selectedMode.value = 'deck_operation'
}

const drawFromDeck = async () => {
  try {
    const response = await gameAPI.drawCards(gameStateId.value, drawCount.value)
    addLog(`你抽了${drawCount.value}張牌`, 'player')
    await loadGameState()
    cancelSelection()
    alert(response.data.message)
  } catch (err) {
    alert('抽牌失敗: ' + (err.response?.data?.error || err.message))
  }
}

const pickFromDiscard = async () => {
  try {
    console.log('🔍 發送請求 - drawCount:', drawCount.value)
    
    const response = await gameAPI.pickFromDiscard(gameStateId.value, drawCount.value)
    
    const actualCount = response.data.picked_cards?.length || 0
    addLog(`你從棄牌堆撿了${actualCount}張牌`, 'player')
    await loadGameState()
    cancelSelection()
    
    alert(`從棄牌堆撿了 ${actualCount} 張牌`)
    
  } catch (err) {
    console.error('🔍 錯誤:', err)
    alert(err.response?.data?.error || err.message)
  }
}

const takePrizeCard = async () => {
  try {
    const response = await gameAPI.takePrize(gameStateId.value)
    addLog('你領取了1張獎勵卡', 'player')
    await loadGameState()
    cancelSelection()
    alert(response.data.message)
  } catch (err) {
    alert('領取失敗: ' + (err.response?.data?.error || err.message))
  }
}

// ========== 回合管理 ==========

const confirmTurn = async () => {
  try {
    await gameAPI.endTurn(gameStateId.value)
    addLog('你結束了回合', 'system')
    await loadGameState()
    alert('回合已結束,換對手操作')
  } catch (err) {
    alert('結束回合失敗: ' + (err.response?.data?.error || err.message))
  }
}

// ========== 通用操作 ==========

const cancelSelection = () => {
  selectedCard.value = null
  selectedMode.value = null
  selectedPokemonOnField.value = null
  operationMode.value = null
  selectedEnergyCard.value = null
  targetPokemon.value = null
  selectedDeckZone.value = null
  selectedStadiumCard.value = null
  drawCount.value = 1
}

onMounted(() => {
  loadGameState()
  addLog('遊戲開始', 'system')
})
</script>

<template>
  <div class="game-board">
    <div v-if="loading" class="loading">
      載入遊戲中...
    </div>
    
    <div v-else-if="error" class="error">
      <h2>載入失敗</h2>
      <p>{{ error }}</p>
      <button @click="loadGameState">重試</button>
    </div>
    
    <div v-else-if="gameState" class="game-container">
      <!-- 結束回合按鈕 -->
      <div class="turn-controls">
        <button @click="confirmTurn" class="confirm-turn-btn">
          ✓ 確認完成
        </button>
      </div>

      <!-- 操作記錄面板 -->
      <div class="action-log-panel" :class="{ 'collapsed': !isLogPanelExpanded }">
        <div v-if="isLogPanelExpanded" class="log-panel-content">
          <div class="log-panel-header">
            <h3>📜 操作記錄</h3>
            <button @click="toggleLogPanel" class="toggle-btn">−</button>
          </div>
          <div class="log-panel-body" ref="logContainer">
            <div 
              v-for="log in actionLogs" 
              :key="log.id"
              class="log-item"
              :class="'log-' + log.type"
            >
              <span class="log-time">{{ log.timestamp }}</span>
              <span class="log-message">{{ log.message }}</span>
            </div>
          </div>
        </div>
        
        <div v-else class="log-panel-tab" @click="toggleLogPanel">
          <span class="tab-text">📜 記錄</span>
        </div>
      </div>

      <!-- 卡片彈出動畫 -->
      <transition name="popup-fade">
        <div v-if="showPopup && popupCard" class="card-popup-overlay">
          <div class="card-popup">
            <div class="popup-action-label">{{ popupCard.action }}</div>
            <img :src="popupCard.img_url" :alt="popupCard.name">
            <h3>{{ popupCard.name }}</h3>
          </div>
        </div>
      </transition>

      <!-- 遊戲資訊 -->
      <header class="game-header">
        <div class="game-info">
          <h2>遊戲 #{{ gameStateId }}</h2>
          <p>回合: {{ gameState.round_number || 0 }}</p>
        </div>
      </header>

      <!-- 對手區域 (鏡像 - 上下顛倒) -->
      <section class="opponent-area">
        <h3>🔴 對手</h3>
        
        <!-- 對手手牌 (在最上方，顯示卡背) -->
        <div class="opponent-hand-zone">
          <h4>手牌 ({{ sortedHandCards.length }})</h4>
          <div class="opponent-hand-cards">
            <div 
              v-for="(card, index) in sortedHandCards" 
              :key="'opp-hand-' + index"
              class="card-back"
            >
            </div>
          </div>
        </div>

        <div class="field-layout opponent-layout">
          
          <!-- 左側:戰鬥場 + 備戰區 (順序相反) -->
          <div class="left-side">
        <!-- 戰鬥場 (在上) -->
            <div class="battle-zone">
              <h4>戰鬥場</h4>
              <div 
                v-if="gameState.active_pokemon" 
                class="pokemon-card opponent-card"
              >
                <img :src="getDisplayCard(gameState.active_pokemon).img_url" :alt="getDisplayCard(gameState.active_pokemon).name">
                <p class="pokemon-name">{{ getDisplayCard(gameState.active_pokemon).name }}</p>
                <p class="pokemon-hp">HP: {{ gameState.active_pokemon.hp - gameState.active_pokemon.damage_taken }}/{{ getDisplayCard(gameState.active_pokemon).hp }}</p>
                
                <!-- 傷害顯示 -->
                <div class="damage-display">
                  傷害: {{ gameState.active_pokemon.damage_taken }}
                </div>
                
                <!-- 附加的能量卡 -->
                <div v-if="gameState.active_pokemon.attached_energies?.length > 0" class="energy-container">
                  <div 
                    v-for="energy in gameState.active_pokemon.attached_energies" 
                    :key="'opp-energy-' + energy.id"
                    class="energy-mini"
                    :title="energy.name"
                  >
                    <img :src="energy.img_url" :alt="energy.name">
                  </div>
                </div>

                <!-- 疊加的卡片 -->
                <div v-if="gameState.active_pokemon.stacked_cards?.length > 0" class="stacked-cards-container">
                  <div 
                    class="stacked-mini-card"
                    :title="gameState.active_pokemon.name"
                  >
                    <img :src="gameState.active_pokemon.img_url" :alt="gameState.active_pokemon.name">
                  </div>
                  
                  <div 
                    v-for="card in getStackedCardsExceptLatest(gameState.active_pokemon)" 
                    :key="'opp-stack-' + card.id"
                    class="stacked-mini-card"
                    :title="card.name"
                  >
                    <img :src="card.img_url" :alt="card.name">
                  </div>
                </div>
              </div>
              <div v-else class="empty-slot">
                無寶可夢
              </div>
            </div>
            <!-- 備戰區 (在下) -->
            <div class="bench-zone">
              <h4>備戰區</h4>
              <div class="bench-grid">
                <div 
                  v-for="pokemon in (gameState.bench || [])" 
                  :key="'opp-bench-' + pokemon.id"
                  class="pokemon-card small opponent-card"
                >
                  <img :src="getDisplayCard(pokemon).img_url" :alt="getDisplayCard(pokemon).name">
                  <p class="pokemon-name">{{ getDisplayCard(pokemon).name }}</p>
                  <p class="pokemon-hp-small">{{ pokemon.hp - pokemon.damage_taken }}/{{ getDisplayCard(pokemon).hp }}</p>
                  
                  <!-- 傷害顯示(小版) -->
                  <div class="damage-display-small">
                    傷害: {{ pokemon.damage_taken }}
                  </div>
                  
                  <!-- 附加的能量卡 -->
                  <div v-if="pokemon.attached_energies?.length > 0" class="energy-container-small">
                    <div 
                      v-for="energy in pokemon.attached_energies" 
                      :key="'opp-bench-energy-' + energy.id"
                      class="energy-mini-small"
                      :title="energy.name"
                    >
                      <img :src="energy.img_url" :alt="energy.name">
                    </div>
                  </div>

                  <!-- 疊加的卡片(小版) -->
                  <div v-if="pokemon.stacked_cards?.length > 0" class="stacked-cards-container-small">
                    <div class="stacked-mini-card-small" :title="pokemon.name">
                      <img :src="pokemon.img_url" :alt="pokemon.name">
                    </div>
                    <div 
                      v-for="card in getStackedCardsExceptLatest(pokemon)" 
                      :key="'opp-bench-stack-' + card.id"
                      class="stacked-mini-card-small"
                      :title="card.name"
                    >
                      <img :src="card.img_url" :alt="card.name">
                    </div>
                  </div>
                </div>
                
                <!-- 空位 -->
                <div 
                  v-for="i in (5 - (gameState.bench?.length || 0))" 
                  :key="'opp-empty-' + i"
                  class="empty-slot small"
                >
                  空位 {{ (gameState.bench?.length || 0) + i }}
                </div>
              </div>
            </div>


          </div>

          <!-- 右側:牌庫 + 棄牌堆 + 獎勵卡 (順序相反) -->
          <div class="right-side opponent-right">
            <div class="deck-area">
              <!-- 牌庫 -->
              <div class="deck-item">
                <h4>牌庫</h4>
                <div class="deck-stack">
                  <span class="deck-count">{{ gameState.deck_count || 0 }}</span>
                </div>
              </div>
              
              <!-- 棄牌堆 -->
              <div class="deck-item">
                <h4>棄牌堆</h4>
                <div class="deck-stack discard">
                  <span class="deck-count">{{ gameState.discard_count || 0 }}</span>
                </div>
              </div>
              
              <!-- 獎勵卡 -->
              <div class="deck-item">
                <h4>獎勵卡</h4>
                <div class="deck-stack prize">
                  <span class="deck-count">{{ gameState.prize_count || 0 }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- 競技場卡區域 -->
      <section class="stadium-area">
        <h3>🏟️ 競技場</h3>
        <div class="stadium-cards-container">
          <template v-if="gameState.stadium_cards && Array.isArray(gameState.stadium_cards) && gameState.stadium_cards.length > 0">
            <div 
              v-for="(stadiumCard, index) in gameState.stadium_cards" 
              :key="stadiumCard.id || index"
              class="stadium-card"
              @click="handleStadiumCardClick(stadiumCard)"
            >
              <img 
                :src="stadiumCard.img_url || 'https://via.placeholder.com/150x210?text=No+Image'" 
                :alt="stadiumCard.name || '未知卡片'"
              >
              <p class="stadium-card-name">{{ stadiumCard.name || '未知' }}</p>
              <p class="stadium-card-owner">{{ stadiumCard.owner_name || '未知玩家' }}</p>
            </div>
          </template>
          
          <div v-else class="empty-stadium">
            尚無競技場卡
          </div>
        </div>
      </section>

      <!-- 玩家區域 -->
      <section class="player-area">
        <h3>🔵 你的場地</h3>
        
        <div class="field-layout">
          <!-- 左側:戰鬥場 + 備戰區 -->
          <div class="left-side">
            <!-- 戰鬥場 -->
            <div class="battle-zone">
              <h4>戰鬥場</h4>
              <div 
                v-if="gameState.active_pokemon" 
                class="pokemon-card"
                :class="{ 
                  'target-highlight': operationMode === 'attach' || operationMode === 'stack' || operationMode === 'transfer_energy_target' 
                }"
                @click="handleFieldPokemonClick(gameState.active_pokemon)"
              >
                <img :src="getDisplayCard(gameState.active_pokemon).img_url" :alt="getDisplayCard(gameState.active_pokemon).name">
                <p class="pokemon-name">{{ getDisplayCard(gameState.active_pokemon).name }}</p>
                <p class="pokemon-hp">HP: {{ gameState.active_pokemon.hp - gameState.active_pokemon.damage_taken }}/{{ getDisplayCard(gameState.active_pokemon).hp }}</p>
                
                <!-- 傷害調整 -->
                <div class="damage-controls">
                  <button @click.stop="adjustDamage(gameState.active_pokemon, -10)" class="damage-btn">-10</button>
                  <input 
                    type="number" 
                    v-model.number="gameState.active_pokemon.damage_taken" 
                    @change="updateDamage(gameState.active_pokemon)"
                    @click.stop
                    class="damage-input"
                    min="0"
                  >
                  <button @click.stop="adjustDamage(gameState.active_pokemon, 10)" class="damage-btn">+10</button>
                </div>
                
                <!-- 附加的能量卡 -->
                <div v-if="gameState.active_pokemon.attached_energies?.length > 0" class="energy-container">
                  <div 
                    v-for="energy in gameState.active_pokemon.attached_energies" 
                    :key="energy.id"
                    class="energy-mini"
                    :title="energy.name"
                    @click.stop="selectEnergyForTransfer(energy, gameState.active_pokemon)"
                  >
                    <img :src="energy.img_url" :alt="energy.name">
                  </div>
                </div>

                <!-- 疊加的卡片 -->
                <div v-if="gameState.active_pokemon.stacked_cards?.length > 0" class="stacked-cards-container">
                  <div 
                    class="stacked-mini-card"
                    :title="gameState.active_pokemon.name"
                  >
                    <img :src="gameState.active_pokemon.img_url" :alt="gameState.active_pokemon.name">
                  </div>
                  
                  <div 
                    v-for="card in getStackedCardsExceptLatest(gameState.active_pokemon)" 
                    :key="card.id"
                    class="stacked-mini-card"
                    :title="card.name"
                  >
                    <img :src="card.img_url" :alt="card.name">
                  </div>
                </div>
              </div>
              <div v-else class="empty-slot">
                無寶可夢
              </div>
            </div>

            <!-- 備戰區 -->
            <div class="bench-zone">
              <h4>備戰區</h4>
              <div class="bench-grid">
                <div 
                  v-for="pokemon in (gameState.bench || [])" 
                  :key="pokemon.id"
                  class="pokemon-card small"
                  :class="{ 
                    'target-highlight': operationMode === 'attach' || operationMode === 'stack' || operationMode === 'transfer_energy_target' 
                  }"
                  @click="handleFieldPokemonClick(pokemon)"
                >
                  <img :src="getDisplayCard(pokemon).img_url" :alt="getDisplayCard(pokemon).name">
                  <p class="pokemon-name">{{ getDisplayCard(pokemon).name }}</p>
                  <p class="pokemon-hp-small">{{ pokemon.hp - pokemon.damage_taken }}/{{ getDisplayCard(pokemon).hp }}</p>
                  
                  <!-- 傷害調整(小版) -->
                  <div class="damage-controls-small">
                    <button @click.stop="adjustDamage(pokemon, -10)" class="damage-btn-small">-</button>
                    <input 
                      type="number" 
                      v-model.number="pokemon.damage_taken" 
                      @change="updateDamage(pokemon)"
                      @click.stop
                      class="damage-input-small"
                      min="0"
                    >
                    <button @click.stop="adjustDamage(pokemon, 10)" class="damage-btn-small">+</button>
                  </div>
                  
                  <!-- 附加的能量卡 -->
                  <div v-if="pokemon.attached_energies?.length > 0" class="energy-container-small">
                    <div 
                      v-for="energy in pokemon.attached_energies" 
                      :key="energy.id"
                      class="energy-mini-small"
                      :title="energy.name"
                      @click.stop="selectEnergyForTransfer(energy, pokemon)"
                    >
                      <img :src="energy.img_url" :alt="energy.name">
                    </div>
                  </div>

                  <!-- 疊加的卡片(小版) -->
                  <div v-if="pokemon.stacked_cards?.length > 0" class="stacked-cards-container-small">
                    <div class="stacked-mini-card-small" :title="pokemon.name">
                      <img :src="pokemon.img_url" :alt="pokemon.name">
                    </div>
                    <div 
                      v-for="card in getStackedCardsExceptLatest(pokemon)" 
                      :key="card.id"
                      class="stacked-mini-card-small"
                      :title="card.name"
                    >
                      <img :src="card.img_url" :alt="card.name">
                    </div>
                  </div>
                </div>
                
                <!-- 空位 -->
                <div 
                  v-for="i in (5 - (gameState.bench?.length || 0))" 
                  :key="'empty-' + i"
                  class="empty-slot small"
                >
                  空位 {{ (gameState.bench?.length || 0) + i }}
                </div>
              </div>
            </div>
          </div>

          <!-- 右側:獎勵卡 + 棄牌堆 + 牌庫 -->
          <div class="right-side">
            <div class="deck-area">
              <!-- 獎勵卡 -->
              <div class="deck-item">
                <h4>獎勵卡</h4>
                <div 
                  class="deck-stack prize"
                  :class="{ 'clickable': (gameState.prize_count || 0) > 0 }"
                  @click="(gameState.prize_count || 0) > 0 && handlePrizeClick()"
                >
                  <span class="deck-count">{{ gameState.prize_count || 0 }}</span>
                </div>
              </div>
              
              <!-- 棄牌堆 -->
              <div class="deck-item">
                <h4>棄牌堆</h4>
                <div 
                  class="deck-stack discard"
                  :class="{ 'clickable': (gameState.discard_count || 0) > 0 }"
                  @click="(gameState.discard_count || 0) > 0 && handleDiscardClick()"
                >
                  <span class="deck-count">{{ gameState.discard_count || 0 }}</span>
                </div>
              </div>
              
              <!-- 牌庫 -->
              <div class="deck-item">
                <h4>牌庫</h4>
                <div 
                  class="deck-stack"
                  :class="{ 'clickable': (gameState.deck_count || 0) > 0 }"
                  @click="(gameState.deck_count || 0) > 0 && handleDeckClick()"
                >
                  <span class="deck-count">{{ gameState.deck_count || 0 }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 手牌 -->
        <div class="hand-zone">
          <h4>手牌 ({{ sortedHandCards.length }})</h4>
          <div class="hand-cards">
            <div 
              v-for="card in sortedHandCards" 
              :key="card.id"
              class="hand-card"
              :class="{ 'selected': selectedCard?.id === card.id }"
              @click="handleCardClick(card)"
            >
              <img :src="card.img_url" :alt="card.name">
              <div class="card-info">
                <p class="card-name">{{ card.name }}</p>
                <p class="card-type">{{ card.card_type }}</p>
                <p v-if="card.hp" class="card-hp">HP: {{ card.hp }}</p>
                <p v-if="card.stage" class="card-stage">{{ card.stage }}</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- 操作選單:手牌 -->
      <div v-if="selectedMode === 'hand_card' && selectedCard" class="action-menu">
        <div class="action-menu-header">
          <h3>{{ selectedCard.name }}</h3>
          <button @click="cancelSelection" class="close-btn">✕</button>
        </div>
        <div class="action-buttons">
          <button 
            v-if="selectedCard.card_type === 'Pokémon'" 
            @click="playToActive"
            :disabled="!canPlayToActive"
            class="action-btn primary"
            :class="{ 'disabled': !canPlayToActive }"
            :title="!canPlayToActive ? '戰鬥場已有牌' : ''"
          >
            放到戰鬥場
          </button>
          <button 
            v-if="selectedCard.card_type === 'Pokémon'" 
            @click="playToBench"
            :disabled="!canPlayToBench"
            class="action-btn"
            :class="{ 'disabled': !canPlayToBench }"
            :title="!canPlayToBench ? '備戰區已滿(5張)' : ''"
          >
            放到備戰區
          </button>
          <button 
            v-if="selectedCard.card_type && selectedCard.card_type.includes('能量卡')" 
            @click="prepareAttachEnergy"
            class="action-btn primary"
          >
            附加能量
          </button>
          <button 
            @click="playStadiumCard"
            class="action-btn primary"
          >
            🏟️ 打出到競技場
          </button>
          <button 
            @click="playSupporterCard"
            class="action-btn primary"
          >
            👤 使用支援者卡
          </button>
          <button 
            @click="prepareStackCard"
            class="action-btn"
          >
            疊加到場上寶可夢
          </button>
          <button 
            @click="moveCardTo(selectedCard, 'discard')"
            class="action-btn"
          >
            丟到棄牌堆
          </button>
          <button 
            @click="moveCardTo(selectedCard, 'deck')"
            class="action-btn"
          >
            放回牌堆
          </button>
          <button @click="cancelSelection" class="action-btn cancel">
            取消
          </button>
        </div>
        <p v-if="operationMode === 'attach'" class="hint">
          請點擊場上的寶可夢來附加能量
        </p>
        <p v-if="operationMode === 'stack'" class="hint">
          請點擊場上的寶可夢來疊加卡片
        </p>
      </div>

      <!-- 操作選單:場上寶可夢 -->
      <div v-if="selectedMode === 'field_pokemon' && selectedPokemonOnField" class="action-menu">
        <div class="action-menu-header">
          <h3>{{ getDisplayCard(selectedPokemonOnField).name }}</h3>
          <button @click="cancelSelection" class="close-btn">✕</button>
        </div>
        <div class="action-buttons">
          <button 
            @click="moveCardTo(selectedPokemonOnField, 'hand')"
            class="action-btn"
          >
            移至手牌
          </button>
          <button 
            @click="moveCardTo(selectedPokemonOnField, 'discard')"
            class="action-btn"
          >
            移至棄牌堆
          </button>
          <button 
            @click="moveCardTo(selectedPokemonOnField, 'deck')"
            class="action-btn"
          >
            移回牌堆
          </button>
          <button 
            v-if="selectedPokemonOnField.zone !== 'active'"
            @click="moveCardTo(selectedPokemonOnField, 'active')"
            :disabled="!canMoveToActive"
            class="action-btn primary"
            :class="{ 'disabled': !canMoveToActive }"
            :title="!canMoveToActive ? '戰鬥場已有牌' : ''"
          >
            移到戰鬥場
          </button>
          <button 
            v-if="selectedPokemonOnField.zone !== 'bench'"
            @click="moveCardTo(selectedPokemonOnField, 'bench')"
            class="action-btn"
          >
            移到備戰區
          </button>
          <button @click="cancelSelection" class="action-btn cancel">
            取消
          </button>
        </div>
      </div>

      <!-- 操作選單:競技場卡 -->
      <div v-if="selectedMode === 'stadium_card' && selectedStadiumCard" class="action-menu">
        <div class="action-menu-header">
          <h3>{{ selectedStadiumCard.name || '未知卡片' }}</h3>
          <button @click="cancelSelection" class="close-btn">✕</button>
        </div>
        <div class="action-buttons">
          <button 
            @click="moveStadiumCardTo('hand')"
            class="action-btn"
          >
            📥 移到我的手牌
          </button>
          <button 
            @click="moveStadiumCardTo('discard')"
            class="action-btn"
          >
            🗑️ 移到我的棄牌堆
          </button>
          <button 
            @click="moveStadiumCardTo('deck')"
            class="action-btn"
          >
            📚 移回我的牌庫
          </button>
          
          <template v-if="gameState.opponent_id">
            <button 
              @click="moveStadiumCardTo('hand', gameState.opponent_id)"
              class="action-btn"
            >
              📤 移到對手的手牌
            </button>
            <button 
              @click="moveStadiumCardTo('discard', gameState.opponent_id)"
              class="action-btn"
            >
              🗑️ 移到對手的棄牌堆
            </button>
            <button 
              @click="moveStadiumCardTo('deck', gameState.opponent_id)"
              class="action-btn"
            >
              📚 移回對手的牌庫
            </button>
          </template>
          
          <button @click="cancelSelection" class="action-btn cancel">
            取消
          </button>
        </div>
      </div>

      <!-- 操作選單:能量轉移 -->
      <div v-if="selectedMode === 'energy_transfer' && selectedEnergyCard" class="action-menu">
        <div class="action-menu-header">
          <h3>{{ selectedEnergyCard.name }}</h3>
          <button @click="cancelSelection" class="close-btn">✕</button>
        </div>
        <div class="action-buttons">
          <button 
            @click="operationMode = 'transfer_energy_target'"
            class="action-btn primary"
          >
            轉移到寶可夢
          </button>
          <button 
            @click="moveEnergyTo(selectedEnergyCard, 'hand')"
            class="action-btn"
          >
            移到手牌
          </button>
          <button 
            @click="moveEnergyTo(selectedEnergyCard, 'discard')"
            class="action-btn"
          >
            移到棄牌堆
          </button>
          <button 
            @click="moveEnergyTo(selectedEnergyCard, 'deck')"
            class="action-btn"
          >
            移回牌堆
          </button>
          <button @click="cancelSelection" class="action-btn cancel">
            取消
          </button>
        </div>
        <p v-if="operationMode === 'transfer_energy_target'" class="hint">
          請點擊目標寶可夢
        </p>
      </div>

      <!-- 操作選單:牌庫/棄牌堆/獎勵卡 -->
      <div v-if="selectedMode === 'deck_operation' && selectedDeckZone" class="action-menu">
        <div class="action-menu-header">
          <h3>
            {{ selectedDeckZone === 'deck' ? '牌庫' : selectedDeckZone === 'discard' ? '棄牌堆' : '獎勵卡' }}
          </h3>
          <button @click="cancelSelection" class="close-btn">✕</button>
        </div>
        
        <!-- 牌庫操作 -->
        <div v-if="selectedDeckZone === 'deck'" class="action-content">
          <div class="draw-count-selector">
            <label>抽牌數量:</label>
            <div class="count-controls">
              <button @click="drawCount = Math.max(1, drawCount - 1)" class="count-btn">-</button>
              <input 
                type="number" 
                v-model.number="drawCount" 
                min="1" 
                max="10"
                class="count-input"
              >
              <button @click="drawCount = Math.min(10, drawCount + 1)" class="count-btn">+</button>
            </div>
          </div>
          <div class="action-buttons">
            <button @click="drawFromDeck" class="action-btn primary">
              抽 {{ drawCount }} 張牌
            </button>
            <button @click="cancelSelection" class="action-btn cancel">
              取消
            </button>
          </div>
        </div>

        <!-- 棄牌堆操作 -->
        <div v-if="selectedDeckZone === 'discard'" class="action-content">
          <div class="draw-count-selector">
            <label>撿牌數量:</label>
            <div class="count-controls">
              <button @click="drawCount = Math.max(1, drawCount - 1)" class="count-btn">-</button>
              <input 
                type="number" 
                v-model.number="drawCount" 
                min="1" 
                max="10"
                class="count-input"
              >
              <button @click="drawCount = Math.min(10, drawCount + 1)" class="count-btn">+</button>
            </div>
          </div>
          <div class="action-buttons">
            <button @click="pickFromDiscard" class="action-btn primary">
              撿 {{ drawCount }} 張牌
            </button>
            <button @click="cancelSelection" class="action-btn cancel">
              取消
            </button>
          </div>
        </div>

        <!-- 獎勵卡操作 -->
        <div v-if="selectedDeckZone === 'prize'" class="action-content">
          <p class="info-text">領取一張獎勵卡到手牌</p>
          <div class="action-buttons">
            <button @click="takePrizeCard" class="action-btn primary">
              領取獎勵卡
            </button>
            <button @click="cancelSelection" class="action-btn cancel">
              取消
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
* {
  box-sizing: border-box;
}

/* ========== 主要背景 (深藍色) ========== */
.game-board {
  min-height: 100vh;
  background: linear-gradient(180deg, #1a365d 0%, #2d3748 100%);
  color: white;
  padding: 20px;
  overflow-x: hidden;
  width: 100%;
  max-width: 100vw;
}

.loading, .error {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  font-size: 24px;
}

.game-container {
  max-width: 1600px;
  margin: 0 auto;
  padding-bottom: 200px;
  width: 100%;
}

/* ========== 結束回合按鈕 ========== */
.turn-controls {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 100;
}

.confirm-turn-btn {
  padding: 12px 24px;
  background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(72, 187, 120, 0.4);
  transition: all 0.2s;
}

.confirm-turn-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(72, 187, 120, 0.5);
}

/* ========== 操作記錄面板 ========== */
.action-log-panel {
  position: fixed;
  top: 80px;
  right: 20px;
  bottom: 20px;
  width: 280px;
  z-index: 90;
  transition: all 0.3s ease;
}

.action-log-panel.collapsed {
  width: 50px;
}

.log-panel-content {
  background: rgba(26, 32, 44, 0.95);
  border-radius: 12px;
  height: 100%;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
  border: 2px solid rgba(251, 191, 36, 0.3);
}

.log-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  border-bottom: 2px solid rgba(255, 255, 255, 0.1);
}

.log-panel-header h3 {
  margin: 0;
  font-size: 16px;
  color: #fbbf24;
}

.toggle-btn {
  width: 28px;
  height: 28px;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  border-radius: 4px;
  color: white;
  cursor: pointer;
  font-size: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.toggle-btn:hover {
  background: rgba(255, 255, 255, 0.2);
}

.log-panel-body {
  flex: 1;
  overflow-y: auto;
  padding: 10px;
  scrollbar-width: thin;
  scrollbar-color: rgba(251, 191, 36, 0.5) rgba(255, 255, 255, 0.1);
}

.log-panel-body::-webkit-scrollbar {
  width: 6px;
}

.log-panel-body::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 3px;
}

.log-panel-body::-webkit-scrollbar-thumb {
  background: rgba(251, 191, 36, 0.5);
  border-radius: 3px;
}

.log-item {
  padding: 8px 10px;
  margin-bottom: 6px;
  border-radius: 6px;
  font-size: 13px;
  line-height: 1.4;
  background: rgba(255, 255, 255, 0.05);
  border-left: 3px solid transparent;
}

.log-item.log-player {
  border-left-color: #60a5fa;
  background: rgba(96, 165, 250, 0.1);
}

.log-item.log-opponent {
  border-left-color: #ff6b6b;
  background: rgba(255, 107, 107, 0.1);
}

.log-item.log-system {
  border-left-color: #fbbf24;
  background: rgba(251, 191, 36, 0.1);
}

.log-time {
  display: block;
  font-size: 10px;
  color: rgba(255, 255, 255, 0.5);
  margin-bottom: 2px;
}

.log-message {
  display: block;
  color: rgba(255, 255, 255, 0.9);
}

/* 收合狀態的標籤 */
.log-panel-tab {
  background: rgba(26, 32, 44, 0.95);
  width: 50px;
  height: 120px;
  border-radius: 12px 0 0 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  box-shadow: -4px 0 12px rgba(0, 0, 0, 0.3);
  border: 2px solid rgba(251, 191, 36, 0.3);
  border-right: none;
  transition: all 0.2s;
}

.log-panel-tab:hover {
  background: rgba(26, 32, 44, 1);
  box-shadow: -6px 0 16px rgba(0, 0, 0, 0.4);
}

.tab-text {
  writing-mode: vertical-rl;
  text-orientation: mixed;
  color: #fbbf24;
  font-size: 14px;
  font-weight: bold;
  letter-spacing: 2px;
}

/* ========== 卡片彈出動畫 ========== */
.card-popup-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}

.card-popup {
  background: white;
  padding: 20px;
  border-radius: 16px;
  text-align: center;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5);
  max-width: 90%;
  position: relative;
}

.popup-action-label {
  position: absolute;
  top: -15px;
  left: 50%;
  transform: translateX(-50%);
  background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%);
  color: white;
  padding: 8px 24px;
  border-radius: 20px;
  font-weight: bold;
  font-size: 16px;
  box-shadow: 0 4px 12px rgba(251, 191, 36, 0.4);
}

.card-popup img {
  width: 300px;
  max-width: 100%;
  border-radius: 12px;
  margin-bottom: 15px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.card-popup h3 {
  color: #1a365d;
  margin: 0;
  font-size: 24px;
}

.popup-fade-enter-active,
.popup-fade-leave-active {
  transition: opacity 0.3s ease;
}

.popup-fade-enter-from,
.popup-fade-leave-to {
  opacity: 0;
}

/* ========== 遊戲資訊 ========== */
.game-header {
  background: rgba(255, 255, 255, 0.1);
  padding: 20px;
  border-radius: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
}

/* ========== 對手區域 ========== */
.opponent-area {
  background: rgba(220, 53, 69, 0.15);
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 20px;
  border: 3px solid rgba(220, 53, 69, 0.4);
}

.opponent-area h3 {
  color: #ff6b6b;
  margin-bottom: 15px;
  text-align: center;
  font-size: 20px;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
}

/* 對手區域特殊佈局 (鏡像) */
.opponent-layout {
  flex-direction: row;
}

.opponent-layout .left-side {
  flex-direction: column-reverse;
}

.opponent-right .deck-area {
  flex-direction: column-reverse;
}

/* 對手手牌區 (在最上方) */
.opponent-hand-zone {
  margin-bottom: 20px;
  padding-bottom: 20px;
  border-bottom: 2px solid rgba(255, 255, 255, 0.2);
}

.opponent-hand-cards {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  padding: 10px 0;
  -webkit-overflow-scrolling: touch;
  justify-content: center;
}

.card-back {
  width: 140px;
  height: 196px;
  background: linear-gradient(135deg, #2b5797 0%, #1e3a8a 100%);
  border: 3px solid #3b82f6;
  border-radius: 12px;
  position: relative;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  flex-shrink: 0;
}

.card-back::after {
  content: '?';
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 64px;
  color: rgba(255, 255, 255, 0.3);
  font-weight: bold;
}

/* 對手的卡片不能點擊 */
.opponent-card {
  cursor: default !important;
  pointer-events: none;
}

/* 對手的傷害顯示 (不可編輯) */
.damage-display {
  margin-top: 8px;
  padding: 8px;
  background: #f7fafc;
  border-radius: 6px;
  text-align: center;
  font-weight: bold;
  color: #e53e3e;
  font-size: 14px;
}

.damage-display-small {
  margin-top: 5px;
  padding: 5px;
  background: #f7fafc;
  border-radius: 4px;
  text-align: center;
  font-weight: bold;
  color: #e53e3e;
  font-size: 11px;
}

/* ========== 競技場卡區域 ========== */
.stadium-area {
  background: linear-gradient(135deg, rgba(251, 191, 36, 0.15) 0%, rgba(245, 158, 11, 0.15) 100%);
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 20px;
  border: 2px solid rgba(251, 191, 36, 0.3);
}

.stadium-area h3 {
  color: #fbbf24;
  margin-bottom: 15px;
  font-size: 20px;
  text-align: center;
}

.stadium-cards-container {
  display: flex;
  gap: 15px;
  overflow-x: auto;
  padding: 10px;
  min-height: 200px;
  align-items: center;
  justify-content: center;
  -webkit-overflow-scrolling: touch;
}

.stadium-card {
  background: white;
  color: black;
  padding: 12px;
  border-radius: 10px;
  width: 150px;
  flex-shrink: 0;
  cursor: pointer;
  transition: all 0.3s;
  border: 3px solid transparent;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.stadium-card:hover {
  transform: translateY(-10px) scale(1.05);
  border-color: #fbbf24;
  box-shadow: 0 8px 20px rgba(251, 191, 36, 0.4);
}

.stadium-card img {
  width: 100%;
  height: 210px;
  object-fit: cover;
  border-radius: 8px;
  margin-bottom: 8px;
}

.stadium-card-name {
  font-weight: bold;
  font-size: 13px;
  margin-bottom: 4px;
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.stadium-card-owner {
  font-size: 11px;
  color: #666;
  text-align: center;
}

.empty-stadium {
  width: 100%;
  text-align: center;
  padding: 40px;
  color: rgba(255, 255, 255, 0.5);
  font-size: 18px;
  border: 2px dashed rgba(255, 255, 255, 0.2);
  border-radius: 8px;
}

/* ========== 玩家區域 ========== */
.player-area {
  background: rgba(59, 130, 246, 0.15);
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 20px;
  border: 3px solid rgba(59, 130, 246, 0.4);
}

.player-area h3 {
  color: #60a5fa;
  margin-bottom: 15px;
  text-align: center;
  font-size: 20px;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
}

.field-layout {
  display: flex;
  gap: 20px;
  margin-top: 15px;
}

.left-side {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.right-side {
  width: 200px;
  flex-shrink: 0;
}

/* ========== 戰鬥場 ========== */
.battle-zone {
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
}

h4 {
  margin-bottom: 15px;
  font-size: 18px;
  color: #fbbf24;
  text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.5);
  text-align: center;
  width: 100%;
}

.pokemon-card {
  background: white;
  color: black;
  padding: 15px;
  border-radius: 12px;
  width: 220px;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.pokemon-card:hover {
  transform: scale(1.05);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
}

.pokemon-card.target-highlight {
  border: 3px solid #fbbf24;
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(251, 191, 36, 0.7); }
  50% { box-shadow: 0 0 0 10px rgba(251, 191, 36, 0); }
}

.pokemon-card img {
  width: 100%;
  border-radius: 8px;
  margin-bottom: 10px;
}

.pokemon-name {
  font-weight: bold;
  margin-bottom: 5px;
  font-size: 14px;
}

.pokemon-hp {
  color: #e53e3e;
  font-weight: bold;
  margin-bottom: 8px;
}

/* ========== 傷害控制 ========== */
.damage-controls {
  display: flex;
  gap: 5px;
  align-items: center;
  margin-top: 8px;
  padding: 8px;
  background: #f7fafc;
  border-radius: 6px;
}

.damage-btn {
  width: 35px;
  height: 28px;
  background: #4299e1;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
  transition: background 0.2s;
}

.damage-btn:hover {
  background: #3182ce;
}

.damage-input {
  width: 50px;
  text-align: center;
  border: 1px solid #cbd5e0;
  border-radius: 4px;
  padding: 4px;
  font-size: 14px;
}

/* ========== 能量卡容器 ========== */
.energy-container {
  display: flex;
  gap: 4px;
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid #e2e8f0;
  flex-wrap: wrap;
  justify-content: center;
}

.energy-mini {
  width: 40px;
  height: 56px;
  border-radius: 4px;
  overflow: hidden;
  border: 1px solid #cbd5e0;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
  cursor: pointer;
  transition: transform 0.2s;
}

.energy-mini:hover {
  transform: scale(1.8);
  z-index: 10;
  box-shadow: 0 0 8px rgba(251, 191, 36, 0.6);
}

.energy-mini img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  margin: 0;
}

/* ========== 疊加卡片容器 ========== */
.stacked-cards-container {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid #e2e8f0;
}

.stacked-cards-container > div:not(.stacked-label) {
  display: inline-block;
  margin-right: 4px;
}

.stacked-mini-card {
  width: 45px;
  height: 63px;
  border-radius: 4px;
  overflow: hidden;
  border: 1px solid #cbd5e0;
  opacity: 0.8;
  transition: all 0.2s;
  cursor: help;
  display: inline-block;
  vertical-align: top;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
}

.stacked-mini-card:hover {
  opacity: 1;
  transform: scale(2.5);
  z-index: 999;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.4);
}

.stacked-mini-card img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

/* ========== 備戰區 ========== */
.bench-zone {
  flex: 1;
  min-width: 0;
}

.bench-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 10px;
  width: 100%;
}

.pokemon-card.small {
  width: 100%;
  padding: 10px;
}

.pokemon-hp-small {
  font-size: 11px;
  color: #e53e3e;
  font-weight: bold;
  margin: 5px 0;
}

.damage-controls-small {
  display: flex;
  gap: 3px;
  align-items: center;
  margin-top: 5px;
  padding: 5px;
  background: #f7fafc;
  border-radius: 4px;
}

.damage-btn-small {
  width: 25px;
  height: 22px;
  background: #4299e1;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  font-weight: bold;
  font-size: 12px;
}

.damage-input-small {
  width: 40px;
  text-align: center;
  border: 1px solid #cbd5e0;
  border-radius: 3px;
  padding: 2px;
  font-size: 12px;
}

.energy-container-small {
  display: flex;
  gap: 3px;
  margin-top: 5px;
  padding-top: 5px;
  border-top: 1px solid #e2e8f0;
  flex-wrap: wrap;
  justify-content: center;
}

.energy-mini-small {
  width: 30px;
  height: 42px;
  border-radius: 3px;
  overflow: hidden;
  border: 1px solid #cbd5e0;
  cursor: pointer;
  transition: transform 0.2s;
}

.energy-mini-small:hover {
  transform: scale(1.5);
  z-index: 10;
}

.energy-mini-small img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  margin: 0;
}

.stacked-cards-container-small {
  margin-top: 5px;
  padding-top: 5px;
  border-top: 1px solid #e2e8f0;
}

.stacked-mini-card-small {
  width: 35px;
  height: 49px;
  border-radius: 3px;
  overflow: hidden;
  border: 1px solid #cbd5e0;
  opacity: 0.8;
  transition: all 0.2s;
  cursor: help;
  display: inline-block;
  margin-right: 3px;
}

.stacked-mini-card-small:hover {
  opacity: 1;
  transform: scale(2);
  z-index: 999;
}

.stacked-mini-card-small img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.empty-slot {
  background: rgba(255, 255, 255, 0.1);
  border: 2px dashed rgba(255, 255, 255, 0.3);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgba(255, 255, 255, 0.5);
  font-size: 14px;
  width: 220px;
  min-height: 300px;
}

.empty-slot.small {
  width: 100%;
  min-height: 200px;
  font-size: 12px;
}

/* ========== 牌庫區域 ========== */
.deck-area {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.deck-item {
  text-align: center;
}

.deck-stack {
  width: 140px;
  height: 196px;
  background: linear-gradient(135deg, #2d3748 0%, #1a202c 100%);
  border: 3px solid #4a5568;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  transition: all 0.2s;
  margin: 0 auto;
}

.deck-stack.clickable {
  cursor: pointer;
}

.deck-stack.clickable:hover {
  transform: translateY(-5px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.4);
}

.deck-stack.discard {
  background: linear-gradient(135deg, #742a2a 0%, #c53030 100%);
  border-color: #e53e3e;
}

.deck-stack.prize {
  background: linear-gradient(135deg, #975a16 0%, #dd6b20 100%);
  border-color: #ed8936;
}

.deck-count {
  font-size: 48px;
  font-weight: bold;
  color: white;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
}

/* ========== 手牌區 ========== */
.hand-zone {
  margin-top: 30px;
  padding-top: 20px;
  border-top: 2px solid rgba(255, 255, 255, 0.2);
}

.hand-cards {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  padding: 10px 0;
  -webkit-overflow-scrolling: touch;
}

.hand-card {
  background: white;
  border-radius: 12px;
  padding: 10px;
  width: 140px;
  flex-shrink: 0;
  cursor: pointer;
  transition: all 0.2s;
  border: 3px solid transparent;
}

.hand-card:hover {
  transform: translateY(-10px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
}

.hand-card.selected {
  border-color: #fbbf24;
  box-shadow: 0 0 20px rgba(251, 191, 36, 0.5);
}

.hand-card img {
  width: 100%;
  border-radius: 8px;
  margin-bottom: 8px;
}

.card-info {
  color: black;
}

.card-name {
  font-weight: bold;
  font-size: 12px;
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-type {
  font-size: 10px;
  color: #666;
  margin-bottom: 2px;
}

.card-hp {
  font-size: 10px;
  color: #e53e3e;
  font-weight: bold;
}

.card-stage {
  font-size: 10px;
  color: #4299e1;
}

/* ========== 操作選單 ========== */
.action-menu {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(26, 32, 44, 0.98);
  padding: 20px;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
  z-index: 1000;
  min-width: 400px;
  max-width: 90vw;
  border: 2px solid rgba(251, 191, 36, 0.5);
}

.action-menu-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 2px solid rgba(255, 255, 255, 0.2);
}

.action-menu-header h3 {
  color: #fbbf24;
  margin: 0;
  font-size: 18px;
}

.close-btn {
  width: 30px;
  height: 30px;
  background: #e53e3e;
  color: white;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  font-size: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.close-btn:hover {
  background: #c53030;
  transform: rotate(90deg);
}

.action-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.action-btn {
  padding: 10px 20px;
  background: #4a5568;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.2s;
  flex: 1;
  min-width: 120px;
}

.action-btn:hover {
  background: #2d3748;
  transform: translateY(-2px);
}

.action-btn.primary {
  background: linear-gradient(135deg, #4299e1 0%, #3182ce 100%);
}

.action-btn.primary:hover {
  background: linear-gradient(135deg, #3182ce 0%, #2c5282 100%);
}

.action-btn.cancel {
  background: #718096;
}

.action-btn.cancel:hover {
  background: #4a5568;
}

.action-btn.disabled {
  background: #2d3748;
  color: #718096;
  cursor: not-allowed;
  opacity: 0.5;
}

.action-btn.disabled:hover {
  transform: none;
}

.hint {
  margin-top: 15px;
  padding: 10px;
  background: rgba(66, 153, 225, 0.2);
  border-left: 4px solid #4299e1;
  border-radius: 4px;
  font-size: 14px;
  color: #90cdf4;
}

.action-content {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.draw-count-selector {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.draw-count-selector label {
  font-size: 14px;
  color: #e2e8f0;
}

.count-controls {
  display: flex;
  gap: 10px;
  align-items: center;
}

.count-btn {
  width: 40px;
  height: 40px;
  background: #4299e1;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 20px;
  font-weight: bold;
  transition: all 0.2s;
}

.count-btn:hover {
  background: #3182ce;
}

.count-input {
  width: 80px;
  height: 40px;
  text-align: center;
  border: 2px solid #4a5568;
  border-radius: 8px;
  background: #2d3748;
  color: white;
  font-size: 18px;
  font-weight: bold;
}

.info-text {
  color: #e2e8f0;
  font-size: 14px;
  text-align: center;
  padding: 10px;
}
</style>
