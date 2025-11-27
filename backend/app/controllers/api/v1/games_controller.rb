module Api
  module V1
    class GamesController < ApplicationController
      before_action :set_user

      # POST /api/v1/games/initialize
      def initialize_game
        result = GameInitializerService.new(@current_user).call

        if result[:success]
          render json: {
            message: "遊戲初始化成功",
            game_state_id: result[:game_state].id,
            room_id: result[:room].id
          }, status: :created
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/games/:id/setup
      def setup_game
        game_state = GameState.find(params[:id])
        result = GameSetupService.new(game_state, @current_user).call

        if result[:success]
          render json: {
            message: "發牌完成",
            hand: result[:hand].map { |gc| format_game_card(gc) },
            deck_count: result[:deck_count],
            prize_count: result[:prize_count]
          }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/games/:id/state
      def game_state
        game_state = GameState.find(params[:id])

        render json: {
          game_state_id: game_state.id,
          round_number: game_state.round_number,
          status: game_state.status,
          hand: get_hand_cards(game_state),
          active_pokemon: get_active_pokemon(game_state),
          bench: get_bench_pokemon(game_state),
          deck_count: get_deck_count(game_state),
          prize_count: get_prize_count(game_state),
          discard_count: get_discard_count(game_state)
        }
      end

      private

      def set_user
        @current_user = User.first
        
        unless @current_user
          render json: { 
            error: '找不到用戶,請先建立用戶或匯入資料' 
          }, status: :unprocessable_entity
        end
      end

      def format_game_card(game_card)
        {
          id: game_card.id,
          card_unique_id: game_card.card_unique_id,
          name: game_card.card.name,
          img_url: game_card.card.img_url,
          card_type: game_card.card.card_type,
          hp: game_card.card.hp,
          damage_taken: game_card.damage_taken,
          zone: game_card.zone,
          zone_position: game_card.zone_position
        }
      end

      def get_hand_cards(game_state)
        GameCard.includes(:card)
                .where(game_state_id: game_state.id, user_id: @current_user.id, zone: 'hand')
                .map { |gc| format_game_card(gc) }
      end

      def get_active_pokemon(game_state)
        card = GameCard.includes(:card)
                       .find_by(game_state_id: game_state.id, user_id: @current_user.id, zone: 'active')
        card ? format_game_card(card) : nil
      end

      def get_bench_pokemon(game_state)
        GameCard.includes(:card)
                .where(game_state_id: game_state.id, user_id: @current_user.id, zone: 'bench')
                .order(:zone_position)
                .map { |gc| format_game_card(gc) }
      end

      def get_deck_count(game_state)
        GameCard.where(game_state_id: game_state.id, user_id: @current_user.id, zone: 'deck').count
      end

      def get_prize_count(game_state)
        GameCard.where(game_state_id: game_state.id, user_id: @current_user.id, zone: 'prize').count
      end

      def get_discard_count(game_state)
        GameCard.where(game_state_id: game_state.id, user_id: @current_user.id, zone: 'discard').count
      end
    end
  end
end
