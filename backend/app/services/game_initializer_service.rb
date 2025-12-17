class GameInitializerService
  attr_reader :user, :room, :game_state

  def initialize(user)
    @user = user
    @errors = []
  end

  def call
    ActiveRecord::Base.transaction do
      create_room
      create_game_state
      initialize_deck
    end

    { success: true, game_state: @game_state, room: @room }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  private

  def create_room
    @room = Room.create!(
      name: "#{@user.name} 的遊戲",
      room_type: 'public',
      creator: @user,
      status: 'waiting'
    )

    RoomParticipant.create!(
      room: @room,
      user: @user,
      role: 'host',
      ready_status: true
    )
  end

  def create_game_state
    @game_state = GameState.create!(
      room: @room,
      player1: @user,
      player2: @user,  # 單人測試時用同一個 user
      current_turn_user: @user,
      round_number: 1,
      status: 'setup'
    )
  end

  def initialize_deck
    # ✅ 為兩個玩家都建立牌組
    [@game_state.player1, @game_state.player2].uniq.each do |player|
      create_deck_for_player(player)
    end
  end

  def create_deck_for_player(player)
    user_deck_cards = UserCard.where(user_id: player.id, is_in_deck: true)
                               .select(:card_unique_id, :quantity)

    deck_cards = []
    user_deck_cards.each do |user_card|
      copies = user_card.quantity > 0 ? user_card.quantity : 1
      
      copies.times do
        deck_cards << user_card.card_unique_id
        break if deck_cards.count >= 60
      end
      break if deck_cards.count >= 60
    end

    # 如果不足60張,重複填充
    if deck_cards.count < 60
      original_cards = deck_cards.dup
      while deck_cards.count < 60 && original_cards.any?
        deck_cards << original_cards[deck_cards.count % original_cards.count]
      end
    end

    if deck_cards.count < 60
      raise "玩家 #{player.name} 無法組成 60 張牌組"
    end

    deck_cards = deck_cards.first(60)

    # 建立 GAME_CARDS
    game_cards = []
    deck_cards.each_with_index do |card_unique_id, index|
      game_cards << {
        game_state_id: @game_state.id,
        user_id: player.id,
        card_unique_id: card_unique_id,
        zone: 'deck',
        damage_taken: 0,
        is_evolved_this_turn: false,
        created_at: Time.current + index.seconds,
        updated_at: Time.current
      }
    end

    GameCard.insert_all(game_cards)
    shuffle_deck_for_player(player)
  end

  def shuffle_deck_for_player(player)
    deck_cards = GameCard.where(
      game_state_id: @game_state.id,
      user_id: player.id,
      zone: 'deck'
    ).pluck(:id)
    
    deck_cards.shuffle.each_with_index do |id, index|
      GameCard.where(id: id).update_all(created_at: Time.current + index.seconds)
    end
  end
end
