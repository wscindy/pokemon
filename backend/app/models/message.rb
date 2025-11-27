class Message < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validates :content, presence: true
  validates :message_type, presence: true, inclusion: { in: %w[chat system game_action] }

  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :chat_only, -> { where(message_type: 'chat') }
end
