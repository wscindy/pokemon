# app/models/user.rb
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]
  # 驗證
  validates :email, presence: true, uniqueness: true
  validates :uid, uniqueness: { scope: :provider }, if: -> { uid.present? }
  
  # 關聯：牌卡系統
  has_many :user_cards, dependent: :destroy
  has_many :cards, through: :user_cards
  
  # 關聯：房間系統
  has_many :created_rooms, class_name: 'Room', foreign_key: 'creator_id', dependent: :destroy
  has_many :room_participants, dependent: :destroy
  has_many :rooms, through: :room_participants
  
  # 關聯：遊戲狀態
  has_many :games_as_player1, class_name: 'GameState', foreign_key: 'player1_id', dependent: :destroy
  has_many :games_as_player2, class_name: 'GameState', foreign_key: 'player2_id', dependent: :destroy
  has_many :current_turn_games, class_name: 'GameState', foreign_key: 'current_turn_user_id', dependent: :nullify
  
  # 關聯：訊息
  has_many :messages, dependent: :destroy
  
  # 方法：取得牌組中的卡片
  def deck_cards
    user_cards.in_deck.includes(:card)
  end
  
  # 方法：計算牌組總卡片數（應該是 60 張）
  def deck_total_count
    user_cards.in_deck.sum(:quantity)
  end
  
  # 方法：檢查牌組是否完整（60張）
  def deck_complete?
    deck_total_count == 60
  end

   # OAuth callback handler
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.avatar_url = auth.info.image
      user.password = Devise.friendly_token[0, 20]
    end
  end

  # Generate refresh token
  def generate_refresh_token!
    self.refresh_token = SecureRandom.hex(32)
    self.refresh_token_expires_at = 30.days.from_now
    save!
  end

   # Check if refresh token is valid
  def refresh_token_valid?
    refresh_token.present? && refresh_token_expires_at > Time.current
  end
end
