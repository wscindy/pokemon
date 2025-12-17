# app/services/game_setup_service.rb
class GameSetupService
  attr_reader :game_state

  def initialize(game_state)
    @game_state = game_state
  end

  def call
    ActiveRecord::Base.transaction do
      draw_initial_hand_for_player(@game_state.player1_id)
      draw_initial_hand_for_player(@game_state.player2_id)
      
      setup_prize_cards_for_player(@game_state.player1_id)
      setup_prize_cards_for_player(@game_state.player2_id)
      
      check_basic_pokemon_for_player(@game_state.player1_id)
      check_basic_pokemon_for_player(@game_state.player2_id)

      @game_state.update!(status: 'playing')
    end

    { success: true }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  private

  def draw_initial_hand_for_player(user_id)
    @game_state.game_cards
      .where(user_id: user_id, zone: 'deck')
      .order(:created_at)
      .limit(7)
      .update_all(zone: 'hand', zone_position: nil)
  end

  def setup_prize_cards_for_player(user_id)
    prize_cards = @game_state.game_cards
      .where(user_id: user_id, zone: 'deck')
      .order(:created_at)
      .limit(6)

    prize_cards.each_with_index do |card, index|
      card.update!(zone: 'prize', zone_position: index + 1)
    end
  end

  def check_basic_pokemon_for_player(user_id)
    @game_state.game_cards
      .joins(:card)
      .where(user_id: user_id, zone: 'hand')
      .where("cards.stage = 'Basic' OR cards.stage IS NULL")
      .where(cards: { card_type: 'Pokémon' })
  end
end
