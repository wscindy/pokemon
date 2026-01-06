require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      user = User.new(
        email: "test@example.com",
        password: "password123"
      )
      expect(user).to be_valid
    end
    
    it "is invalid without an email" do
      user = User.new(password: "password123")
      expect(user).not_to be_valid
    end
    
    it "is invalid with duplicate email" do
      User.create!(email: "test@example.com", password: "password123")
      user = User.new(email: "test@example.com", password: "password456")
      expect(user).not_to be_valid
    end
  end
  
  describe "associations" do
    it "can have multiple rooms" do
      user = User.create!(email: "test@example.com", password: "password123")
      expect(user).to respond_to(:rooms)
    end
    
    it "can have user_cards" do
      user = User.create!(email: "test@example.com", password: "password123")
      expect(user).to respond_to(:user_cards)
    end
  end
end


RSpec.describe User, type: :model do
  describe "deck_complete?" do
    let(:user) { create(:user) }
    
    context "when the deck has 60 cards" do
      it "return true" do
        # 從 test 資料庫取得 3 張真實卡片
        cards = Card.limit(3)
        
        # 為這個 user 建立 3 筆 user_card,總共 60 張
        create(:user_card, 
          user: user, 
          card_unique_id: cards[0].card_unique_id, 
          is_in_deck: true, 
          quantity: 20
        )
        
        create(:user_card, 
          user: user, 
          card_unique_id: cards[1].card_unique_id, 
          is_in_deck: true, 
          quantity: 20
        )
        
        create(:user_card, 
          user: user, 
          card_unique_id: cards[2].card_unique_id, 
          is_in_deck: true, 
          quantity: 20
        )
        
        # 測試 deck_complete? 方法
        expect(user.deck_complete?).to be true
      end
    end
    
    context "when the deck has less than 60 cards" do
      it "return false" do
        # 只建立 30 張
        card = Card.first
        create(:user_card, 
          user: user, 
          card_unique_id: card.card_unique_id, 
          is_in_deck: true, 
          quantity: 30
        )
        
        expect(user.deck_complete?).to be false
      end
    end
    
    context "when the deck has more than 60 cards" do
      it "return false" do
        # 建立 70 張
        card = Card.first
        create(:user_card, 
          user: user, 
          card_unique_id: card.card_unique_id, 
          is_in_deck: true, 
          quantity: 70
        )
        
        expect(user.deck_complete?).to be false
      end
    end
    
    context "when the deck has 0 cards" do
      it "return false" do
        # 不建立任何 user_card
        expect(user.deck_complete?).to be false
      end
    end
    
    context "when the deck has cards, but is_in_deck = false" do
      it "return false" do
        # 建立 60 張但 is_in_deck = false
        card = Card.first
        create(:user_card, 
          user: user, 
          card_unique_id: card.card_unique_id, 
          is_in_deck: false,  # 不在卡組中
          quantity: 60
        )
        
        expect(user.deck_complete?).to be false
      end
    end
  end
end