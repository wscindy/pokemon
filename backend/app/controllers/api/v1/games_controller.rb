# app/controllers/api/v1/games_controller.rb
module Api
  module V1
    class GamesController < ApplicationController
      before_action :authenticate_user_from_token!
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
          # 🔥 廣播遊戲開始
          broadcast_game_update('game_setup', {
            message: '發牌完成'
          })

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

        # 🔥 獲取卡片資料
        card_data = Card.find_by(card_unique_id: game_card.card_unique_id)

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

        # 🔥 廣播出牌動作（加入卡片名稱和位置中文）
        broadcast_game_update('card_played', {
          card_id: game_card.id,
          card_name: card_data&.name || '未知卡片',
          card_img_url: card_data&.img_url,
          card_type: card_data&.card_type,
          zone: zone,
          zone_display: zone_display_name(zone),
          user_id: @current_user.id,
          user_name: @current_user.name
        })

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

        # 🔥 獲取卡片資料
        energy_data = Card.find_by(card_unique_id: energy_card.card_unique_id)
        pokemon_data = Card.find_by(card_unique_id: target_pokemon.card_unique_id)


        energy_card.update!(
          zone: 'attached',
          attached_to_game_card_id: target_pokemon.id
        )


        # 🔥 廣播能量附加（加入卡片名稱）
        broadcast_game_update('energy_attached', {
          energy_id: energy_card.id,
          energy_name: energy_data&.name || '能量',
          target_pokemon_id: target_pokemon.id,
          target_pokemon_name: pokemon_data&.name || '寶可夢',
          user_id: @current_user.id,
          user_name: @current_user.name
        })


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

        # 🔥 獲取卡片資料
        card_data = Card.find_by(card_unique_id: card.card_unique_id)
        from_zone = card.zone


        card.update!(
          zone: params[:to_zone],
          zone_position: params[:to_position]
        )


        # 🔥 廣播卡牌移動（加入卡片名稱和位置中文）
        broadcast_game_update('card_moved', {
          card_id: card.id,
          card_name: card_data&.name || '卡片',
          from_zone: from_zone,
          from_zone_display: zone_display_name(from_zone),
          to_zone: params[:to_zone],
          to_zone_display: zone_display_name(params[:to_zone]),
          user_id: @current_user.id,
          user_name: @current_user.name
        })


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

        # 🔥 獲取卡片資料
        card_data = Card.find_by(card_unique_id: card.card_unique_id)
        target_data = Card.find_by(card_unique_id: target.card_unique_id)


        card.update!(
          zone: 'stacked',
          parent_card_id: target.id
        )


        # 🔥 廣播卡牌疊加（加入卡片名稱）
        broadcast_game_update('card_stacked', {
          card_id: card.id,
          card_name: card_data&.name || '卡片',
          target_card_id: target.id,
          target_card_name: target_data&.name || '寶可夢',
          user_id: @current_user.id,
          user_name: @current_user.name
        })


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

        # 🔥 獲取卡片資料
        pokemon_data = Card.find_by(card_unique_id: pokemon.card_unique_id)
        old_damage = pokemon.damage_taken
        pokemon.update!(damage_taken: params[:damage_taken])


        # 🔥 廣播傷害更新（加入寶可夢名稱）
        broadcast_game_update('damage_updated', {
          pokemon_id: pokemon.id,
          pokemon_name: pokemon_data&.name || '寶可夢',
          old_damage: old_damage,
          new_damage: params[:damage_taken],
          user_id: @current_user.id,
          user_name: @current_user.name
        })


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

        # 🔥 獲取卡片資料
        energy_data = Card.find_by(card_unique_id: energy.card_unique_id)
        from_pokemon = @game_state.game_cards.find(params[:from_pokemon_id])
        from_pokemon_data = Card.find_by(card_unique_id: from_pokemon.card_unique_id)

        to_pokemon_name = nil
        to_zone_display = nil


        if params[:to_pokemon_id]
          to_pokemon = @game_state.game_cards.find(params[:to_pokemon_id])
          to_pokemon_data = Card.find_by(card_unique_id: to_pokemon.card_unique_id)
          to_pokemon_name = to_pokemon_data&.name
          energy.update!(attached_to_game_card_id: params[:to_pokemon_id])
        elsif params[:to_zone]
          to_zone_display = zone_display_name(params[:to_zone])
          energy.update!(
            zone: params[:to_zone],
            attached_to_game_card_id: nil
          )
        end


        # 🔥 廣播能量轉移（加入詳細資訊）
        broadcast_game_update('energy_transferred', {
          energy_id: energy.id,
          energy_name: energy_data&.name || '能量',
          from_pokemon_id: params[:from_pokemon_id],
          from_pokemon_name: from_pokemon_data&.name || '寶可夢',
          to_pokemon_id: params[:to_pokemon_id],
          to_pokemon_name: to_pokemon_name,
          to_zone: params[:to_zone],
          to_zone_display: to_zone_display,
          user_id: @current_user.id,
          user_name: @current_user.name
        })


        render json: {
          message: '能量轉移成功',
          game_state: game_state_json(@game_state.reload)
        }
      end


      # 結束回合
      def end_turn
        old_turn_user = @game_state.current_turn_user_id

        @game_state.update!(
          current_turn_user_id: @game_state.current_turn_user_id == @game_state.player1_id ? 
                                @game_state.player2_id : @game_state.player1_id,
          round_number: @game_state.round_number + 1
        )


        # 🔥 廣播回合結束
        broadcast_game_update('turn_ended', {
          old_turn_user_id: old_turn_user,
          next_turn_user_id: @game_state.current_turn_user_id,
          round_number: @game_state.round_number,
          user_id: @current_user.id,
          user_name: @current_user.name
        })


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


        # 🔥 廣播抽牌
        broadcast_game_update('cards_drawn', {
          count: deck_cards.count,
          user_id: @current_user.id,
          user_name: @current_user.name
        })


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


        # 🔥 廣播從棄牌堆撿牌
        broadcast_game_update('cards_picked_from_discard', {
          count: discard_cards.count,
          user_id: @current_user.id,
          user_name: @current_user.name
        })


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

        # 🔥 獲取卡片資料
        card_data = Card.find_by(card_unique_id: prize_card.card_unique_id)


        prize_card.update!(zone: 'hand', zone_position: nil)


        # 🔥 廣播領取獎勵卡（加入卡片名稱）
        broadcast_game_update('prize_taken', {
          card_id: prize_card.id,
          card_name: card_data&.name || '獎勵卡',
          user_id: @current_user.id,
          user_name: @current_user.name
        })


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

        # 🔥 獲取卡片資料
        card_data = Card.find_by(card_unique_id: card.card_unique_id)


        card.update!(
          zone: params[:target_zone],
          user_id: target_user.id,
          zone_position: nil
        )


        # 🔥 廣播競技場卡移動（加入詳細資訊）
        broadcast_game_update('stadium_card_moved', {
          card_id: card.id,
          card_name: card_data&.name || '競技場卡',
          target_zone: params[:target_zone],
          target_zone_display: zone_display_name(params[:target_zone]),
          player_id: params[:player_id],
          player_name: target_user.name,
          user_id: @current_user.id,
          user_name: @current_user.name
        })


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


        # 🔥 廣播設定獎勵卡
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


      # 廣播遊戲更新的方法
      def broadcast_game_update(action, data = {})
        return unless @game_state

        room_id = @game_state.room_id
        current_user_id = @current_user.id

        # 找出對手 ID
        opponent_id = if @game_state.player1_id == current_user_id
          @game_state.player2_id
        else
          @game_state.player1_id
        end

        Rails.logger.info "📡 廣播遊戲更新: #{action} to game_#{room_id}"
        Rails.logger.info "👤 當前玩家: #{current_user_id}, 對手: #{opponent_id.inspect}"

        # 備份原本的 @current_user
        original_user = @current_user

        # 產生當前玩家的視角
        @current_user = User.find(current_user_id)
        current_player_state = game_state_json(@game_state)

        # 建立 game_states，使用字串作為 key
        game_states = {}
        game_states[current_user_id.to_s] = current_player_state

        # 只在對手確實存在時才產生對手視角
        if opponent_id.present?  # ← 用 .present? 更安全
          begin
            @current_user = User.find(opponent_id)
            opponent_state = game_state_json(@game_state)
            game_states[opponent_id.to_s] = opponent_state
          rescue ActiveRecord::RecordNotFound => e
            Rails.logger.warn "⚠️ 找不到對手 ID: #{opponent_id}"
          end
        end

        # 還原 @current_user
        @current_user = original_user

        # 準備廣播的資料
        broadcast_data = {
          type: 'game_update',
          action: action,
          user_id: current_user_id,
          user_name: original_user.name,
          data: data,
          game_states: game_states
        }

        Rails.logger.info "📡 準備廣播資料，game_states keys: #{game_states.keys.inspect}"

        # 廣播
        ActionCable.server.broadcast("game_#{room_id}", broadcast_data)
        
        Rails.logger.info "✅ 廣播成功"
      rescue => e
        Rails.logger.error "❌ 廣播失敗: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.first(10).join("\n")
        raise
      end

      # 🔥 新增：zone 中文對照 helper
      def zone_display_name(zone)
        {
          'hand' => '手牌',
          'deck' => '牌庫',
          'discard' => '棄牌堆',
          'active' => '戰鬥場',
          'bench' => '備戰區',
          'stadium' => '競技場',
          'prize' => '獎勵卡',
          'attached' => '附加',
          'stacked' => '疊加'
        }[zone] || zone
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