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
    end
  end
end

