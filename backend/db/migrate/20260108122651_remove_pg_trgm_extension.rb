class RemovePgTrgmExtension < ActiveRecord::Migration[7.0]
  def up
    execute 'DROP EXTENSION IF EXISTS pg_trgm;'
  end
  
  def down
    enable_extension 'pg_trgm'
  end
end
