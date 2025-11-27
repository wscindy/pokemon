class CreateGameCards < ActiveRecord::Migration[8.0]
  def up
    # 清理可能存在的索引
    execute <<-SQL
      DROP INDEX IF EXISTS index_game_cards_on_game_state_id;
      DROP INDEX IF EXISTS index_game_cards_on_user_id;
      DROP INDEX IF EXISTS index_game_cards_on_card_unique_id;
      DROP INDEX IF EXISTS index_game_cards_on_state_user_zone;
      DROP INDEX IF EXISTS index_game_cards_on_attached_to_game_card_id;
    SQL
    
    drop_table :game_cards, if_exists: true, force: :cascade
    
    create_table :game_cards do |t|
      t.references :game_state, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false
      t.string :card_unique_id, null: false
      t.string :zone, null: false
      t.integer :zone_position
      t.references :attached_to_game_card, foreign_key: { to_table: :game_cards }, index: false
      t.integer :damage_taken, default: 0, null: false
      t.string :special_condition
      t.boolean :is_evolved_this_turn, default: false

      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_foreign_key :game_cards, :cards, column: :card_unique_id, primary_key: :card_unique_id

    add_index :game_cards, :game_state_id
    add_index :game_cards, :user_id
    add_index :game_cards, :card_unique_id
    add_index :game_cards, [:game_state_id, :user_id, :zone], name: 'index_game_cards_on_state_user_zone'
    add_index :game_cards, :attached_to_game_card_id
  end

  def down
    drop_table :game_cards, if_exists: true, force: :cascade
  end
end
