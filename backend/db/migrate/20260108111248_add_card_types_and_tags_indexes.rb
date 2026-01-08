class AddCardTypesAndTagsIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :card_types, :card_unique_id unless index_exists?(:card_types, :card_unique_id)
    add_index :card_types, [:type_name, :card_unique_id] unless index_exists?(:card_types, [:type_name, :card_unique_id])
    add_index :card_tags, :card_unique_id unless index_exists?(:card_tags, :card_unique_id)
  end
end
