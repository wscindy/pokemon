class CreateGameStates < ActiveRecord::Migration[8.0]
  def up
    # 先清理所有可能存在的索引
    execute <<-SQL
      DROP INDEX IF EXISTS index_game_states_on_room_id;
      DROP INDEX IF EXISTS index_game_states_on_status;
    SQL
    
    drop_table :game_states, if_exists: true, force: :cascade
    
    create_table :game_states do |t|
      t.references :room, null: false, foreign_key: true, index: false  # 關鍵:先不建索引
      t.references :player1, null: false, foreign_key: { to_table: :users }
      t.references :player2, null: false, foreign_key: { to_table: :users }
      t.references :current_turn_user, null: false, foreign_key: { to_table: :users }
      t.integer :round_number, default: 1, null: false
      t.integer :player1_prizes_remaining, default: 6, null: false
      t.integer :player2_prizes_remaining, default: 6, null: false
      t.string :status, default: 'setup', null: false
      t.references :winner, foreign_key: { to_table: :users }

      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end

    # 然後手動建立 unique 索引
    add_index :game_states, :room_id, unique: true
    add_index :game_states, :status
  end

  def down
    drop_table :game_states, if_exists: true, force: :cascade
  end
end
