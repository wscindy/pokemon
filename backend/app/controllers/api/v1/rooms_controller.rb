# app/controllers/api/v1/rooms_controller.rb
module Api
  module V1
    class RoomsController < ApplicationController
      before_action :authenticate_user_from_token!

      def join
        room = Room.find(params[:room_id])
        game_state = GameState.find_by(room_id: room.id)

        # 更新 player2
        game_state.update!(player2_id: current_user.id)

        # 為 player2 創建牌組
        create_deck_for_player(game_state, current_user.id)

        # 為 player2 洗牌
        shuffle_deck_for_player(game_state, current_user.id)

        render json: {
          message: "成功加入房間",
          room_id: room.id,
          game_state_id: game_state.id
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error "加入房間失敗: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def authenticate_user_from_token!
        token = cookies.signed[:jwt] || 
                request.headers['Authorization']&.split(' ')&.last

        unless token
          return render json: { error: 'No token provided' }, status: :unauthorized
        end

        decoded = JsonWebToken.decode(token)

        unless decoded
          return render json: { error: 'Invalid or expired token' }, status: :unauthorized
        end

        @current_user = User.find_by(id: decoded[:user_id])
        
        unless @current_user
          render json: { error: '找不到用戶' }, status: :unauthorized
        end
      end

      def current_user
        @current_user
      end

      # 為玩家創建牌組
      def create_deck_for_player(game_state, user_id)
        user_deck_cards = UserCard.where(user_id: user_id, is_in_deck: true)
                                   .pluck(:card_unique_id, :quantity)

        if user_deck_cards.empty?
          raise "玩家 #{user_id} 沒有設置牌組"
        end

        game_cards = []
        user_deck_cards.each do |card_unique_id, quantity|
          quantity.times do
            game_cards << {
              game_state_id: game_state.id,
              user_id: user_id,
              card_unique_id: card_unique_id,
              zone: 'deck',
              damage_taken: 0,
              is_evolved_this_turn: false,
              created_at: Time.current,
              updated_at: Time.current
            }
          end
        end

        GameCard.insert_all!(game_cards) if game_cards.any?

        Rails.logger.info "✅ 玩家 #{user_id} 的牌組已創建，共 #{game_cards.count} 張卡"
      end

      # 為玩家洗牌
      def shuffle_deck_for_player(game_state, user_id)
        deck_card_ids = game_state.game_cards
                                   .where(user_id: user_id, zone: 'deck')
                                   .pluck(:id)

        shuffled_ids = deck_card_ids.shuffle
        
        shuffled_ids.each_with_index do |card_id, index|
          GameCard.where(id: card_id).update_all(
            created_at: Time.current + index.seconds
          )
        end

        Rails.logger.info "✅ 玩家 #{user_id} 的牌組已洗牌，共 #{shuffled_ids.count} 張卡"
      end
    end
  end
end
