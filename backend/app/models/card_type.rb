# app/models/card_type.rb
class CardType < ApplicationRecord
  belongs_to :card, foreign_key: :card_unique_id, primary_key: :card_unique_id
  
  validates :card_unique_id, presence: true
  validates :type_name, presence: true
end
