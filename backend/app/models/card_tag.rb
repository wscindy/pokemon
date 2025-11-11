# app/models/card_tag.rb
class CardTag < ApplicationRecord
  belongs_to :card, foreign_key: :card_unique_id, primary_key: :card_unique_id
  
  validates :card_unique_id, presence: true
  validates :tag_name, presence: true
end
