class GameState < ApplicationRecord
  belongs_to :room
  belongs_to :player1, class_name: 'User'
  belongs_to :player2, class_name: 'User', optional: true
  belongs_to :current_turn_user, class_name: 'User'
  belongs_to :winner, class_name: 'User', optional: true

  has_many :game_cards, dependent: :destroy
  has_many :game_actions, dependent: :destroy

  validates :status, presence: true, inclusion: { in: %w[setup playing finished] }
  validates :round_number, numericality: { greater_than: 0 }

  scope :in_progress, -> { where(status: 'playing') }

  def current_player?(user)
    current_turn_user_id == user.id
  end

  def opponent_of(user)
    user.id == player1_id ? player2 : player1
  end
end
