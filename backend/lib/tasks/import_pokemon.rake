require 'json'

namespace :db do
  desc "Import Pokemon cards from JSON"
  task import_cards: :environment do
    data_dir = Rails.root.join('..', 'PTCG-database', 'data_tc')
    
    unless Dir.exist?(data_dir)
      puts "❌ 找不到資料目錄: #{data_dir}"
      exit
    end
    
    puts "🎮 開始匯入...\n"
    total = 0
    start_time = Time.now
    
    Dir.glob("#{data_dir}/*").sort.each do |set_path|
      next unless File.directory?(set_path)
      
      set_folder_name = File.basename(set_path)
      puts "📦 #{set_folder_name}"
      
      Dir.glob("#{set_path}/*.json").each do |card_file|
        begin
          card_data = JSON.parse(File.read(card_file))
          card_unique_id = "#{set_folder_name}-#{card_data['number']}"
          
          ActiveRecord::Base.transaction do
            # 建立卡牌
            card = Card.find_or_create_by!(card_unique_id: card_unique_id) do |c|
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
              c.set_number = card_data['number']
              c.rule_box = card_data['rule_box']
              c.tera_effect = card_data['tera_effect']
              c.weakness_type = card_data.dig('weakness', 'type', 0)
              c.weakness_value = card_data.dig('weakness', 'value')
              c.resistance_type = card_data.dig('resistance', 'type', 0)
              c.resistance_value = card_data.dig('resistance', 'value')
              c.retreat_cost = card_data['retreat']
              c.raw_json = card_data.to_json
            end
            
            # 屬性
            if card_data['types']
              card_data['types'].each do |type|
                CardType.create!(card_unique_id: card_unique_id, type_name: type)
              end
            end
            
            # 招式
            if card_data['attacks']
              card_data['attacks'].each_with_index do |attack, index|
                att = Attack.create!(
                  card_unique_id: card_unique_id,
                  name: attack['name'],
                  damage: attack['damage'],
                  effect_description: attack['effect'],
                  position: index + 1
                )
                
                # 能量消耗
                if attack['cost']
                  energy_counts = attack['cost'].tally
                  energy_counts.each do |energy_type, count|
                    AttackEnergyCost.create!(
                      attack_id: att.id,
                      energy_type: energy_type,
                      energy_count: count
                    )
                  end
                end
              end
            end
            
            # 特性
            if card_data['abilities']
              card_data['abilities'].each do |ability|
                CardAbility.create!(
                  card_unique_id: card_unique_id,
                  name: ability['name'],
                  effect: ability['effect']
                )
              end
            end
            
            # 標籤
            if card_data['tags']
              card_data['tags'].each do |tag|
                CardTag.create!(card_unique_id: card_unique_id, tag_name: tag)
              end
            end
          end
          
          total += 1
          puts "   進度: #{total}" if total % 100 == 0
          
        rescue => e
          puts "❌ 錯誤 #{card_file}: #{e.message}"
        end
      end
    end
    
    duration = (Time.now - start_time).round(2)
    puts "\n✨ 完成！共 #{total} 張卡牌，耗時 #{duration}秒\n"
  end
end
