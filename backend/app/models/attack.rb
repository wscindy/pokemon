# app/models/attack.rb
class Attack < ApplicationRecord
  belongs_to :card, foreign_key: :card_unique_id, primary_key: :card_unique_id
  has_many :attack_energy_costs, dependent: :destroy
  
  validates :card_unique_id, presence: true
  validates :name, presence: true
  
  # 預設按 position 排序
  default_scope { order(position: :asc) }
end
