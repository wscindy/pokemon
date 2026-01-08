class FixCardsNameIndexToGin < ActiveRecord::Migration[7.0]
  def up
    # 1. 啟用 pg_trgm extension
    enable_extension 'pg_trgm'
    
    # 2. 刪除舊的 btree 索引
    remove_index :cards, name: 'idx_cards_name' if index_exists?(:cards, :name, name: 'idx_cards_name')
    
    # 3. 建立新的 GIN 索引
    add_index :cards, :name, 
              using: :gin, 
              opclass: :gin_trgm_ops,
              name: 'index_cards_on_name_gin_trgm'
  end
  
  def down
    # 回滾時恢復 btree 索引
    remove_index :cards, name: 'index_cards_on_name_gin_trgm'
    add_index :cards, :name, name: 'idx_cards_name'
  end
end
