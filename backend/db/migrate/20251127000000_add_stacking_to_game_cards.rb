# db/migrate/20251127000000_add_stacking_to_game_cards.rb
class AddStackingToGameCards < ActiveRecord::Migration[8.0]
  def change
    # 🔥 加上條件檢查，避免重複新增
    unless column_exists?(:game_cards, :parent_card_id)
      add_column :game_cards, :parent_card_id, :bigint
    end
    
    unless column_exists?(:game_cards, :stack_order)
      add_column :game_cards, :stack_order, :integer, default: 0
    end
    
    # 🔥 同時加上 index
    unless index_exists?(:game_cards, :parent_card_id)
      add_index :game_cards, :parent_card_id
    end
  end
end
