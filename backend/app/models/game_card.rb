class GameCard < ApplicationRecord
  belongs_to :game_state
  belongs_to :user
  belongs_to :card, foreign_key: :card_unique_id, primary_key: :card_unique_id
  belongs_to :attached_to_game_card, class_name: 'GameCard', optional: true
  has_many :attached_cards, class_name: 'GameCard', foreign_key: :attached_to_game_card_id

  validates :zone, presence: true, inclusion: { in: %w[deck hand active bench prize discard] }

  scope :in_deck, -> { where(zone: 'deck') }
  scope :in_hand, -> { where(zone: 'hand') }
  scope :active, -> { where(zone: 'active') }
  scope :on_bench, -> { where(zone: 'bench').order(:zone_position) }
  scope :in_prizes, -> { where(zone: 'prize') }
  scope :in_discard, -> { where(zone: 'discard') }

  def is_knocked_out?
    return false unless card.hp
    damage_taken >= card.hp
  end

  def move_to_zone(new_zone, position = nil)
    update(zone: new_zone, zone_position: position)
  end
end
