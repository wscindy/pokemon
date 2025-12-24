# app/controllers/api/v1/auth_controller.rb
class Api::V1::AuthController < ApplicationController
  before_action :authenticate_user_from_token!, only: [:me, :logout, :ws_token]
  # skip_before_action :verify_authenticity_token

  # POST /api/v1/auth/google
  # 前端用 Google SDK 取得 credential 後呼叫
  def google
    require 'httparty'

    # 驗證 Google ID Token
    response = HTTParty.get(
      'https://oauth2.googleapis.com/tokeninfo',
      query: { id_token: params[:credential] }
    )
    
    if response.success?
      google_user = response.parsed_response
      
      # 驗證 audience (Client ID)
      unless google_user['aud'] == ENV['GOOGLE_CLIENT_ID']
        return render json: { error: 'Invalid token' }, status: :unauthorized
      end

      # 找或建立用戶（首次註冊時不設定 name，只存 Google 資料）
      user = User.find_or_create_by(email: google_user['email']) do |u|
        u.provider = 'google_oauth2'
        u.uid = google_user['sub']
        # 不設定 name，讓用戶自己選（或存到另一個欄位）
        # u.name = google_user['name']  # ← 註解掉這行
        u.avatar_url = google_user['picture']  # 存 Google 頭像作為預設
        u.password = Devise.friendly_token[0, 20]
      end

      # 如果已存在但沒有 OAuth 資訊，更新之
      if user.uid.blank?
        user.update(
          provider: 'google_oauth2',
          uid: google_user['sub'],
          avatar_url: google_user['picture']
        )
      end

      # Generate tokens
      access_token = JsonWebToken.encode(user_id: user.id)
      user.generate_refresh_token!

      # Set cookies
      set_auth_cookies(access_token, user.refresh_token)

      render json: {
        user: user_json(user),
        access_token: access_token,
        refresh_token: user.refresh_token
      }, status: :ok
    else
      render json: { error: 'Invalid Google token', details: response.body }, status: :unauthorized
    end
  rescue => e
    Rails.logger.error "Google auth error: #{e.message}"
    render json: { error: 'Authentication failed', message: e.message }, status: :internal_server_error
  end

  # POST /api/v1/auth/refresh
  def refresh
    refresh_token = cookies.signed[:refresh_token] || params[:refresh_token]

    unless refresh_token
      return render json: { error: 'Refresh token not provided' }, status: :unauthorized
    end

    user = User.find_by(refresh_token: refresh_token)

    if user&.refresh_token_valid?
      # Generate new access token
      access_token = JsonWebToken.encode(user_id: user.id)
      
      # Optionally rotate refresh token
      user.generate_refresh_token!

      set_auth_cookies(access_token, user.refresh_token)

      render json: {
        user: user_json(user),
        access_token: access_token,
        refresh_token: user.refresh_token
      }, status: :ok
    else
      render json: { error: 'Invalid or expired refresh token' }, status: :unauthorized
    end
  end

  # DELETE /api/v1/auth/logout
  def logout
    @current_user.update(refresh_token: nil, refresh_token_expires_at: nil)
    
    cookies.delete(:jwt)
    cookies.delete(:refresh_token)

    render json: { message: 'Logged out successfully' }, status: :ok
  end

  # GET /api/v1/auth/me
  def me
    render json: { user: user_json(@current_user) }, status: :ok
  end

  # 🔥 新增：GET /api/v1/auth/ws_token
  # 用於 WebSocket 連線時取得 token
  def ws_token
    # 從 cookie 或 header 取得現有的 JWT token
    token = cookies.signed[:jwt] || 
            request.headers['Authorization']&.split(' ')&.last

    unless token
      return render json: { error: 'No token provided' }, status: :unauthorized
    end

    # 驗證 token 是否有效
    decoded = JsonWebToken.decode(token)
    unless decoded
      return render json: { error: 'Invalid or expired token' }, status: :unauthorized
    end

    # 確認用戶存在
    user = User.find_by(id: decoded[:user_id])
    unless user
      return render json: { error: 'User not found' }, status: :unauthorized
    end

    # 返回 token 供 WebSocket 使用
    render json: { 
      token: token,
      user_id: user.id,
      expires_at: 24.hours.from_now.iso8601
    }, status: :ok
  end

  private

  def authenticate_user_from_token!
    token = cookies.signed[:jwt] || 
            request.headers['Authorization']&.split(' ')&.last

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

  def set_auth_cookies(access_token, refresh_token)
    cookies.signed[:jwt] = {
      value: access_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: Rails.env.production? ? :none : :lax,
      expires: 24.hours.from_now
    }

    cookies.signed[:refresh_token] = {
      value: refresh_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: Rails.env.production? ? :none : :lax,
      expires: 30.days.from_now
    }
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      avatar_url: user.avatar_url,
      online_status: user.online_status
    }
  end
end
