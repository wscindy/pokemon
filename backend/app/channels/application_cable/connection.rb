module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags "ActionCable", "User #{current_user.id}"
    end

    private

    def find_verified_user
      # 從 URL 參數取得 token
      token = request.params[:token]
      
      if token
        decoded = JsonWebToken.decode(token)
        if decoded
          user = User.find_by(id: decoded[:user_id])
          return user if user
        end
      end

      reject_unauthorized_connection
    end
  end
end
