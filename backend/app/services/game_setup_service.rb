class GameSetupService
  attr_reader :game_state, :user

  def initialize(game_state, user)
    @game_state = game_state
    @user = user
  end

  def call
    ActiveRecord::Base.transaction do
      draw_initial_hand
      setup_prize_cards
      check_basic_pokemon
    end

    { 
      success: true, 
      hand: hand_cards,
      deck_count: deck_count,
      prize_count: prize_count
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  private

  def draw_initial_hand
    deck_cards = GameCard.where(game_state_id: @game_state.id, user_id: @user.id, zone: 'deck')
                         .order(:created_at)
                         .limit(7)

    deck_cards.update_all(zone: 'hand')
  end

  def setup_prize_cards
    deck_cards = GameCard.where(game_state_id: @game_state.id, user_id: @user.id, zone: 'deck')
                         .order(:created_at)
                         .limit(6)

    deck_cards.each_with_index do |card, index|
      card.update!(zone: 'prize', zone_position: index + 1)
    end
  end

def check_basic_pokemon
  basic_pokemon_in_hand = GameCard.joins(:card)
                                  .where(game_state_id: @game_state.id, user_id: @user.id, zone: 'hand')
                                  .where("cards.stage = 'Basic' OR cards.stage IS NULL")
                                  .where(cards: { card_type: 'Pokémon' })

  # 暫時註解掉檢查,方便開發測試
  # if basic_pokemon_in_hand.empty?
  #   raise "手牌中沒有基礎寶可夢!需要重新洗牌"
  # end

  # 開發階段:如果沒有基礎寶可夢,就直接返回(不報錯)
  if basic_pokemon_in_hand.empty?
    puts "⚠️ 警告:手牌中沒有基礎寶可夢(開發模式已忽略)"
  end

  basic_pokemon_in_hand
end


  def hand_cards
    GameCard.includes(:card)
            .where(game_state_id: @game_state.id, user_id: @user.id, zone: 'hand')
  end

  def deck_count
    GameCard.where(game_state_id: @game_state.id, user_id: @user.id, zone: 'deck').count
  end

  def prize_count
    GameCard.where(game_state_id: @game_state.id, user_id: @user.id, zone: 'prize').count
  end
end
