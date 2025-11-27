class RoomParticipant < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validates :role, presence: true, inclusion: { in: %w[host guest] }
  validates :user_id, uniqueness: { scope: :room_id }
end
