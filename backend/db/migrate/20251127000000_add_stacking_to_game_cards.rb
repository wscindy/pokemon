class AddStackingToGameCards < ActiveRecord::Migration[8.0]
  def change
    add_column :game_cards, :parent_card_id, :bigint
    add_column :game_cards, :stack_order, :integer, default: 0
    
    add_index :game_cards, :parent_card_id
    add_foreign_key :game_cards, :game_cards, column: :parent_card_id
  end
end
