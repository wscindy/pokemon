# app/models/user_card.rb
class UserCard < ApplicationRecord
  # 關聯
  belongs_to :user
  belongs_to :card, foreign_key: :card_unique_id, primary_key: :card_unique_id
  
  # 驗證
  validates :user_id, presence: true
  validates :card_unique_id, presence: true
  validates :card_unique_id, uniqueness: { scope: :user_id, message: "已經存在於此使用者的收藏中" }
  validates :quantity, numericality: { 
    only_integer: true, 
    greater_than_or_equal_to: 0,
    message: "數量必須大於等於 0"
  }
  
  # Scope：在牌組中的卡片（使用 is_in_deck）
  scope :in_deck, -> { where(is_in_deck: true) }
  
  # Scope：不在牌組中的卡片
  scope :not_in_deck, -> { where(is_in_deck: false) }
  
  # 方法：加入牌組
  def add_to_deck(quantity)
    update(is_in_deck: true, quantity: quantity)
  end
  
  # 方法：從牌組移除
  def remove_from_deck
    update(is_in_deck: false, quantity: 0)
  end
end
