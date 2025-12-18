# app/controllers/api/v1/games_controller.rb
module Api
  module V1
    class GamesController < ApplicationController
      before_action :set_user
      before_action :set_game_state, only: [
        :setup_game, :game_state, :play_card, :attach_energy,
        :move_card, :stack_card, :update_damage, :transfer_energy, :end_turn,
        :draw_cards, :pick_from_discard, :take_prize, :move_stadium_card,
        :set_prize_cards
      ]

      # 初始化遊戲
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

      # 發牌
      def setup_game
        result = GameSetupService.new(@game_state).call

        if result[:success]
          render json: {
            message: "發牌完成",
            game_state: game_state_json(@game_state)
          }
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      # 查詢遊戲狀態
      def game_state
        render json: game_state_json(@game_state)
      end

      # 出牌
      def play_card
        card_id = params[:card_id]
        zone = params[:zone]
        
        game_card = @game_state.game_cards.find_by(
          id: card_id, 
          user_id: @current_user.id,
          zone: 'hand'
        )
        
        unless game_card
          render json: { error: '卡片不在手牌中或無權操作' }, status: :bad_request
          return
        end
        
        case zone
        when 'active'
          if @game_state.game_cards.exists?(user_id: @current_user.id, zone: 'active')
            render json: { error: '戰鬥場已有寶可夢' }, status: :bad_request
            return
          end
          
          game_card.update!(zone: 'active', zone_position: nil)
          
        when 'bench'
          bench_count = @game_state.game_cards.where(user_id: @current_user.id, zone: 'bench').count
          
          if bench_count >= 5
            render json: { error: '備戰區已滿' }, status: :bad_request
            return
          end
          
          game_card.update!(zone: 'bench', zone_position: bench_count)
          
        when 'stadium'
          old_stadium = @game_state.game_cards.find_by(zone: 'stadium')
          if old_stadium
            old_stadium.update!(zone: 'discard', zone_position: nil)
          end
          
          game_card.update!(zone: 'stadium', zone_position: Time.current.to_i)
          
        else
          render json: { error: "未知的位置: #{zone}" }, status: :bad_request
          return
        end
        
        game_card.reload
        
        render json: { 
          message: '出牌成功',
          game_card: game_card.as_json(include: [:attached_cards, :stacked_cards]),
          game_state: game_state_json(@game_state.reload)
        }, status: :ok
      end

      # 附加能量
      def attach_energy
        energy_card = @game_state.game_cards.find_by(
          id: params[:card_id],
          user_id: @current_user.id,
          zone: 'hand'
        )
        
        target_pokemon = @game_state.game_cards.find_by(
          id: params[:target_card_id],
          user_id: @current_user.id
        )

        unless energy_card && target_pokemon
          return render json: { error: '找不到卡片' }, status: :not_found
        end

        energy_card.update!(
          zone: 'attached',
          attached_to_game_card_id: target_pokemon.id
        )

        render json: {
          message: '能量附加成功',
          game_state: game_state_json(@game_state.reload)
        }
      end

      # 移動卡牌
      def move_card
        card = @game_state.game_cards.find_by(
          id: params[:card_id],
          user_id: @current_user.id
        )
        
        unless card
          return render json: { error: '找不到卡片' }, status: :not_found
        end

        card.update!(
          zone: params[:to_zone],
          zone_position: params[:to_position]
        )

        render json: {
          message: '移動成功',
          game_state: game_state_json(@game_state.reload)
        }
      end

      # 疊加卡牌
      def stack_card
        card = @game_state.game_cards.find_by(
          id: params[:card_id],
          user_id: @current_user.id
        )
        
        target = @game_state.game_cards.find_by(
          id: params[:target_card_id],
          user_id: @current_user.id
        )

        unless card && target
          return render json: { error: '找不到卡片' }, status: :not_found
        end

        card.update!(
          zone: 'stacked',
          parent_card_id: target.id
        )

        render json: {
          message: '疊加成功',
          game_state: game_state_json(@game_state.reload)
        }
      end

      # 更新傷害
      def update_damage
        pokemon = @game_state.game_cards.find_by(
          id: params[:pokemon_id],
          user_id: @current_user.id
        )

        unless pokemon
          return render json: { error: '找不到寶可夢' }, status: :not_found
        end

        pokemon.update!(damage_taken: params[:damage_taken])

        render json: {
          message: "傷害已更新",
          game_state: game_state_json(@game_state.reload)
        }
      end

      # 轉移能量
      def transfer_energy
        energy = @game_state.game_cards.find_by(
          id: params[:energy_id],
          attached_to_game_card_id: params[:from_pokemon_id]
        )

        unless energy
          return render json: { error: '找不到能量卡' }, status: :not_found
        end

        if params[:to_pokemon_id]
          energy.update!(attached_to_game_card_id: params[:to_pokemon_id])
        elsif params[:to_zone]
          energy.update!(
            zone: params[:to_zone],
            attached_to_game_card_id: nil
          )
        end

        render json: {
          message: '能量轉移成功',
          game_state: game_state_json(@game_state.reload)
        }
      end

      # 結束回合
      def end_turn
        @game_state.update!(
          current_turn_user_id: @game_state.current_turn_user_id == @game_state.player1_id ? 
                                @game_state.player2_id : @game_state.player1_id,
          round_number: @game_state.round_number + 1
        )

        render json: {
          message: '回合結束',
          game_state: game_state_json(@game_state.reload)
        }
      end

      # 抽牌
      def draw_cards
        count = params[:count].to_i
        deck_cards = @game_state.game_cards
          .where(user_id: @current_user.id, zone: 'deck')
          .order(:zone_position)
          .limit(count)

        deck_cards.update_all(zone: 'hand', zone_position: nil)

        render json: {
          message: "抽了 #{deck_cards.count} 張牌",
          game_state: game_state_json(@game_state.reload)
        }
      end

      # 從棄牌堆撿牌
      def pick_from_discard
        count = params[:count].to_i
        discard_cards = @game_state.game_cards
          .where(user_id: @current_user.id, zone: 'discard')
          .order(updated_at: :desc)
          .limit(count)

        discard_cards.update_all(zone: 'hand', zone_position: nil)

        render json: {
          message: "從棄牌堆撿了 #{discard_cards.count} 張牌",
          picked_cards: discard_cards,
          game_state: game_state_json(@game_state.reload)
        }
      end

      # 領取獎勵卡
      def take_prize
        prize_card = @game_state.game_cards
          .where(user_id: @current_user.id, zone: 'prize')
          .first

        unless prize_card
          return render json: { error: '沒有獎勵卡可領取' }, status: :bad_request
        end

        prize_card.update!(zone: 'hand', zone_position: nil)

        render json: {
          message: '領取獎勵卡成功',
          prize_card: prize_card,
          game_state: game_state_json(@game_state.reload)
        }
      end

      # 移動競技場卡
      def move_stadium_card
        card = @game_state.game_cards.find_by(
          id: params[:card_id],
          zone: 'stadium'
        )

        unless card
          return render json: { error: '找不到競技場卡' }, status: :not_found
        end

        target_user = User.find_by(id: params[:player_id])

        unless target_user
          return render json: { error: '找不到目標玩家' }, status: :not_found
        end

        card.update!(
          zone: params[:target_zone],
          user_id: target_user.id,
          zone_position: nil
        )

        render json: {
          message: '競技場卡移動成功',
          game_state: game_state_json(@game_state.reload)
        }
      end

      def set_prize_cards
        count = params[:count].to_i
        
        deck_cards = @game_state.game_cards
          .where(user_id: @current_user.id, zone: 'deck')
          .order(:created_at)
          .limit(count)

        deck_cards.update_all(zone: 'prize')

        # 加上 WebSocket 廣播
        broadcast_game_update('prize_cards_set', {
          count: deck_cards.count,
          user_id: @current_user.id,
          user_name: @current_user.name
        })

        render json: {
          message: "設定了 #{deck_cards.count} 張獎勵卡",
          game_state: game_state_json(@game_state.reload)
        }
      end

      private

      def set_user
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
          render json: { 
            error: '找不到用戶' 
          }, status: :unauthorized
        end
      end

      # 🔥 修正：改善查詢邏輯
      def set_game_state
        # 優先使用 room_id 查詢
        room = Room.find_by(id: params[:id])
        
        if room
          @game_state = room.game_state
        else
          # 如果不是 room_id，嘗試直接查詢 game_state_id
          @game_state = GameState.find_by(id: params[:id])
        end
        
        unless @game_state
          render json: { 
            error: '找不到遊戲',
            hint: '請確認房間號碼是否正確，或嘗試重新建立房間'
          }, status: :not_found
        end
      end

      def game_state_json(game_state)
        current_player_id = @current_user.id
        opponent_id = game_state.player1_id == current_player_id ? 
                      game_state.player2_id : game_state.player1_id

        {
          id: game_state.id,
          room_id: game_state.room_id,
          current_player_id: current_player_id,
          opponent_id: opponent_id,
          current_turn_user_id: game_state.current_turn_user_id,
          round_number: game_state.round_number,
          status: game_state.status,
          
          # 玩家資訊
          deck_count: game_state.game_cards.where(user_id: current_player_id, zone: 'deck').count,
          hand: cards_json(game_state.game_cards.where(user_id: current_player_id, zone: 'hand')),
          active_pokemon: card_detail_json(game_state.game_cards.find_by(user_id: current_player_id, zone: 'active')),
          bench: cards_json(game_state.game_cards.where(user_id: current_player_id, zone: 'bench').order(:zone_position)),
          discard_count: game_state.game_cards.where(user_id: current_player_id, zone: 'discard').count,
          prize_count: game_state.game_cards.where(user_id: current_player_id, zone: 'prize').count,
          
          # 對手資訊
          opponent: opponent_id ? {
            hand_count: game_state.game_cards.where(user_id: opponent_id, zone: 'hand').count,
            deck_count: game_state.game_cards.where(user_id: opponent_id, zone: 'deck').count,
            active_pokemon: card_detail_json(game_state.game_cards.find_by(user_id: opponent_id, zone: 'active')),
            bench: cards_json(game_state.game_cards.where(user_id: opponent_id, zone: 'bench').order(:zone_position)),
            discard_count: game_state.game_cards.where(user_id: opponent_id, zone: 'discard').count,
            prize_count: game_state.game_cards.where(user_id: opponent_id, zone: 'prize').count
          } : nil,
          
          # 競技場卡
          stadium_cards: stadium_cards_json(game_state.game_cards.where(zone: 'stadium'))
        }
      end

      def cards_json(cards)
        cards.map { |card| card_detail_json(card) }
      end

      def card_detail_json(card)
        return nil unless card

        card_data = Card.find_by(card_unique_id: card.card_unique_id)
        
        {
          id: card.id,
          card_unique_id: card.card_unique_id,
          name: card_data&.name,
          img_url: card_data&.img_url,
          card_type: card_data&.card_type,
          hp: card_data&.hp,
          stage: card_data&.stage,
          zone: card.zone,
          zone_position: card.zone_position,
          damage_taken: card.damage_taken,
          attached_energies: cards_json(card.attached_cards),
          stacked_cards: cards_json(card.stacked_cards)
        }
      end

      def stadium_cards_json(cards)
        cards.map do |card|
          card_data = Card.find_by(card_unique_id: card.card_unique_id)
          {
            id: card.id,
            card_unique_id: card.card_unique_id,
            name: card_data&.name,
            img_url: card_data&.img_url,
            owner_name: card.user.name
          }
        end
      end
    end
  end
end
