module Api
  module V1
    class GamesController < ApplicationController
      # ========== before_action 區塊 ==========
      before_action :set_user
      before_action :set_game_state, only: [
        :setup_game, :game_state, :play_card, :attach_energy,
        :move_card, :stack_card, :update_damage, :transfer_energy, :end_turn,
        :draw_cards, :pick_from_discard, :take_prize, :move_stadium_card
      ]


      # ========== Public Actions ==========
      
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


      def setup_game
        result = GameSetupService.new(@game_state, @current_user).call


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


      def game_state
        render json: {
          game_state_id: @game_state.id,
          round_number: @game_state.round_number,
          status: @game_state.status,
          current_player_id: @current_user.id,
          opponent_id: @game_state.opponent_of(@current_user)&.id,
          hand: get_hand_cards(@game_state),
          active_pokemon: get_active_pokemon(@game_state),
          bench: get_bench_pokemon(@game_state),
          deck_count: get_deck_count(@game_state),
          prize_count: get_prize_count(@game_state),
          discard_count: get_discard_count(@game_state),
          stadium_cards: get_stadium_cards(@game_state)
        }
      end



      def play_card
        card_id = params[:card_id]
        zone = params[:zone]
        
        game_card = @game_state.game_cards.find_by(id: card_id, zone: 'hand')
        
        unless game_card
          render json: { error: '卡片不在手牌中' }, status: :bad_request
          return
        end
        
        case zone
        when 'active'
          if @game_state.game_cards.exists?(zone: 'active')
            render json: { error: '戰鬥場已有寶可夢' }, status: :bad_request
            return
          end
          
          game_card.update!(zone: 'active', zone_position: nil)
          
        when 'bench'
          bench_count = @game_state.game_cards.where(zone: 'bench').count
          
          if bench_count >= 5
            render json: { error: '備戰區已滿' }, status: :bad_request
            return
          end
          
          game_card.update!(zone: 'bench', zone_position: bench_count)
          
        when 'stadium'
          # ✅ 先移除場上舊的競技場卡(回到打出者的棄牌堆)
          old_stadium = @game_state.game_cards.find_by(zone: 'stadium')
          if old_stadium
            old_stadium.update!(
              zone: 'discard',
              zone_position: nil
            )
            Rails.logger.info "🏟️ 舊競技場卡 #{old_stadium.card.name} 已移至棄牌堆"
          end
          
          # 打出新的競技場卡
          game_card.update!(
            zone: 'stadium',
            zone_position: Time.current.to_i
          )
          
          Rails.logger.info "🏟️ 新競技場卡 #{game_card.card.name} 已打出"
          
        else
          render json: { error: "未知的位置: #{zone}" }, status: :bad_request
          return
        end
        
        game_card.reload
        
        render json: { 
          message: '出牌成功',
          game_card: game_card.as_json(include: [:attached_cards, :stacked_cards])
        }
      end




      def attach_energy
        game_card = GameCard.find(params[:card_id])
        
        result = CardPlayService.new(@game_state, @current_user, game_card)
                                .attach_energy(params[:target_card_id])


        if result[:success]
          render json: { message: '附加能量成功' }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end


      # 移動卡牌到指定區域
      def move_card
        game_card = GameCard.find(params[:card_id])
        to_zone = params[:to_zone]
        to_position = params[:to_position]


        # 檢查卡片擁有者
        unless game_card.user_id == @current_user.id
          render json: { error: '無權操作此卡片' }, status: :forbidden
          return
        end


        # ✅ 修復:清除所有附加關係
        game_card.update(
          zone: to_zone,
          zone_position: to_position,
          attached_to_game_card_id: nil,
          parent_card_id: nil,
          stack_order: nil
        )


        render json: { 
          message: "卡片已移至#{zone_name(to_zone)}",
          game_card: format_game_card(game_card.reload)
        }, status: :ok
      end


      # 疊加卡片
      def stack_card
        card_to_stack = GameCard.find(params[:card_id])
        target_card = GameCard.find(params[:target_card_id])


        # 檢查權限
        unless card_to_stack.user_id == @current_user.id && target_card.user_id == @current_user.id
          render json: { error: '無權操作此卡片' }, status: :forbidden
          return
        end


        # ✅ 修復:使用 transaction 確保原子性
        ActiveRecord::Base.transaction do
          # 取得當前最大的 stack_order
          max_order = GameCard.where(parent_card_id: target_card.id)
                              .maximum(:stack_order) || 0


          # 更新疊加卡片
          card_to_stack.update!(
            parent_card_id: target_card.id,
            stack_order: max_order + 1,
            zone: target_card.zone,
            zone_position: target_card.zone_position,
            attached_to_game_card_id: nil
          )


          render json: { 
            message: '疊加成功',
            target_card: format_game_card(target_card.reload)
          }, status: :ok
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: "疊加失敗: #{e.message}" }, status: :unprocessable_entity
      end


      # 更新傷害值
      def update_damage
        pokemon = GameCard.find(params[:pokemon_id])
        damage_value = params[:damage_taken].to_i


        # 檢查權限
        unless pokemon.user_id == @current_user.id
          render json: { error: '無權操作此卡片' }, status: :forbidden
          return
        end


        # ✅ 確保傷害值不為負數
        if pokemon.update(damage_taken: [0, damage_value].max)
          render json: { 
            message: '傷害更新成功',
            pokemon: format_game_card(pokemon)
          }, status: :ok
        else
          render json: { error: '更新失敗' }, status: :unprocessable_entity
        end
      end


      # 轉移能量卡
      def transfer_energy
        energy_card = GameCard.find(params[:energy_id])
        from_pokemon_id = params[:from_pokemon_id]
        to_pokemon_id = params[:to_pokemon_id]
        to_zone = params[:to_zone]


        # 檢查權限
        unless energy_card.user_id == @current_user.id
          render json: { error: '無權操作此能量卡' }, status: :forbidden
          return
        end


        # 轉移到寶可夢
        if to_pokemon_id.present?
          target_pokemon = GameCard.find(to_pokemon_id)
          
          unless target_pokemon.user_id == @current_user.id
            render json: { error: '無權操作目標寶可夢' }, status: :forbidden
            return
          end


          if energy_card.update(attached_to_game_card_id: target_pokemon.id, zone: 'attached')
            render json: { message: '能量轉移成功' }, status: :ok
          else
            render json: { error: '轉移失敗' }, status: :unprocessable_entity
          end


        # 轉移到其他區域
        elsif to_zone.present?
          # ✅ 清除附加關係
          if energy_card.update(attached_to_game_card_id: nil, zone: to_zone, zone_position: nil)
            render json: { message: "能量已移至#{zone_name(to_zone)}" }, status: :ok
          else
            render json: { error: '移動失敗' }, status: :unprocessable_entity
          end
        else
          render json: { error: '請指定目標' }, status: :unprocessable_entity
        end
      end


      # 結束回合
      def end_turn
        # 切換到對手
        opponent = @game_state.opponent_of(@current_user)
        
        unless opponent
          render json: { error: '找不到對手' }, status: :unprocessable_entity
          return
        end


        # 更新回合
        if @game_state.update(
          current_turn_user_id: opponent.id,
          round_number: @game_state.round_number + 1
        )
          # 重置 is_evolved_this_turn
          GameCard.where(game_state_id: @game_state.id, is_evolved_this_turn: true)
                  .update_all(is_evolved_this_turn: false)


          render json: { 
            message: '回合已結束',
            current_turn_user_id: opponent.id,
            round_number: @game_state.round_number
          }, status: :ok
        else
          render json: { error: '結束回合失敗' }, status: :unprocessable_entity
        end
      end


      # 從牌庫抽牌
      def draw_cards
        count = params[:count].to_i
        
        if count <= 0 || count > 10
          render json: { error: '抽牌數量必須在 1-10 張之間' }, status: :unprocessable_entity
          return
        end


        deck_cards = GameCard.where(
          game_state_id: @game_state.id,
          user_id: @current_user.id,
          zone: 'deck'
        ).limit(count)

        Rails.logger.info "🔍 draw_cards - 找到 #{deck_cards.count} 張牌庫卡片"

        if deck_cards.empty?
          render json: { error: '牌庫已空' }, status: :unprocessable_entity
          return
        end


        # ✅ 移動到手牌並清除關聯
        deck_cards.each do |card|
          Rails.logger.info "🔍 draw_cards - 移動卡片 #{card.id}"
          card.update(
            zone: 'hand',
            zone_position: nil,
            attached_to_game_card_id: nil,
            parent_card_id: nil,
            stack_order: nil
          )
        end

        formatted_cards = deck_cards.map { |gc| format_game_card(gc.reload) }
        Rails.logger.info "🔍 draw_cards - 格式化後剩餘 #{formatted_cards.compact.count} 張卡片"

        render json: {
          message: "抽了 #{deck_cards.count} 張牌",
          drawn_cards: formatted_cards.compact
        }, status: :ok
      end


      # 從棄牌堆撿牌
      def pick_from_discard
        count = params[:count].to_i
        
        if count <= 0 || count > 10
          render json: { error: '撿牌數量必須在 1-10 張之間' }, status: :unprocessable_entity
          return
        end


        discard_cards = GameCard.includes(:card)
                                .where(
                                  game_state_id: @game_state.id,
                                  user_id: @current_user.id,
                                  zone: 'discard'
                                )
                                .order(updated_at: :desc)
                                .limit(count)

        Rails.logger.info "🔍 pick_from_discard - 找到 #{discard_cards.count} 張棄牌堆卡片"

        if discard_cards.empty?
          render json: { error: '棄牌堆已空' }, status: :unprocessable_entity
          return
        end


        # 移動到手牌並清除關聯
        discard_cards.each do |card|
          Rails.logger.info "🔍 pick_from_discard - 移動卡片 #{card.id}: #{card.card.name}"
          Rails.logger.info "   移動前 - zone: #{card.zone}, attached_to: #{card.attached_to_game_card_id.inspect}, parent: #{card.parent_card_id.inspect}"
          
          card.update(
            zone: 'hand',
            zone_position: nil,
            attached_to_game_card_id: nil,
            parent_card_id: nil,
            stack_order: nil
          )
          
          card.reload
          Rails.logger.info "   移動後 - zone: #{card.zone}, attached_to: #{card.attached_to_game_card_id.inspect}, parent: #{card.parent_card_id.inspect}"
        end

        formatted_cards = discard_cards.map { |gc| format_game_card(gc) }
        Rails.logger.info "🔍 pick_from_discard - 格式化後剩餘 #{formatted_cards.compact.count} 張卡片"
        
        formatted_cards.each_with_index do |fc, idx|
          if fc.nil?
            Rails.logger.info "   ❌ 第 #{idx} 張卡片格式化失敗 (返回 nil)"
          else
            Rails.logger.info "   ✅ 第 #{idx} 張卡片格式化成功: #{fc[:name]}"
          end
        end

        render json: {
          message: "從棄牌堆撿了 #{discard_cards.count} 張牌",
          picked_cards: formatted_cards.compact
        }, status: :ok
      end


      # 領取獎勵卡
      def take_prize
        prize_card = GameCard.includes(:card)
                            .where(
                              game_state_id: @game_state.id,
                              user_id: @current_user.id,
                              zone: 'prize'
                            )
                            .first

        Rails.logger.info "🔍 take_prize - 找到獎勵卡: #{prize_card&.id}"

        unless prize_card
          render json: { error: '沒有獎勵卡可領取' }, status: :unprocessable_entity
          return
        end


        # ✅ 移動到手牌並清除關聯
        Rails.logger.info "🔍 take_prize - 移動前 - zone: #{prize_card.zone}, attached_to: #{prize_card.attached_to_game_card_id.inspect}, parent: #{prize_card.parent_card_id.inspect}"
        
        if prize_card.update(
          zone: 'hand',
          zone_position: nil,
          attached_to_game_card_id: nil,
          parent_card_id: nil,
          stack_order: nil
        )
          prize_card.reload
          Rails.logger.info "🔍 take_prize - 移動後 - zone: #{prize_card.zone}, attached_to: #{prize_card.attached_to_game_card_id.inspect}, parent: #{prize_card.parent_card_id.inspect}"
          
          formatted = format_game_card(prize_card)
          Rails.logger.info "🔍 take_prize - 格式化結果: #{formatted.nil? ? 'nil' : '成功'}"
          
          render json: {
            message: '領取獎勵卡成功',
            prize_card: formatted
          }, status: :ok
        else
          render json: { error: '領取失敗' }, status: :unprocessable_entity
        end
      end


      # 移動競技場卡到指定玩家的指定區域
      def move_stadium_card
        # ✅ 使用 @game_state 來查找卡片
        stadium_card = @game_state.game_cards.find_by(id: params[:card_id])
        
        unless stadium_card
          render json: { error: "找不到卡片 (ID: #{params[:card_id]})" }, status: :not_found
          return
        end
        
        target_player_id = params[:player_id].to_i
        target_zone = params[:target_zone]
        
        # 檢查卡片確實在競技場
        unless stadium_card.zone == 'stadium'
          render json: { error: '此卡片不在競技場上' }, status: :bad_request
          return
        end
        
        # 檢查目標玩家是否存在
        target_player = User.find_by(id: target_player_id)
        unless target_player
          render json: { error: '找不到目標玩家' }, status: :bad_request
          return
        end
        
        # ✅ 檢查目標玩家是否參與此遊戲
        unless [@game_state.player1_id, @game_state.player2_id].include?(target_player_id)
          render json: { error: '目標玩家不在此遊戲中' }, status: :bad_request
          return
        end
        
        # 檢查目標區域是否合法
        valid_zones = ['hand', 'discard', 'deck']
        unless valid_zones.include?(target_zone)
          render json: { error: "不支援的目標區域: #{target_zone}" }, status: :bad_request
          return
        end
        
        # ✅ 更新卡片（清除所有關聯）
        if stadium_card.update(
          user_id: target_player_id,
          zone: target_zone,
          zone_position: nil,
          attached_to_game_card_id: nil,
          parent_card_id: nil,
          stack_order: nil
        )
          render json: {
            message: "競技場卡已移至#{target_player.name}的#{zone_name(target_zone)}",
            card: {
              id: stadium_card.id,
              name: stadium_card.card.name,
              new_zone: target_zone,
              new_owner: target_player.name
            }
          }, status: :ok
        else
          render json: { 
            error: '移動失敗', 
            details: stadium_card.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end




      # ========== Private Methods ==========
      private


      def get_stadium_cards(game_state)
        # 取得場上所有競技場卡(只取最新的一張,符合官方規則)
        GameCard.includes(:card, :user)
                .where(
                  game_state_id: game_state.id,
                  zone: 'stadium',
                  parent_card_id: nil,
                  attached_to_game_card_id: nil
                )
                .order(zone_position: :desc)
                .limit(1)
                .map do |gc|
          {
            id: gc.id,
            card_unique_id: gc.card_unique_id,
            name: gc.card.name,
            img_url: gc.card.img_url,
            card_type: gc.card.card_type,
            zone: gc.zone,
            zone_position: gc.zone_position,
            owner_id: gc.user_id,
            owner_name: gc.user.name
          }
        end
      end



      def set_user
        @current_user = User.first
        
        unless @current_user
          render json: { 
            error: '找不到用戶,請先建立用戶或匯入資料' 
          }, status: :unprocessable_entity
        end
      end


      def set_game_state
        @game_state = GameState.find(params[:id])
      end


      def format_game_card(game_card)
        return nil unless game_card
        
        Rails.logger.info "🔍 format_game_card - 開始格式化卡片 #{game_card.id}"
        Rails.logger.info "   zone: #{game_card.zone}"
        Rails.logger.info "   attached_to_game_card_id: #{game_card.attached_to_game_card_id.inspect}"
        Rails.logger.info "   parent_card_id: #{game_card.parent_card_id.inspect}"
        
        # ✅ 修復:如果是附加卡或疊加卡,不格式化(避免遞迴)
        if game_card.attached_to_game_card_id.present? || game_card.parent_card_id.present?
          Rails.logger.info "   ❌ 跳過格式化 (有關聯 ID)"
          return nil
        end


        # 查詢附加的能量卡
        attached_energies = GameCard.includes(:card)
                                    .where(attached_to_game_card_id: game_card.id, zone: 'attached')
                                    .map do |energy|
          {
            id: energy.id,
            name: energy.card.name,
            img_url: energy.card.img_url,
            card_type: energy.card.card_type
          }
        end


        # 查詢疊加的卡片(按 stack_order 降序排列,最新的在前)
        stacked_cards = GameCard.includes(:card)
                                .where(parent_card_id: game_card.id)
                                .order(stack_order: :desc)
                                .map do |stacked|
          {
            id: stacked.id,
            name: stacked.card.name,
            img_url: stacked.card.img_url,
            card_type: stacked.card.card_type,
            stack_order: stacked.stack_order
          }
        end

        Rails.logger.info "   ✅ 格式化成功"

        {
          id: game_card.id,
          card_unique_id: game_card.card_unique_id,
          name: game_card.card.name,
          img_url: game_card.card.img_url,
          card_type: game_card.card.card_type,
          hp: game_card.card.hp,
          stage: game_card.card.stage,
          damage_taken: game_card.damage_taken || 0,
          zone: game_card.zone,
          zone_position: game_card.zone_position,
          attached_energies: attached_energies,
          stacked_cards: stacked_cards
        }
      end


      def get_hand_cards(game_state)
        GameCard.includes(:card)
                .where(
                  game_state_id: game_state.id,
                  user_id: @current_user.id,
                  zone: 'hand',
                  parent_card_id: nil,
                  attached_to_game_card_id: nil
                )
                .map { |gc| format_game_card(gc) }
                .compact
      end


      def get_active_pokemon(game_state)
        card = GameCard.includes(:card)
                       .find_by(
                         game_state_id: game_state.id,
                         user_id: @current_user.id,
                         zone: 'active',
                         parent_card_id: nil,
                         attached_to_game_card_id: nil
                       )
        card ? format_game_card(card) : nil
      end


      def get_bench_pokemon(game_state)
        GameCard.includes(:card)
                .where(
                  game_state_id: game_state.id,
                  user_id: @current_user.id,
                  zone: 'bench',
                  parent_card_id: nil,
                  attached_to_game_card_id: nil
                )
                .order(:zone_position)
                .map { |gc| format_game_card(gc) }
                .compact
      end


      def get_deck_count(game_state)
        GameCard.where(
          game_state_id: game_state.id,
          user_id: @current_user.id,
          zone: 'deck'
        ).count
      end


      def get_prize_count(game_state)
        GameCard.where(
          game_state_id: game_state.id,
          user_id: @current_user.id,
          zone: 'prize'
        ).count
      end


      def get_discard_count(game_state)
        GameCard.where(
          game_state_id: game_state.id,
          user_id: @current_user.id,
          zone: 'discard'
        ).count
      end


      # 區域名稱對應
      def zone_name(zone)
        {
          'hand' => '手牌',
          'discard' => '棄牌堆',
          'deck' => '牌堆',
          'active' => '戰鬥場',
          'bench' => '備戰區',
          'prize' => '獎勵卡',
          'attached' => '附加'
        }[zone] || zone
      end
    end
  end
end
