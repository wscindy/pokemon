class CardPlayService
  attr_reader :game_state, :user, :game_card

  def initialize(game_state, user, game_card)
    @game_state = game_state
    @user = user
    @game_card = game_card
  end

  # 打出基礎寶可夢到場上
  def play_basic_pokemon(position)
    ActiveRecord::Base.transaction do
      # 決定位置
      target_zone = position == 'active' ? 'active' : 'bench'
      
      # 如果是備戰區,自動分配位置
      if target_zone == 'bench'
        bench_count = GameCard.where(
          game_state_id: @game_state.id,
          user_id: @user.id,
          zone: 'bench'
        ).count
        
        zone_position = bench_count + 1
      else
        zone_position = nil
      end

      # 移動卡片
      @game_card.update!(
        zone: target_zone,
        zone_position: zone_position
      )

      # 記錄操作
      GameAction.create!(
        game_state_id: @game_state.id,
        user_id: @user.id,
        round_number: @game_state.round_number,
        action_type: 'play_basic',
        source_card_id: @game_card.id,
        action_description: "打出了 #{@game_card.card.name}"
      )
    end

    { success: true, game_card: @game_card }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  # 附加能量卡到寶可夢
  def attach_energy(target_game_card_id)
    ActiveRecord::Base.transaction do
      # 附加能量
      @game_card.update!(
        zone: 'attached',
        attached_to_game_card_id: target_game_card_id
      )

      target_card = GameCard.find(target_game_card_id)

      # 記錄操作
      GameAction.create!(
        game_state_id: @game_state.id,
        user_id: @user.id,
        round_number: @game_state.round_number,
        action_type: 'attach_energy',
        source_card_id: @game_card.id,
        target_card_id: target_game_card_id,
        action_description: "將 #{@game_card.card.name} 附加到 #{target_card.card.name}"
      )
    end

    { success: true }
  rescue StandardError => e
    { success: false, error: e.message }
  end
end
