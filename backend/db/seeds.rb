# db/seeds.rb
require 'json'

puts "🎮 開始匯入寶可夢卡牌資料...\n"

# 設定資料目錄
data_dir = Rails.root.join('public', 'data_tc')

unless Dir.exist?(data_dir)
  puts "❌ 找不到資料目錄: #{data_dir}"
  exit 1
end

# 統計變數
total = 0
success = 0
failed = 0
errors = []
start_time = Time.now

# 清空現有資料（選擇性,小心使用!)
if ENV['RESET_DB'] == 'true'
  puts "⚠️  清空現有卡牌資料..."
  AttackEnergyCost.delete_all
  Attack.delete_all
  CardAbility.delete_all
  CardTag.delete_all
  CardType.delete_all
  Card.delete_all
  puts "✅ 清空完成\n"
end

# 遍歷所有系列資料夾
Dir.glob("#{data_dir}/*").each do |set_path|
  next unless File.directory?(set_path)
  
  set_folder_name = File.basename(set_path)
  puts "📦 處理系列: #{set_folder_name}"
  
  # 遍歷該系列的所有 JSON 檔案
  Dir.glob("#{set_path}/*.json").each do |json_file|
    total += 1
    
    begin
      # 讀取 JSON 資料
      json_data = JSON.parse(File.read(json_file))
      card_unique_id = "#{set_folder_name}-#{json_data['number']}"
      
      # 使用交易確保資料一致性
      ActiveRecord::Base.transaction do
        # 1️⃣ 建立主卡牌 (Card)
        # ✅ 改用 find_or_create_by 確保冪等性
        card = Card.find_or_create_by(card_unique_id: card_unique_id) do |c|
          c.name = json_data['name']
          c.img_url = json_data['img']
          c.card_type = json_data['card_type']
          c.stage = json_data['stage']
          c.hp = json_data['hp']&.to_i
          c.pokedex_number = json_data['pokedex_number']&.to_i
          c.evolve_from = json_data['evolve_from']&.join(', ')
          c.regulation_mark = json_data['regulation']
          c.set_name = json_data['set_name']
          c.set_full_name = json_data['set_full_name']
          c.set_number = json_data['number']
          c.rule_box = json_data['rule_box']
          c.tera_effect = json_data['tera_effect']
          c.weakness_type = json_data.dig('weakness', 'type', 0)
          c.weakness_value = json_data.dig('weakness', 'value')
          c.resistance_type = json_data.dig('resistance', 'type', 0)
          c.resistance_value = json_data.dig('resistance', 'value')
          c.retreat_cost = json_data['retreat']
          c.raw_json = json_data
        end
        
        # 如果卡片已存在,跳過子資料的建立
        if card.previously_new_record? == false
          success += 1
          next
        end
        
        # 2️⃣ 建立卡牌類型 (CardType)
        if json_data['types'].is_a?(Array)
          json_data['types'].each do |type_name|
            CardType.find_or_create_by(
              card_unique_id: card_unique_id,
              type_name: type_name
            )
          end
        end
        
        # 3️⃣ 建立攻擊技能 (Attack) 和能量需求 (AttackEnergyCost)
        if json_data['attacks'].is_a?(Array)
          json_data['attacks'].each_with_index do |attack_data, index|
            attack = Attack.find_or_create_by(
              card_unique_id: card_unique_id,
              position: index
            ) do |a|
              a.name = attack_data['name']
              a.damage = attack_data['damage']
              a.effect_description = attack_data['effect']
            end
            
            # 統計能量需求
            if attack_data['cost'].is_a?(Array) && attack.previously_new_record?
              energy_counts = attack_data['cost'].each_with_object(Hash.new(0)) do |energy_type, counts|
                counts[energy_type] += 1
              end
              
              energy_counts.each do |energy_type, count|
                AttackEnergyCost.find_or_create_by(
                  attack_id: attack.id,
                  energy_type: energy_type
                ) do |aec|
                  aec.energy_count = count
                end
              end
            end
          end
        end
        
        # 4️⃣ 建立特殊能力 (CardAbility)
        if json_data['abilities'].is_a?(Array)
          json_data['abilities'].each do |ability_data|
            CardAbility.find_or_create_by(
              card_unique_id: card_unique_id,
              name: ability_data['name']
            ) do |ca|
              ca.effect = ability_data['effect']
            end
          end
        end
        
        # 5️⃣ 建立標籤 (CardTag) - 如果 JSON 中有 tags 欄位
        if json_data['tags'].is_a?(Array)
          json_data['tags'].each do |tag_name|
            CardTag.find_or_create_by(
              card_unique_id: card_unique_id,
              tag_name: tag_name
            )
          end
        end
      end
      
      success += 1
      puts "   ✅ #{json_data['name']}" if success % 100 == 0
      
    rescue => e
      failed += 1
      error_info = {
        file: File.basename(json_file),
        error: e.message,
        backtrace: e.backtrace.first(3)
      }
      errors << error_info
      puts "   ❌ 失敗: #{File.basename(json_file)} - #{e.message}"
    end
  end
end

# 輸出統計結果
duration = (Time.now - start_time).round(2)

puts "\n" + "=" * 60
puts "📊 匯入完成統計:"
puts "   總數: #{total} 張"
puts "   成功: #{success} 張 ✅"
puts "   失敗: #{failed} 張 ❌"
puts "   耗時: #{duration} 秒"
puts "=" * 60

if errors.any?
  puts "\n❌ 失敗清單(前 10 筆):"
  errors.first(10).each do |err|
    puts "   - #{err[:file]}: #{err[:error]}"
  end
  puts "   ... 還有 #{errors.size - 10} 個錯誤" if errors.size > 10
end

puts "\n✨ Seeds 執行完成!"
