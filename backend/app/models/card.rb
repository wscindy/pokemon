# app/models/card.rb
class Card < ApplicationRecord
  # 設定主鍵
  self.primary_key = 'card_unique_id'
  
  # 關聯
  has_many :user_cards, foreign_key: :card_unique_id, primary_key: :card_unique_id, dependent: :destroy
  has_many :users, through: :user_cards
  has_many :card_types, foreign_key: :card_unique_id, primary_key: :card_unique_id, dependent: :destroy
  has_many :attacks, -> { order(position: :asc) }, foreign_key: :card_unique_id, primary_key: :card_unique_id, dependent: :destroy
  has_many :card_abilities, foreign_key: :card_unique_id, primary_key: :card_unique_id, dependent: :destroy
  has_many :card_tags, foreign_key: :card_unique_id, primary_key: :card_unique_id, dependent: :destroy
  
  # 驗證
  validates :card_unique_id, presence: true, uniqueness: true
  validates :name, presence: true
  
  # Scope：搜尋卡片名稱（LIKE %keyword%）
  scope :search_by_name, ->(keyword) { 
    where("name ILIKE ?", "%#{keyword}%") if keyword.present? 
  }
  
  # Scope：依卡片類型篩選
  scope :by_card_type, ->(type) { 
    where(card_type: type) if type.present? 
  }
  
  # 方法：判斷是否為基本能量卡
  def basic_energy?
    card_type == 'Energy' && rule_box.blank?
  end
end
