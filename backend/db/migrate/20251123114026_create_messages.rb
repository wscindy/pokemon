class CreateMessages < ActiveRecord::Migration[8.0]
  def up
    # 清理可能存在的索引
    execute <<-SQL
      DROP INDEX IF EXISTS index_messages_on_room_id;
      DROP INDEX IF EXISTS index_messages_on_user_id;
      DROP INDEX IF EXISTS index_messages_on_created_at;
    SQL
    
    drop_table :messages, if_exists: true, force: :cascade
    
    create_table :messages do |t|
      t.references :room, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false
      t.text :content, null: false
      t.string :message_type, default: 'chat', null: false

      t.timestamp :created_at, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :messages, :room_id
    add_index :messages, :user_id
    add_index :messages, :created_at
  end

  def down
    drop_table :messages, if_exists: true, force: :cascade
  end
end
