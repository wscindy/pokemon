Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # 卡片相關
      resources :cards, only: [:index, :show] do
        get :search, on: :collection  
      end
      
      # 牌組管理
      resource :deck, only: [:show, :create] do
        post :validate, on: :collection
      end

      # delete cards
      resource :deck, only: [:show, :create, :destroy] do
        post :validate, on: :collection
      end
      post 'games/initialize', to: 'games#initialize_game'
        post 'games/:id/setup', to: 'games#setup_game'
        get 'games/:id/state', to: 'games#game_state'

    end
  end
end

