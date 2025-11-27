class CreateRoomParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :room_participants do |t|
      t.references :room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false  # 'host', 'guest'
      t.boolean :ready_status, default: false

      t.timestamp :joined_at, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :room_participants, [:room_id, :user_id], unique: true
  end
end
