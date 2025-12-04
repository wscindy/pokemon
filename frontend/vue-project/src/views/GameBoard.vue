<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { gameAPI } from '@/services/api'

const route = useRoute()
const gameStateId = ref(route.params.id)
const gameState = ref(null)
const loading = ref(true)
const error = ref(null)

// 選中的卡片和操作模式
const selectedCard = ref(null)
const selectedMode = ref(null)  // 'hand_card', 'field_pokemon', 'energy_transfer', 'deck_operation'
const selectedPokemonOnField = ref(null)
const selectedEnergyCard = ref(null)
const operationMode = ref(null)  // 'attach', 'stack', 'transfer_energy_target', 'select_bench_position'
const targetPokemon = ref(null)

// 牌庫操作狀態
const selectedDeckZone = ref(null)  // 'deck', 'discard', 'prize'
const drawCount = ref(1)  // 預設抽1張

// 排序後的手牌
const sortedHandCards = computed(() => {
  if (!gameState.value?.hand) return []
  
  return [...gameState.value.hand].sort((a, b) => {
    return a.card_unique_id.localeCompare(b.card_unique_id)
  })
})

// ========== 新增:按鈕禁用邏輯 ==========

// 戰鬥場是否已有牌
const isActiveSlotFilled = computed(() => {
  return gameState.value?.active_pokemon != null
})

// 備戰區是否已滿(5張)
const isBenchFull = computed(() => {
  return gameState.value?.bench?.length >= 5
})

// 能否放到戰鬥場
const canPlayToActive = computed(() => {
  if (!selectedCard.value) return false
  // 只有寶可夢卡才能放到戰鬥場
  if (selectedCard.value.card_type !== 'Pokémon') return false
  // 戰鬥場已有牌就不能放
  return !isActiveSlotFilled.value
})

// 能否放到備戰區
const canPlayToBench = computed(() => {
  if (!selectedCard.value) return false
  // 只有寶可夢卡才能放到備戰區
  if (selectedCard.value.card_type !== 'Pokémon') return false
  // 備戰區滿了就不能放
  return !isBenchFull.value
})

// ========== 新增:格式化疊加卡片顯示 ==========

// 格式化場上寶可夢的疊加卡片(最新的在最上面)
const formatStackedCards = (pokemon) => {
  if (!pokemon.stacked_cards || pokemon.stacked_cards.length === 0) {
    return []
  }
  
  // 按照 created_at 或 id 排序,最新的在前面
  return [...pokemon.stacked_cards].sort((a, b) => {
    // 假設 id 越大越新,或者可以用 created_at
    return b.id - a.id
  })
}

// 載入遊戲狀態
const loadGameState = async () => {
  try {
    const response = await gameAPI.getGameState(gameStateId.value)
    gameState.value = response.data
  } catch (err) {
    console.error('載入遊戲狀態失敗:', err)
    error.value = err.message
  } finally {
    loading.value = false
  }
}

// ========== 手牌操作 ==========

// 點擊手牌
const handleCardClick = (card) => {
  selectedCard.value = card
  selectedMode.value = 'hand_card'
  operationMode.value = null
  selectedPokemonOnField.value = null
  
  console.log('選中卡片:', card.name)
}

// 出牌到戰鬥場
const playToActive = async () => {
  if (!selectedCard.value || !canPlayToActive.value) return
  
  try {
    await gameAPI.playCard(gameStateId.value, selectedCard.value.id, 'active')
    await loadGameState()
    cancelSelection()
    alert('出牌成功!')
  } catch (err) {
    alert('出牌失敗: ' + (err.response?.data?.error || err.message))
  }
}

// 出牌到備戰區
const playToBench = async () => {
  if (!selectedCard.value || !canPlayToBench.value) return
  
  try {
    await gameAPI.playCard(gameStateId.value, selectedCard.value.id, 'bench')
    await loadGameState()
    cancelSelection()
    alert('出牌成功!')
  } catch (err) {
    alert('出牌失敗: ' + (err.response?.data?.error || err.message))
  }
}

// 準備附加能量
const prepareAttachEnergy = () => {
  if (!selectedCard.value) return
  operationMode.value = 'attach'
  console.log('請選擇目標寶可夢')
}

// 準備疊加卡片
const prepareStackCard = () => {
  if (!selectedCard.value) return
  operationMode.value = 'stack'
  console.log('請選擊場上的寶可夢來疊加卡片')
}

// ========== 場上寶可夢操作 ==========

// 點擊場上的寶可夢
const handleFieldPokemonClick = (pokemon) => {
  // 如果是附加能量模式
  if (operationMode.value === 'attach') {
    attachEnergyToPokemon(selectedCard.value, pokemon)
    return
  }
  
  // 如果是疊加模式
  if (operationMode.value === 'stack') {
    stackCardOnPokemon(selectedCard.value, pokemon)
    return
  }
  
  // 如果是轉移能量模式
  if (operationMode.value === 'transfer_energy_target') {
    transferEnergyToPokemon(selectedEnergyCard.value, pokemon)
    return
  }
  
  // 一般模式:選中並顯示操作選單
  selectedPokemonOnField.value = pokemon
  selectedMode.value = 'field_pokemon'
  operationMode.value = null
}

// 附加能量到寶可夢
const attachEnergyToPokemon = async (energyCard, pokemon) => {
  try {
    await gameAPI.attachEnergy(
      gameStateId.value,
      energyCard.id,
      pokemon.id
    )
    await loadGameState()
    cancelSelection()
    alert('附加能量成功!')
  } catch (err) {
    alert('附加能量失敗: ' + (err.response?.data?.error || err.message))
  }
}

// 疊加卡片到寶可夢
const stackCardOnPokemon = async (card, targetPokemon) => {
  try {
    await gameAPI.stackCard(gameStateId.value, card.id, targetPokemon.id)
    await loadGameState()
    cancelSelection()
    alert('疊加成功!')
  } catch (err) {
    alert('疊加失敗: ' + (err.response?.data?.error || err.message))
  }
}

// 移動卡片到指定區域
const moveCardTo = async (card, toZone, toPosition = null) => {
  try {
    await gameAPI.moveCard(gameStateId.value, card.id, toZone, toPosition)
    await loadGameState()
    cancelSelection()
    
    const zoneNames = {
      'hand': '手牌',
      'discard': '棄牌堆',
      'deck': '牌堆',
      'active': '戰鬥場',
      'bench': '備戰區'
    }
    alert(`已移至${zoneNames[toZone]}`)
  } catch (err) {
    alert('移動失敗: ' + (err.response?.data?.error || err.message))
  }
}

// ========== 傷害操作 ==========

// 傷害調整 (+10 / -10)
const adjustDamage = async (pokemon, amount) => {
  const newDamage = Math.max(0, pokemon.damage_taken + amount)
  try {
    await gameAPI.updateDamage(gameStateId.value, pokemon.id, newDamage)
    await loadGameState()
  } catch (err) {
    alert('更新傷害失敗: ' + (err.response?.data?.error || err.message))
  }
}

// 直接輸入傷害值
const updateDamage = async (pokemon) => {
  try {
    await gameAPI.updateDamage(gameStateId.value, pokemon.id, pokemon.damage_taken)
    await loadGameState()
  } catch (err) {
    alert('更新傷害失敗: ' + (err.response?.data?.error || err.message))
  }
}

// ========== 能量卡操作 ==========

// 點擊能量卡(準備轉移)
const selectEnergyForTransfer = (energy, fromPokemon) => {
  selectedEnergyCard.value = { ...energy, fromPokemon }
  selectedMode.value = 'energy_transfer'
  operationMode.value = null
}

// 轉移能量到寶可夢
const transferEnergyToPokemon = async (energyData, toPokemon) => {
  try {
    await gameAPI.transferEnergy(
      gameStateId.value,
      energyData.id,
      energyData.fromPokemon.id,
      toPokemon.id,
      null
    )
    await loadGameState()
    cancelSelection()
    alert('能量轉移成功!')
  } catch (err) {
    alert('轉移失敗: ' + (err.response?.data?.error || err.message))
  }
}

// 移動能量到其他區域
const moveEnergyTo = async (energyData, toZone) => {
  try {
    await gameAPI.transferEnergy(
      gameStateId.value,
      energyData.id,
      energyData.fromPokemon.id,
      null,
      toZone
    )
    await loadGameState()
    cancelSelection()
    
    const zoneNames = {
      'hand': '手牌',
      'discard': '棄牌堆',
      'deck': '牌堆'
    }
    alert(`能量已移至${zoneNames[toZone]}`)
  } catch (err) {
    alert('移動失敗: ' + (err.response?.data?.error || err.message))
  }
}

// ========== 牌庫操作 ==========

// 點擊牌庫
const handleDeckClick = () => {
  selectedDeckZone.value = 'deck'
  selectedMode.value = 'deck_operation'
  drawCount.value = 1
}

// 點擊棄牌堆
const handleDiscardClick = () => {
  selectedDeckZone.value = 'discard'
  selectedMode.value = 'deck_operation'
  drawCount.value = 1
}

// 點擊獎勵卡
const handlePrizeClick = () => {
  selectedDeckZone.value = 'prize'
  selectedMode.value = 'deck_operation'
}

// 從牌庫抽牌
const drawFromDeck = async () => {
  try {
    const response = await gameAPI.drawCards(gameStateId.value, drawCount.value)
    await loadGameState()
    cancelSelection()
    alert(response.data.message)
  } catch (err) {
    alert('抽牌失敗: ' + (err.response?.data?.error || err.message))
  }
}

// 從棄牌堆撿牌
const pickFromDiscard = async () => {
  try {
    const response = await gameAPI.pickFromDiscard(gameStateId.value, drawCount.value)
    await loadGameState()
    cancelSelection()
    alert(response.data.message)
  } catch (err) {
    alert('撿牌失敗: ' + (err.response?.data?.error || err.message))
  }
}

// 領取獎勵卡
const takePrizeCard = async () => {
  try {
    const response = await gameAPI.takePrize(gameStateId.value)
    await loadGameState()
    cancelSelection()
    alert(response.data.message)
  } catch (err) {
    alert('領取失敗: ' + (err.response?.data?.error || err.message))
  }
}

// ========== 回合管理 ==========

// 結束回合
const confirmTurn = async () => {
  try {
    await gameAPI.endTurn(gameStateId.value)
    await loadGameState()
    alert('回合已結束,換對手操作')
  } catch (err) {
    alert('結束回合失敗: ' + (err.response?.data?.error || err.message))
  }
}

// ========== 通用操作 ==========

// 取消選擇
const cancelSelection = () => {
  selectedCard.value = null
  selectedMode.value = null
  selectedPokemonOnField.value = null
  operationMode.value = null
  selectedEnergyCard.value = null
  targetPokemon.value = null
  selectedDeckZone.value = null
  drawCount.value = 1
}

onMounted(() => {
  loadGameState()
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

      <!-- 遊戲資訊 -->
      <header class="game-header">
        <div class="game-info">
          <h2>遊戲 #{{ gameStateId }}</h2>
          <p>回合: {{ gameState.round_number }}</p>
        </div>
        <div class="stats">
          <div class="stat-item">
            <span class="stat-label">牌庫</span>
            <span class="stat-value">{{ gameState.deck_count }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">獎勵卡</span>
            <span class="stat-value">{{ gameState.prize_count }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">棄牌堆</span>
            <span class="stat-value">{{ gameState.discard_count }}</span>
          </div>
        </div>
      </header>

      <!-- 對手區域 -->
      <section class="opponent-area">
        <h3>對手</h3>
        <div class="pokemon-area">
          <div class="active-slot empty-slot">
            <p>戰鬥場</p>
          </div>
          <div class="bench-slots">
            <div class="bench-slot empty-slot" v-for="i in 5" :key="i">
              <p>備戰 {{ i }}</p>
            </div>
          </div>
        </div>
      </section>

      <!-- 玩家區域 -->
      <section class="player-area">
        <h3>你的場地</h3>
        
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
                <img :src="gameState.active_pokemon.img_url" :alt="gameState.active_pokemon.name">
                <p class="pokemon-name">{{ gameState.active_pokemon.name }}</p>
                <p class="pokemon-hp">HP: {{ gameState.active_pokemon.hp - gameState.active_pokemon.damage_taken }}/{{ gameState.active_pokemon.hp }}</p>
                
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

                <!-- 疊加的卡片 (修改:最新的顯示最大) -->
                <div v-if="gameState.active_pokemon.stacked_cards?.length > 0" class="stacked-cards-container">
                  <div 
                    v-for="(card, index) in formatStackedCards(gameState.active_pokemon)" 
                    :key="card.id"
                    class="stacked-mini-card"
                    :class="{ 'is-latest': index === 0 }"
                    :style="{ zIndex: formatStackedCards(gameState.active_pokemon).length - index }"
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
                  v-for="pokemon in gameState.bench" 
                  :key="pokemon.id"
                  class="pokemon-card small"
                  :class="{ 
                    'target-highlight': operationMode === 'attach' || operationMode === 'stack' || operationMode === 'transfer_energy_target' 
                  }"
                  @click="handleFieldPokemonClick(pokemon)"
                >
                  <img :src="pokemon.img_url" :alt="pokemon.name">
                  <p class="pokemon-name">{{ pokemon.name }}</p>
                  <p class="pokemon-hp-small">{{ pokemon.hp - pokemon.damage_taken }}/{{ pokemon.hp }}</p>
                  
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

                  <!-- 疊加的卡片(小版,修改:最新的顯示最大) -->
                  <div v-if="pokemon.stacked_cards?.length > 0" class="stacked-cards-container-small">
                    <div 
                      v-for="(card, index) in formatStackedCards(pokemon)" 
                      :key="card.id"
                      class="stacked-mini-card-small"
                      :class="{ 'is-latest': index === 0 }"
                      :style="{ zIndex: formatStackedCards(pokemon).length - index }"
                      :title="card.name"
                    >
                      <img :src="card.img_url" :alt="card.name">
                    </div>
                  </div>
                </div>
                
                <!-- 空位 -->
                <div 
                  v-for="i in (5 - gameState.bench.length)" 
                  :key="'empty-' + i"
                  class="empty-slot small"
                >
                  空位 {{ gameState.bench.length + i }}
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
                  :class="{ 'clickable': gameState.prize_count > 0 }"
                  @click="gameState.prize_count > 0 && handlePrizeClick()"
                >
                  <span class="deck-count">{{ gameState.prize_count }}</span>
                </div>
              </div>
              
              <!-- 棄牌堆 -->
              <div class="deck-item">
                <h4>棄牌堆</h4>
                <div 
                  class="deck-stack discard"
                  :class="{ 'clickable': gameState.discard_count > 0 }"
                  @click="gameState.discard_count > 0 && handleDiscardClick()"
                >
                  <span class="deck-count">{{ gameState.discard_count }}</span>
                </div>
              </div>
              
              <!-- 牌庫 -->
              <div class="deck-item">
                <h4>牌庫</h4>
                <div 
                  class="deck-stack"
                  :class="{ 'clickable': gameState.deck_count > 0 }"
                  @click="gameState.deck_count > 0 && handleDeckClick()"
                >
                  <span class="deck-count">{{ gameState.deck_count }}</span>
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

      <!-- 操作選單:手牌 (修改:加入按鈕禁用邏輯) -->
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
          <h3>{{ selectedPokemonOnField.name }}</h3>
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
            class="action-btn primary"
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

.stats {
  display: flex;
  gap: 30px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.stat-label {
  font-size: 14px;
  opacity: 0.8;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #fbbf24;
}

/* ========== 對手/玩家區域 ========== */
.opponent-area,
.player-area {
  background: rgba(255, 255, 255, 0.05);
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 20px;
  width: 100%;
}

/* ========== 場地佈局 ========== */
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
}

h4 {
  margin-bottom: 15px;
  font-size: 18px;
  color: #fbbf24;
}

.pokemon-card {
  background: white;
  color: black;
  padding: 15px;
  border-radius: 12px;
  width: 200px;
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
  width: 35px;
  height: 50px;
  border-radius: 4px;
  overflow: hidden;
  border: 1px solid #cbd5e0;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
  cursor: pointer;
  transition: transform 0.2s;
}

.energy-mini:hover {
  transform: scale(1.5);
  z-index: 10;
  box-shadow: 0 0 8px rgba(251, 191, 36, 0.6);
}

.energy-mini img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  margin: 0;
}

/* ========== 疊加卡片容器 (修改:最新的顯示最大) ========== */
.stacked-cards-container {
  display: flex;
  gap: 3px;
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid #e2e8f0;
  flex-wrap: wrap;
  align-items: flex-end;
}

.stacked-mini-card {
  width: 30px;
  height: 42px;
  border-radius: 3px;
  overflow: hidden;
  border: 1px solid #cbd5e0;
  opacity: 0.7;
  transition: all 0.2s;
  cursor: help;
}

/* 最新疊加的卡片(第一張)顯示為大張 */
.stacked-mini-card.is-latest {
  width: 45px;
  height: 63px;
  opacity: 1;
  border: 2px solid #fbbf24;
  box-shadow: 0 2px 8px rgba(251, 191, 36, 0.4);
}

.stacked-mini-card:hover {
  opacity: 1;
  transform: scale(1.5);
  z-index: 999 !important;
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

/* 傷害控制(小版) */
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
  width: 22px;
  height: 22px;
  background: #4299e1;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
  font-weight: bold;
}

.damage-input-small {
  width: 40px;
  text-align: center;
  border: 1px solid #cbd5e0;
  border-radius: 3px;
  padding: 2px;
  font-size: 11px;
}

/* 能量卡容器(小版) */
.energy-container-small {
  display: flex;
  gap: 2px;
  margin-top: 5px;
  padding-top: 5px;
  border-top: 1px solid #e2e8f0;
  flex-wrap: wrap;
  justify-content: center;
}

.energy-mini-small {
  width: 20px;
  height: 28px;
  border-radius: 2px;
  overflow: hidden;
  border: 1px solid #cbd5e0;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
  cursor: pointer;
  transition: transform 0.2s;
}

.energy-mini-small:hover {
  transform: scale(2);
  z-index: 10;
}

.energy-mini-small img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  margin: 0;
}

/* 疊加卡片容器(小版,修改:最新的顯示最大) */
.stacked-cards-container-small {
  display: flex;
  gap: 2px;
  margin-top: 5px;
  padding-top: 5px;
  border-top: 1px solid #e2e8f0;
  flex-wrap: wrap;
  align-items: flex-end;
}

.stacked-mini-card-small {
  width: 18px;
  height: 25px;
  border-radius: 2px;
  overflow: hidden;
  border: 1px solid #cbd5e0;
  opacity: 0.7;
  transition: all 0.2s;
  cursor: help;
}

/* 最新疊加的卡片(第一張)顯示為大張 */
.stacked-mini-card-small.is-latest {
  width: 28px;
  height: 39px;
  opacity: 1;
  border: 1px solid #fbbf24;
  box-shadow: 0 1px 4px rgba(251, 191, 36, 0.4);
}

.stacked-mini-card-small:hover {
  opacity: 1;
  transform: scale(2);
  z-index: 999 !important;
}

.stacked-mini-card-small img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

/* ========== 右側牌堆區 ========== */
.deck-area {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.deck-item {
  text-align: center;
}

.deck-item h4 {
  font-size: 14px;
  margin-bottom: 10px;
}

.deck-stack {
  width: 100%;
  height: 120px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  position: relative;
  transition: transform 0.2s;
}

.deck-stack.clickable {
  cursor: pointer;
}

.deck-stack.clickable:hover {
  transform: scale(1.1);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.4);
}

.deck-stack.discard {
  background: linear-gradient(135deg, #fc8181 0%, #f56565 100%);
}

.deck-stack.prize {
  background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%);
}

.deck-count {
  font-size: 36px;
  font-weight: bold;
  color: white;
}

/* ========== 空位 ========== */
.empty-slot {
  border: 2px dashed rgba(255, 255, 255, 0.3);
  border-radius: 12px;
  padding: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100px;
  opacity: 0.5;
  text-align: center;
}

.empty-slot.small {
  min-height: 80px;
  padding: 10px;
  font-size: 12px;
}

/* ========== 手牌區 ========== */
.hand-zone {
  margin-top: 30px;
  width: 100%;
}

.hand-cards {
  display: flex;
  gap: 15px;
  overflow-x: auto;
  padding: 10px 0;
  width: 100%;
  -webkit-overflow-scrolling: touch;
}

.hand-card {
  background: white;
  color: black;
  padding: 12px;
  border-radius: 10px;
  width: 150px;
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
  transform: translateY(-15px);
  box-shadow: 0 12px 24px rgba(251, 191, 36, 0.5);
}

.hand-card img {
  width: 100%;
  height: 210px;
  object-fit: cover;
  border-radius: 8px;
  margin-bottom: 8px;
}

.card-info {
  font-size: 12px;
}

.card-name {
  font-weight: bold;
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-type {
  color: #666;
  margin-bottom: 4px;
}

.card-hp {
  color: #e53e3e;
  font-weight: bold;
  margin-bottom: 4px;
}

.card-stage {
  color: #4299e1;
  font-size: 11px;
}

/* ========== 操作選單 ========== */
.action-menu {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  color: black;
  padding: 20px;
  box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.3);
  z-index: 1000;
  max-width: 100vw;
}

.action-menu-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.action-menu-header h3 {
  margin: 0;
  color: #2d3748;
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #718096;
}

.close-btn:hover {
  color: #2d3748;
}

.action-buttons {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.action-btn {
  flex: 1;
  min-width: 150px;
  padding: 12px 20px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  background: white;
  color: #2d3748;
}

.action-btn:hover:not(:disabled):not(.disabled) {
  background: #f7fafc;
  transform: translateY(-2px);
}

.action-btn.primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
}

.action-btn.primary:hover:not(:disabled):not(.disabled) {
  background: linear-gradient(135deg, #8B9EF5 0%, #9370C7 100%);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.action-btn.primary:active:not(:disabled):not(.disabled) {
  background: linear-gradient(135deg, #5A6FD8 0%, #644394 100%);
  transform: translateY(0);
}

/* 禁用按鈕樣式 */
.action-btn:disabled,
.action-btn.disabled {
  opacity: 0.4;
  cursor: not-allowed;
  background: #e2e8f0;
  color: #a0aec0;
  transform: none !important;
}

.action-btn.primary:disabled,
.action-btn.primary.disabled {
  background: #cbd5e0;
  color: #718096;
}

.action-btn.cancel {
  background: #fed7d7;
  color: #c53030;
  border-color: #fc8181;
}

.hint {
  margin-top: 15px;
  padding: 10px;
  background: #fef3c7;
  color: #92400e;
  border-radius: 8px;
  text-align: center;
  font-weight: 600;
}

/* ========== 牌庫操作選單 ========== */
.action-content {
  width: 100%;
}

.draw-count-selector {
  margin-bottom: 15px;
  padding: 15px;
  background: #f7fafc;
  border-radius: 8px;
}

.draw-count-selector label {
  display: block;
  margin-bottom: 10px;
  font-weight: 600;
  color: #2d3748;
}

.count-controls {
  display: flex;
  gap: 10px;
  align-items: center;
  justify-content: center;
}

.count-btn {
  width: 40px;
  height: 40px;
  background: #4299e1;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 20px;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s;
}

.count-btn:hover {
  background: #3182ce;
}

.count-input {
  width: 80px;
  height: 40px;
  text-align: center;
  border: 2px solid #cbd5e0;
  border-radius: 8px;
  font-size: 18px;
  font-weight: bold;
}

.info-text {
  padding: 15px;
  background: #e6fffa;
  color: #234e52;
  border-radius: 8px;
  text-align: center;
  margin-bottom: 15px;
  font-weight: 600;
}

/* ========== 響應式設計 ========== */
@media (max-width: 1200px) {
  .field-layout {
    flex-direction: column;
  }

  .right-side {
    width: 100%;
    display: flex;
    gap: 15px;
  }

  .deck-item {
    flex: 1;
  }

  .deck-stack {
    height: 100px;
  }
}

@media (max-width: 768px) {
  .game-board {
    padding: 10px;
  }

  .game-container {
    padding-bottom: 250px;
  }

  .game-header {
    flex-direction: column;
    gap: 15px;
    padding: 15px;
  }

  .stats {
    gap: 15px;
  }

  .bench-grid {
    grid-template-columns: repeat(3, 1fr);
  }

  .hand-cards {
    gap: 10px;
  }

  .hand-card {
    width: 130px;
  }

  .hand-card img {
    height: 180px;
  }

  .action-menu {
    padding: 15px;
  }

  .action-buttons {
    flex-direction: column;
  }

  .action-btn {
    width: 100%;
    min-width: auto;
  }

  .confirm-turn-btn {
    padding: 10px 20px;
    font-size: 14px;
  }
}

@media (max-width: 480px) {
  .pokemon-card {
    max-width: 180px;
  }

  .bench-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
  }

  .hand-card {
    width: 110px;
  }

  .hand-card img {
    height: 150px;
  }
}
</style>
