Rails.application.routes.draw do
  # devise_for :users, skip: [:sessions, :registrations], controllers: {
  #   omniauth_callbacks: 'users/omniauth_callbacks'
  # }

  namespace :api do
    namespace :v1 do
      # Auth endpoints
      post 'auth/google', to: 'auth#google'
      post 'auth/refresh', to: 'auth#refresh'
      delete 'auth/logout', to: 'auth#logout'
      get 'auth/me', to: 'auth#me'

      # User profile (移到這裡)
      patch 'users/profile', to: 'users#update_profile'
      put 'users/profile', to: 'users#update_profile'

      # 卡片相關
      resources :cards, only: [:index, :show] do
        get :search, on: :collection  
      end
      
      # 牌組管理
      resource :deck, only: [:show, :create, :destroy] do
        post :validate, on: :collection
      end

      # 遊戲相關
      post 'games/initialize', to: 'games#initialize_game'
      post 'games/:id/setup', to: 'games#setup_game'
      get 'games/:id/state', to: 'games#game_state'
      post 'games/:id/play_card', to: 'games#play_card'
      post 'games/:id/attach_energy', to: 'games#attach_energy'
      
      # 遊戲操作
      post 'games/:id/move_card', to: 'games#move_card'
      post 'games/:id/stack_card', to: 'games#stack_card'
      post 'games/:id/update_damage', to: 'games#update_damage'
      post 'games/:id/transfer_energy', to: 'games#transfer_energy'
      post 'games/:id/end_turn', to: 'games#end_turn'

      # 抽牌相關
      post 'games/:id/draw_cards', to: 'games#draw_cards'
      post 'games/:id/pick_from_discard', to: 'games#pick_from_discard'
      post 'games/:id/take_prize', to: 'games#take_prize'
      post 'games/:id/move_stadium_card', to: 'games#move_stadium_card'
    end
  end
  
  # ActionCable
  mount ActionCable.server => '/cable'

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
