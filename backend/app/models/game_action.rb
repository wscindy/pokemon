class GameAction < ApplicationRecord
  belongs_to :game_state
  belongs_to :user
  belongs_to :source_card, class_name: 'GameCard', optional: true
  belongs_to :target_card, class_name: 'GameCard', optional: true

  validates :action_type, presence: true
  validates :action_description, presence: true

  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :by_round, ->(round) { where(round_number: round) }
end
