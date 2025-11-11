class DeckValidator
  def self.validate(cards_data)
    errors = []
    
    return { 
      valid: false, 
      error: '牌組資料不能為空', 
      errors: ['牌組資料不能為空'],
      total_cards: 0
    } if cards_data.blank?
    
    total_cards = cards_data.sum { |c| (c[:quantity] || c['quantity']).to_i }
    
    # 規則 1：牌組必須有 60 張卡片
    if total_cards != 60
      errors << "牌組必須有 60 張卡片（目前：#{total_cards} 張）"
    end
    
    # 規則 2：同一張卡片最多 4 張（基本能量卡除外）
    cards_data.each do |card_data|
      card_unique_id = card_data[:card_unique_id] || card_data['card_unique_id']
      quantity = (card_data[:quantity] || card_data['quantity']).to_i
      
      if quantity <= 0
        errors << "卡片數量必須大於 0"
        next
      end
      
      card = Card.find_by(card_unique_id: card_unique_id)
      unless card
        errors << "卡片 #{card_unique_id} 不存在"
        next
      end
      
      # unless card.basic_energy?
      #   if quantity > 4
      #     errors << "#{card.name} 超過數量限制（最多 4 張，目前：#{quantity} 張）"
      #   end
      # end
    end
    
    {
      valid: errors.empty?,
      error: errors.join(', '),
      errors: errors,
      total_cards: total_cards
    }
  end
end
