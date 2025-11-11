# app/models/attack_energy_cost.rb
class AttackEnergyCost < ApplicationRecord
  belongs_to :attack
  
  validates :attack_id, presence: true
  validates :energy_type, presence: true
  validates :energy_count, numericality: { only_integer: true, greater_than: 0 }
end
