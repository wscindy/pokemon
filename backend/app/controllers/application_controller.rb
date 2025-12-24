class ApplicationController < ActionController::API
  include ActionController::Cookies
  
  private
  
  # 🔥 JWT 認證方法（所有 controller 共用）
  def authenticate_user_from_token!
    # 🔥 優先從 Authorization header 讀取
    token = request.headers['Authorization']&.split(' ')&.last ||
            cookies.signed[:jwt]
    
    unless token
      return render json: { error: 'No token provided' }, status: :unauthorized
    end

    decoded = JsonWebToken.decode(token)

    unless decoded
      return render json: { error: 'Invalid or expired token' }, status: :unauthorized
    end

    @current_user = User.find_by(id: decoded[:user_id])

    unless @current_user
      render json: { error: 'User not found' }, status: :unauthorized
    end
  end
end