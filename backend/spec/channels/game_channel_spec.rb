require 'rails_helper'

RSpec.describe GameChannel, type: :channel do
  let(:user) { create(:user) } # user = User.create(...)
  let(:room) { Room.create!(name: "測試房間", room_type: "public", status: "waiting", max_players: 2, creator: user) }

  before do
    stub_connection(current_user: user) # stub_connection 是 ActionCable 測試工具提供的方法
  end

  it "成功訂閱存在的房間" do
    subscribe(room_id: room.id) # 類似 client 端：App.cable.subscriptions.create({ channel: "GameChannel", room_id: 1 })
    
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("game_#{room.id}")
    # 不用刪除 room id 因為有 config.use_transactional_fixtures = true in rails_helper.rb
  end
end