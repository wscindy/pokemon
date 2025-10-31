require 'json'

namespace :cards do
  desc 'Import Pokemon TCG cards from JSON files'
  task import: :environment do
    data_dir = Rails.root.join('public', 'data_tc')
    
    puts "🎮 開始匯入卡牌資料...\n"
    
    total_files = 0
    processed_files = 0
    start_time = Time.now
    
    Dir.glob("#{data_dir}/*").each do |set_folder|
      next unless File.directory?(set_folder)
      
      set_folder_name = File.basename(set_folder)
      puts "\n📦 #{set_folder_name}"
      
      Dir.glob("#{set_folder}/*.json").each do |file_path|
        total_files += 1
        
        begin
          card_data = JSON.parse(File.read(file_path))
          set_number = File.basename(file_path, '.json')
          card_unique_id = "#{set_folder_name}-#{set_number}"
          
          # 建立或更新卡牌
          card = Card.find_or_create_by(card_unique_id: card_unique_id) do |c|
            c.name = card_data['name']
            c.img_url = card_data['img']
            c.card_type = card_data['card_type']
            c.stage = card_data['stage']
            c.hp = card_data['hp']&.to_i
            c.pokedex_number = card_data['pokedex_number']&.to_i
            c.evolve_from = card_data['evolve_from']&.join(', ')
            c.regulation_mark = card_data['regulation']
            c.set_name = card_data['set_name']
            c.set_full_name = card_data['set_full_name']
            c.set_number = set_number
            c.rule_box = card_data['rule_box']
            c.tera_effect = card_data['tera_effect']
            c.weakness_type = card_data['weakness']&.[]('type')&.first
            c.weakness_value = card_data['weakness']&.[]('value')
            c.resistance_type = card_data['resistance']&.[]('type')&.first
            c.resistance_value = card_data['resistance']&.[]('value')
            c.retreat_cost = card_data['retreat']
            c.raw_json = card_data
          end
          
          # 新增屬性
          if card_data['types']
            card_data['types'].each do |type_name|
              CardType.find_or_create_by(card_unique_id: card_unique_id, type_name: type_name)
            end
          end
          
          # 新增招式
          if card_data['attacks']
            card_data['attacks'].each_with_index do |attack_data, index|
              attack = Attack.find_or_create_by(
                card_unique_id: card_unique_id,
                position: index + 1
              ) do |a|
                a.name = attack_data['name']
                a.damage = attack_data['damage']
                a.effect_description = attack_data['effect']
              end
              
              # 新增能量消耗
              if attack_data['cost']
                energy_counts = Hash.new(0)
                attack_data['cost'].each { |energy| energy_counts[energy] += 1 }
                
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
          
          # 新增特性
          if card_data['abilities']
            card_data['abilities'].each do |ability_data|
              CardAbility.find_or_create_by(
                card_unique_id: card_unique_id,
                name: ability_data['name']
              ) do |ca|
                ca.effect = ability_data['effect']
              end
            end
          end
          
          # 新增標籤
          if card_data['tags']
            card_data['tags'].each do |tag_name|
              CardTag.find_or_create_by(card_unique_id: card_unique_id, tag_name: tag_name)
            end
          end
          
          processed_files += 1
          puts "✅ #{card_data['name']} (#{card_unique_id})" if processed_files % 100 == 0
          
        rescue => e
          puts "❌ 失敗: #{file_path} - #{e.message}"
        end
      end
    end
    
    duration = (Time.now - start_time).round(2)
    puts "\n✨ 完成！處理了 #{total_files} 張卡牌，耗時 #{duration}秒\n"
  end
end
