class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.string :name, null: false
      t.string :room_type, null: false  # 'public', 'private', 'friend'
      t.string :password
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :status, default: 'waiting', null: false  # 'waiting', 'playing', 'finished'
      t.integer :max_players, default: 2, null: false

      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :rooms, :status
  end
end
