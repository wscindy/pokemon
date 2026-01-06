FactoryBot.define do
  factory :user_card do
    association :user
    card_unique_id { Card.order("RANDOM()").first&.card_unique_id }
    is_in_deck { true }
    quantity { 1 }
  end
end
