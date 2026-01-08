class AddSearchIndexesToCards < ActiveRecord::Migration[7.0]
  def change
    # 註解掉或刪掉這段
    # enable_extension 'pg_trgm'
    # add_index :cards, :name, using: :gin, opclass: :gin_trgm_ops
    
    # 保留這些 ✅
    add_index :card_types, :card_unique_id
    add_index :card_types, [:type_name, :card_unique_id]
    add_index :card_tags, :card_unique_id
  end
end