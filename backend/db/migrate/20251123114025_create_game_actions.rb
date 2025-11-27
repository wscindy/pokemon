class CreateGameActions < ActiveRecord::Migration[8.0]
  def up
    # 清理可能存在的索引
    execute <<-SQL
      DROP INDEX IF EXISTS index_game_actions_on_game_state_id;
      DROP INDEX IF EXISTS index_game_actions_on_user_id;
      DROP INDEX IF EXISTS index_game_actions_on_source_card_id;
      DROP INDEX IF EXISTS index_game_actions_on_target_card_id;
      DROP INDEX IF EXISTS index_game_actions_on_state_and_round;
    SQL
    
    drop_table :game_actions, if_exists: true, force: :cascade
    
    create_table :game_actions do |t|
      t.references :game_state, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false
      t.integer :round_number, null: false
      t.string :action_type, null: false
      t.references :source_card, foreign_key: { to_table: :game_cards }, index: false
      t.references :target_card, foreign_key: { to_table: :game_cards }, index: false
      t.text :action_description, null: false

      t.timestamp :created_at, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :game_actions, :game_state_id
    add_index :game_actions, :user_id
    add_index :game_actions, [:game_state_id, :round_number], name: 'index_game_actions_on_state_and_round'
  end

  def down
    drop_table :game_actions, if_exists: true, force: :cascade
  end
end
