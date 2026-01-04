# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Ensures that the test database schema matches the current schema file.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true

  # 保護卡片資料不被測試清空
  config.before(:suite) do
    puts "🧹 清空測試資料(保留卡片資料)..."
    
    # 取得所有資料表,排除要保留的
    tables_to_clean = ActiveRecord::Base.connection.tables - [
      'schema_migrations',
      'ar_internal_metadata',
      'cards',
      'card_types', 
      'attacks',
      'attack_energy_costs',
      'card_abilities',
      'card_tags'
    ]
    
    # 清空動態資料表
    tables_to_clean.each do |table|
      begin
        ActiveRecord::Base.connection.execute("TRUNCATE #{table} RESTART IDENTITY CASCADE")
      rescue => e
        puts "⚠️  跳過資料表 #{table}: #{e.message}"
      end
    end
    
    puts "✅ 測試環境準備完成!"
    puts "📊 卡片資料數量: #{Card.count}"
  end

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
end
