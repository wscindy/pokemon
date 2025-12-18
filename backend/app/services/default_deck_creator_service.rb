# TO-DO: need to go in the end
class DefaultDeckCreatorService
  def initialize(user)
    @user = user
  end

  def call
    return if @user.user_cards.exists?
    
    create_default_deck
  end

  private

  def create_default_deck
    # 策略：取15種卡片，每種4張，共60張
    default_cards = select_default_cards
    
    default_cards.each do |card_unique_id|
      UserCard.create!(
        user_id: @user.id,
        card_unique_id: card_unique_id,
        quantity: 4,
        is_in_deck: true
      )
    end
    
    Rails.logger.info "✅ 已為用戶 #{@user.id} (#{@user.email}) 建立預設牌組"
  rescue => e
    Rails.logger.error "❌ 建立預設牌組失敗: #{e.message}"
    raise
  end

  def select_default_cards
    # 優先順序：
    # 1. 基礎寶可夢（至少要有幾隻）
    # 2. 能量卡
    # 3. 訓練家卡
    
    basic_pokemon = Card.where(stage: 'Basic')
                        .where(card_type: 'Pokémon')
                        .limit(5)
                        .pluck(:card_unique_id)
    
    energy_cards = Card.where("card_type LIKE ?", "%能量%")
                       .limit(8)
                       .pluck(:card_unique_id)
    
    trainer_cards = Card.where("card_type LIKE ?", "%訓練家%")
                        .limit(2)
                        .pluck(:card_unique_id)
    
    selected = basic_pokemon + energy_cards + trainer_cards
    
    # 如果不足15種，隨機補足
    if selected.count < 15
      additional = Card.where.not(card_unique_id: selected)
                       .limit(15 - selected.count)
                       .pluck(:card_unique_id)
      selected += additional
    end
    
    selected.first(15)
  end
end
