class UpdateUserCardsForDeck < ActiveRecord::Migration[8.0]
  def change
    # 重新命名 is_active 為 is_in_deck
    rename_column :user_cards, :is_active, :is_in_deck
    
    # 新增 quantity 欄位
    add_column :user_cards, :quantity, :integer, default: 0, null: false
    
    # 更新現有資料：如果 is_in_deck = true，則 quantity = 1
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE user_cards SET quantity = 1 WHERE is_in_deck = true;
        SQL
      end
    end
  end
end
