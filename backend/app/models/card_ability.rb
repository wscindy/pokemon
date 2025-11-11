# app/models/card_ability.rb
class CardAbility < ApplicationRecord
  belongs_to :card, foreign_key: :card_unique_id, primary_key: :card_unique_id
  
  validates :card_unique_id, presence: true
  validates :name, presence: true
end
