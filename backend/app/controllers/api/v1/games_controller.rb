module Api
  module V1
    class GamesController < ApplicationController
      # ========== before_action 區塊 ==========
      before_action :set_user
      before_action :set_game_state, only: [
        :setup_game, :game_state, :play_card, :attach_energy,
        :move_card, :stack_card, :update_damage, :transfer_energy, :end_turn,
        :draw_cards, :pick_from_discard, :take_prize
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
          hand: get_hand_cards(@game_state),
          active_pokemon: get_active_pokemon(@game_state),
          bench: get_bench_pokemon(@game_state),
          deck_count: get_deck_count(@game_state),
          prize_count: get_prize_count(@game_state),
          discard_count: get_discard_count(@game_state)
        }
      end

      def play_card
        game_card = GameCard.find(params[:card_id])
        
        result = CardPlayService.new(@game_state, @current_user, game_card)
                                .play_basic_pokemon(params[:position])

        if result[:success]
          render json: {
            message: '出牌成功',
            game_card: format_game_card(result[:game_card])
          }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
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

      # 🆕 移動卡牌到指定區域
      def move_card
        game_card = GameCard.find(params[:card_id])
        to_zone = params[:to_zone]
        to_position = params[:to_position]

        # 檢查卡片擁有者
        unless game_card.user_id == @current_user.id
          render json: { error: '無權操作此卡片' }, status: :forbidden
          return
        end

        # 如果是疊加的卡片,先取消疊加
        game_card.unstack if game_card.parent_card_id.present?

        # 移動卡片
        if game_card.move_to_zone(to_zone, to_position)
          render json: { 
            message: "卡片已移至#{zone_name(to_zone)}",
            game_card: format_game_card(game_card)
          }, status: :ok
        else
          render json: { error: '移動失敗' }, status: :unprocessable_entity
        end
      end

      # 🆕 疊加卡片
      def stack_card
        card_to_stack = GameCard.find(params[:card_id])
        target_card = GameCard.find(params[:target_card_id])

        # 檢查權限
        unless card_to_stack.user_id == @current_user.id && target_card.user_id == @current_user.id
          render json: { error: '無權操作此卡片' }, status: :forbidden
          return
        end

        # 執行疊加
        if target_card.stack_card(card_to_stack)
          render json: { 
            message: '疊加成功',
            target_card: format_game_card(target_card)
          }, status: :ok
        else
          render json: { error: '疊加失敗' }, status: :unprocessable_entity
        end
      end

      # 🆕 更新傷害值
      def update_damage
        pokemon = GameCard.find(params[:pokemon_id])
        damage_value = params[:damage_taken].to_i

        # 檢查權限
        unless pokemon.user_id == @current_user.id
          render json: { error: '無權操作此卡片' }, status: :forbidden
          return
        end

        if pokemon.update(damage_taken: [0, damage_value].max)
          render json: { 
            message: '傷害更新成功',
            pokemon: format_game_card(pokemon)
          }, status: :ok
        else
          render json: { error: '更新失敗' }, status: :unprocessable_entity
        end
      end

      # 🆕 轉移能量卡
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
          if energy_card.update(attached_to_game_card_id: nil, zone: to_zone)
            render json: { message: "能量已移至#{zone_name(to_zone)}" }, status: :ok
          else
            render json: { error: '移動失敗' }, status: :unprocessable_entity
          end
        else
          render json: { error: '請指定目標' }, status: :unprocessable_entity
        end
      end

      # 🆕 結束回合
      def end_turn
        # 切換到對手
        opponent = @game_state.opponent_of(@current_user)
        
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

      # 🆕 從牌庫抽牌
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

        if deck_cards.empty?
          render json: { error: '牌庫已空' }, status: :unprocessable_entity
          return
        end

        # 移動到手牌
        deck_cards.each do |card|
          card.update(zone: 'hand', zone_position: nil)
        end

        render json: {
          message: "抽了 #{deck_cards.count} 張牌",
          drawn_cards: deck_cards.map { |gc| format_game_card(gc) }
        }, status: :ok
      end

      # 🆕 從棄牌堆撿牌
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

        if discard_cards.empty?
          render json: { error: '棄牌堆已空' }, status: :unprocessable_entity
          return
        end

        # 移動到手牌
        discard_cards.each do |card|
          card.update(zone: 'hand', zone_position: nil)
        end

        render json: {
          message: "從棄牌堆撿了 #{discard_cards.count} 張牌",
          picked_cards: discard_cards.map { |gc| format_game_card(gc) }
        }, status: :ok
      end

      # 🆕 領取獎勵卡
      def take_prize
        prize_card = GameCard.includes(:card)
                            .where(
                              game_state_id: @game_state.id,
                              user_id: @current_user.id,
                              zone: 'prize'
                            )
                            .first

        unless prize_card
          render json: { error: '沒有獎勵卡可領取' }, status: :unprocessable_entity
          return
        end

        # 移動到手牌
        if prize_card.update(zone: 'hand', zone_position: nil)
          render json: {
            message: '領取獎勵卡成功',
            prize_card: format_game_card(prize_card)
          }, status: :ok
        else
          render json: { error: '領取失敗' }, status: :unprocessable_entity
        end
      end

      # ========== Private Methods ==========
      private

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
        # 🆕 只格式化主卡(避免遞迴)
        return nil unless game_card.main_card?

        # 查詢附加的能量卡
        attached_energies = GameCard.includes(:card)
                                    .where(attached_to_game_card_id: game_card.id)
                                    .map do |energy|
          {
            id: energy.id,
            name: energy.card.name,
            img_url: energy.card.img_url
          }
        end

        # 🆕 查詢疊加的卡片
        stacked_cards = game_card.all_stacked_cards.map do |stacked|
          {
            id: stacked.id,
            name: stacked.card.name,
            img_url: stacked.card.img_url,
            card_type: stacked.card.card_type,
            stack_order: stacked.stack_order
          }
        end

        {
          id: game_card.id,
          card_unique_id: game_card.card_unique_id,
          name: game_card.card.name,
          img_url: game_card.card.img_url,
          card_type: game_card.card.card_type,
          hp: game_card.card.hp,
          stage: game_card.card.stage,  # 🆕 新增 stage
          damage_taken: game_card.damage_taken,
          zone: game_card.zone,
          zone_position: game_card.zone_position,
          attached_energies: attached_energies,
          stacked_cards: stacked_cards  # 🆕 新增疊加卡片
        }
      end

      def get_hand_cards(game_state)
        GameCard.includes(:card)
                .main_cards  # 🆕 只取主卡
                .where(game_state_id: game_state.id, user_id: @current_user.id, zone: 'hand')
                .map { |gc| format_game_card(gc) }
      end

      def get_active_pokemon(game_state)
        card = GameCard.includes(:card)
                       .main_cards  # 🆕 只取主卡
                       .find_by(game_state_id: game_state.id, user_id: @current_user.id, zone: 'active')
        card ? format_game_card(card) : nil
      end

      def get_bench_pokemon(game_state)
        GameCard.includes(:card)
                .main_cards  # 🆕 只取主卡
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

      # 🆕 區域名稱對應
      def zone_name(zone)
        {
          'hand' => '手牌',
          'discard' => '棄牌堆',
          'deck' => '牌堆',
          'active' => '戰鬥場',
          'bench' => '備戰區',
          'prize' => '獎勵卡'
        }[zone] || zone
      end
    end
  end
end
