class GameCard < ApplicationRecord
  belongs_to :game_state
  belongs_to :user
  belongs_to :card, foreign_key: :card_unique_id, primary_key: :card_unique_id
  belongs_to :attached_to_game_card, class_name: 'GameCard', optional: true
  has_many :attached_cards, class_name: 'GameCard', foreign_key: :attached_to_game_card_id

  # 🆕 新增疊加關聯
  belongs_to :parent_card, class_name: 'GameCard', optional: true
  has_many :stacked_cards, class_name: 'GameCard', foreign_key: :parent_card_id, dependent: :nullify

  validates :zone, inclusion: { 
    in: ['hand', 'deck', 'active', 'bench', 'prize', 'discard', 'attached', 'stadium'] 
  }

  scope :in_deck, -> { where(zone: 'deck') }
  scope :in_hand, -> { where(zone: 'hand') }
  scope :active, -> { where(zone: 'active') }
  scope :on_bench, -> { where(zone: 'bench').order(:zone_position) }
  scope :in_prizes, -> { where(zone: 'prize') }
  scope :in_discard, -> { where(zone: 'discard') }
  # 🆕 只查詢主卡(沒有被疊在其他卡下面的)
  scope :main_cards, -> { where(parent_card_id: nil) }

  def is_knocked_out?
    return false unless card.hp
    damage_taken >= card.hp
  end

  def move_to_zone(new_zone, position = nil)
    update(zone: new_zone, zone_position: position)
  end

  # 🆕 疊加卡片到此卡上
  def stack_card(card_to_stack)
    return false if card_to_stack.nil?
    
    # 計算新的疊加順序
    max_order = stacked_cards.maximum(:stack_order) || 0
    
    card_to_stack.update(
      parent_card_id: self.id,
      stack_order: max_order + 1,
      zone: self.zone,
      zone_position: self.zone_position
    )
  end

  # 🆕 取消疊加(移除此卡的 parent)
  def unstack
    update(parent_card_id: nil, stack_order: 0)
  end

  # 🆕 檢查是否為主卡
  def main_card?
    parent_card_id.nil?
  end

  # 🆕 取得所有疊加的卡片(包含自己底下的)
  def all_stacked_cards
    stacked_cards.includes(:card).order(:stack_order)
  end
end
