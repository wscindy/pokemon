# db/migrate/YYYYMMDDHHMMSS_add_missing_indexes_to_game_cards.rb
class AddMissingIndexesToGameCards < ActiveRecord::Migration[8.0]
  def change
    # 檢查並新增所有需要的 index
    
    # 主鍵的 unique index（通常已存在，但確保一下）
    unless index_exists?(:game_cards, :id, unique: true)
      add_index :game_cards, :id, unique: true
    end
    
    # 外鍵的 index
    unless index_exists?(:game_cards, :game_state_id)
      add_index :game_cards, :game_state_id
    end
    
    unless index_exists?(:game_cards, :user_id)
      add_index :game_cards, :user_id
    end
    
    unless index_exists?(:game_cards, :card_unique_id)
      add_index :game_cards, :card_unique_id
    end
    
    unless index_exists?(:game_cards, :attached_to_game_card_id)
      add_index :game_cards, :attached_to_game_card_id
    end
    
    unless index_exists?(:game_cards, :parent_card_id)
      add_index :game_cards, :parent_card_id
    end
    
    # 複合 index 用於常見查詢
    unless index_exists?(:game_cards, [:user_id, :zone])
      add_index :game_cards, [:user_id, :zone]
    end
    
    unless index_exists?(:game_cards, [:game_state_id, :user_id, :zone])
      add_index :game_cards, [:game_state_id, :user_id, :zone]
    end
    
    unless index_exists?(:game_cards, [:game_state_id, :zone])
      add_index :game_cards, [:game_state_id, :zone]
    end
  end
end
