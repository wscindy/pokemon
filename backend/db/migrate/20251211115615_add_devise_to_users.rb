class AddDeviseToUsers < ActiveRecord::Migration[8.0]
  def change
    # 加入 Devise 需要的欄位
    add_column :users, :encrypted_password, :string, null: false, default: ""
    
    # JWT Refresh Token
    add_column :users, :refresh_token, :string
    add_column :users, :refresh_token_expires_at, :datetime
    
    # Recoverable (密碼重置功能)
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    
    # Rememberable (記住我功能)
    add_column :users, :remember_created_at, :datetime
    
    # 加入索引
    add_index :users, :reset_password_token, unique: true
    add_index :users, :refresh_token, unique: true
  end
end
