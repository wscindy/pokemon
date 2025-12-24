module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user_from_token!  # ← 🔥 所有方法都需要認證
      before_action :set_user, only: [:show, :update, :deck, :add_card, :remove_card]
      
      # GET /api/v1/users/:id
      def show
        render json: @user.as_json(
          include: {
            user_cards: {
              include: {
                card: { only: [:card_unique_id, :name, :img_url, :card_type] }
              }
            }
          }
        )
      end
      
      # POST /api/v1/users
      def create
        @user = User.new(user_params)
        
        if @user.save
          render json: @user, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # PATCH/PUT /api/v1/users/:id
      def update
        if @user.update(user_params)
          render json: @user
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # PATCH/PUT /api/v1/users/profile
      def update_profile
        if @current_user.update(profile_params)
          render json: {
            user: user_json(@current_user),
            message: 'Profile updated successfully'
          }, status: :ok
        else
          render json: {
            error: 'Failed to update profile',
            details: @current_user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/users/:id/deck
      def deck
        @deck_cards = @user.deck_cards.includes(:card)
        
        render json: {
          user: @user.as_json(only: [:id, :name, :email]),
          deck: @deck_cards.as_json(
            include: {
              card: {
                include: [:card_types, :card_tags]
              }
            }
          ),
          deck_count: @user.deck_count
        }
      end
      
      # POST /api/v1/users/:id/add_card
      def add_card
        card = Card.find_by!(card_unique_id: params[:card_unique_id])
        
        user_card = @user.user_cards.build(
          card_unique_id: card.card_unique_id,
          is_active: true
        )
        
        if user_card.save
          render json: {
            message: "Card added to deck",
            deck_count: @user.deck_count
          }, status: :created
        else
          render json: { errors: user_card.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/users/:id/remove_card
      def remove_card
        user_card = @user.user_cards.find_by!(card_unique_id: params[:card_unique_id])
        user_card.destroy
        
        render json: {
          message: "Card removed from deck",
          deck_count: @user.deck_count
        }
      end
      
      private
      
      def set_user
        @user = User.find(params[:id])
      end
      
      def user_params
        params.require(:user).permit(:email, :name, :uid, :provider, :avatar_url, :online_status)
      end
      
      def profile_params
        params.require(:user).permit(:name, :avatar_url)
      end
      
      def user_json(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          avatar_url: user.avatar_url,
          online_status: user.online_status
        }
      end
    end
  end
end
