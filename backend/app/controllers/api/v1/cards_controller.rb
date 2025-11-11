module Api
  module V1
    class CardsController < ApplicationController
      # GET /api/v1/cards
      def index
        @cards = Card.includes(:card_types, :card_tags)
                     .limit(params[:limit] || 100)
                     .offset(params[:offset] || 0)
        
        render json: {
          success: true,
          cards: @cards.as_json(include: [:card_types, :card_tags]),
          total: Card.count
        }
      end
      
      # GET /api/v1/cards/:id
      def show
        @card = Card.find_by(card_unique_id: params[:id])
        
        if @card.nil?
          render json: { 
            success: false,
            error: '找不到此卡片' 
          }, status: :not_found
          return
        end
        
        render json: {
          success: true,
          data: @card.as_json(
            include: {
              card_types: { only: [:type_name] },
              attacks: { 
                only: [:name, :damage, :effect_description, :position],
                include: {
                  attack_energy_costs: { only: [:energy_type, :energy_count] }
                }
              },
              card_abilities: { only: [:name, :effect] },
              card_tags: { only: [:tag_name] }
            }
          )
        }
      end
      
      # GET /api/v1/cards/search?q=皮卡丘
      def search
        query = params[:q]
        type_filter = params[:type]
        
        if query.blank?
          render json: { 
            success: false,
            error: '請輸入搜尋關鍵字' 
          }, status: :bad_request
          return
        end
        
        @cards = Card.includes(:card_types, :card_tags)
        
        # 使用 ILIKE 而不是 LIKE（不區分大小寫）
        @cards = @cards.where("name ILIKE ?", "%#{query}%") if query.present?
        
        if type_filter.present?
          @cards = @cards.joins(:card_types)
                         .where(card_types: { type_name: type_filter })
        end
        
        render json: {
          success: true,
          cards: @cards.limit(100).as_json(
            only: [:card_unique_id, :name, :img_url, :card_type, :hp, :stage, :set_name],
            include: {
              card_types: { only: [:type_name] },
              card_tags: { only: [:tag_name] }
            }
          ),
          total: @cards.count
        }
      end
    end
  end
end
