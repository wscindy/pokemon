module Api
  module V1
    class DecksController < ApplicationController
      before_action :authenticate_user_from_token!  # ✏️ 改用正確的認證
      
      # GET /api/v1/deck - 取得使用者目前的牌組
      def show
        deck_cards = @current_user.user_cards.in_deck.includes(:card)
        
        deck_data = deck_cards.map do |user_card|
          {
            card_unique_id: user_card.card_unique_id,
            name: user_card.card.name,
            img_url: user_card.card.img_url,
            card_type: user_card.card.card_type,
            hp: user_card.card.hp,
            stage: user_card.card.stage,
            quantity: user_card.quantity
          }
        end
        
        total_cards = deck_cards.sum(:quantity)
        
        render json: {
          success: true,
          data: {
            cards: deck_data,
            total_cards: total_cards,
            is_complete: total_cards == 60
          }
        }
      end
      
      # POST /api/v1/deck - 儲存牌組（覆蓋舊牌組）
      def create
        cards_data = params[:cards]
        
        unless cards_data.is_a?(Array)
          render json: { 
            success: false,
            error: '參數格式錯誤' 
          }, status: :bad_request
          return
        end
        
        validation_result = DeckValidator.validate(cards_data)
        unless validation_result[:valid]
          render json: { 
            success: false,
            error: validation_result[:error],
            errors: validation_result[:errors]
          }, status: :unprocessable_entity
          return
        end
        
        begin
          ActiveRecord::Base.transaction do
            # ✏️ 清空**當前用戶**的牌組
            @current_user.user_cards.in_deck.update_all(is_in_deck: false, quantity: 0)
            
            cards_data.each do |card_data|
              card_unique_id = card_data['card_unique_id']
              quantity = card_data['quantity'].to_i
              
              unless Card.exists?(card_unique_id: card_unique_id)
                raise ActiveRecord::Rollback, "卡片 #{card_unique_id} 不存在"
              end
              
              # ✏️ 找或建立**當前用戶**的卡片
              user_card = @current_user.user_cards.find_or_initialize_by(card_unique_id: card_unique_id)
              user_card.is_in_deck = true
              user_card.quantity = quantity
              user_card.save!
            end
          end
          
          render json: {
            success: true,
            message: '牌組儲存成功',
            data: {
              total_cards: cards_data.sum { |c| c['quantity'].to_i }
            }
          }
        rescue => e
          render json: { 
            success: false,
            error: "儲存失敗: #{e.message}" 
          }, status: :internal_server_error
        end
      end
      
      # DELETE /api/v1/deck - 刪除牌組
      def destroy
        begin
          # ✏️ 清空**當前用戶**的牌組
          @current_user.user_cards.in_deck.update_all(is_in_deck: false, quantity: 0)
          
          render json: {
            success: true,
            message: '牌組已刪除'
          }
        rescue => e
          render json: { 
            success: false,
            error: "刪除失敗: #{e.message}" 
          }, status: :internal_server_error
        end
      end
      
      # POST /api/v1/deck/validate - 驗證牌組
      def validate
        cards_data = params[:cards]
        result = DeckValidator.validate(cards_data)
        render json: result
      end
      
      private
      
      # ✏️ 改用正確的認證方法
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
          render json: { error: 'User not found' }, status: :unauthorized
        end
      end
    end
  end
end
