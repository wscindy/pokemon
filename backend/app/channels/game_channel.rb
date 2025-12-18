# app/channels/game_channel.rb
class GameChannel < ActionCable::Channel::Base
  def subscribed
    room_id = params[:room_id]
    
    # 驗證房間是否存在
    room = Room.find_by(id: room_id)
    unless room
      reject
      return
    end
    
    # 訂閱該房間的頻道
    stream_from "game_#{room_id}"
    
    Rails.logger.info "✅ User #{current_user.id} subscribed to game_#{room_id}"
    
    # 通知其他玩家有人加入
    ActionCable.server.broadcast(
      "game_#{room_id}",
      {
        type: 'player_joined',
        user_id: current_user.id,
        user_name: current_user.name
      }
    )
  end

  def unsubscribed
    room_id = params[:room_id]
    Rails.logger.info "❌ User #{current_user.id} unsubscribed from game_#{room_id}"
    
    # 通知其他玩家有人離開
    ActionCable.server.broadcast(
      "game_#{room_id}",
      {
        type: 'player_left',
        user_id: current_user.id,
        user_name: current_user.name
      }
    )
  end
end
