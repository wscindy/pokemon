class Room < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :room_participants, dependent: :destroy
  has_many :users, through: :room_participants
  has_one :game_state, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true
  validates :room_type, presence: true, inclusion: { in: %w[public private friend] }
  validates :status, presence: true, inclusion: { in: %w[waiting playing finished] }

  scope :waiting, -> { where(status: 'waiting') }
  scope :playing, -> { where(status: 'playing') }

  def full?
    room_participants.count >= max_players
  end

  def ready_to_start?
    room_participants.count == 2 && room_participants.all?(&:ready_status)
  end
end
