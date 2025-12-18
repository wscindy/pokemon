# app/services/game_setup_service.rb

class GameSetupService
  def initialize(game_state)
    @game_state = game_state
  end

  def call
    # 🔥 檢查是否已經發過牌
    if @game_state.game_cards.where(zone: 'hand').any?
      Rails.logger.warn "⚠️ 遊戲已經發過牌，跳過"
      return { success: true, game_state: @game_state }
    end

    # 🔥 只為還沒拿到牌的玩家發牌
    [@game_state.player1, @game_state.player2].compact.each do |player|
      # 檢查這個玩家是否已經有牌
      unless @game_state.game_cards.exists?(user_id: player.id, zone: 'hand')
        deal_cards_to_player(player)
      end
    end

    @game_state.update!(status: 'playing')

    { success: true, game_state: @game_state }
  rescue => e
    Rails.logger.error "❌ 發牌失敗: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def deal_cards_to_player(player)
    # 抽 7 張手牌
    deck_cards = @game_state.game_cards
      .where(user_id: player.id, zone: 'deck')
      .order(:created_at)
      .limit(7)
    
    deck_cards.update_all(zone: 'hand', zone_position: nil)

    # 設定 6 張獎勵卡
    prize_cards = @game_state.game_cards
      .where(user_id: player.id, zone: 'deck')
      .order(:created_at)
      .limit(6)
    
    prize_cards.update_all(zone: 'prize')

    Rails.logger.info "✅ 為玩家 #{player.name} 發牌完成"
  end
end
