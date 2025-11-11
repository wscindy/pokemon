module Api
  class DecksController < ApplicationController
    # before_action :authenticate_user!  還沒串google account
    
    
    # 暫時用固定使用者來測試
    def current_user
      @current_user ||= User.first || User.create!(email: 'test@example.com', name: 'Test User')
    end
    
    # GET /api/deck - 取得使用者目前的牌組
    def show
      deck_cards = current_user.user_cards.in_deck.includes(:card)
      
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
    
    # POST /api/deck - 儲存牌組（覆蓋舊牌組）
    def create
      cards_data = params[:cards] # [{ card_unique_id: "xxx", quantity: 4 }, ...]
      
      # 驗證參數
      unless cards_data.is_a?(Array)
        render json: { 
          success: false,
          error: '參數格式錯誤' 
        }, status: :bad_request
        return
      end
      
      # 驗證牌組
      validation_result = DeckValidator.validate(cards_data)
      unless validation_result[:valid]
        render json: { 
          success: false,
          error: validation_result[:error],
          errors: validation_result[:errors]
        }, status: :unprocessable_entity
        return
      end
      
      # 使用 transaction 確保資料一致性
      begin
        ActiveRecord::Base.transaction do
          # 1. 清空舊牌組
          current_user.user_cards.in_deck.update_all(is_in_deck: false, quantity: 0)
          
          # 2. 新增新牌組
          cards_data.each do |card_data|
            card_unique_id = card_data[:card_unique_id] || card_data['card_unique_id']
            quantity = (card_data[:quantity] || card_data['quantity']).to_i
            
            # 檢查卡片是否存在
            unless Card.exists?(card_unique_id: card_unique_id)
              raise ActiveRecord::Rollback, "卡片 #{card_unique_id} 不存在"
            end
            
            # 新增或更新 user_card
            user_card = current_user.user_cards.find_or_initialize_by(card_unique_id: card_unique_id)
            user_card.is_in_deck = true
            user_card.quantity = quantity
            user_card.save!
          end
        end
        
        render json: {
          success: true,
          message: '牌組儲存成功',
          data: {
            total_cards: cards_data.sum { |c| (c[:quantity] || c['quantity']).to_i }
          }
        }
      rescue => e
        render json: { 
          success: false,
          error: "儲存失敗: #{e.message}" 
        }, status: :internal_server_error
      end
    end
    
    # POST /api/deck/validate - 驗證牌組是否合法（前端可以呼叫）
    def validate
      cards_data = params[:cards]
      
      result = DeckValidator.validate(cards_data)
      
      render json: result
    end
  end
end
