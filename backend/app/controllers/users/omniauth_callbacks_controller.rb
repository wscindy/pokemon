class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # skip_before_action :verify_authenticity_token, only: :google_oauth2

  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      # Generate tokens
      accessToken = JsonWebToken.encode(user_id: @user.id)
      @user.generate_refresh_token!

      # Set cookies
      cookies.signed[:jwt] = {
        value: accessToken,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        expires: 24.hours.from_now
      }

      cookies.signed[:refresh_token] = {
        value: @user.refresh_token,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        expires: 30.days.from_now
      }

      # Redirect to frontend
      redirect_to "#{ENV['FRONTEND_URL'] || 'http://localhost:5173'}/auth/callback?success=true"
    else
      redirect_to "#{ENV['FRONTEND_URL'] || 'http://localhost:5173'}/auth/callback?success=false"
    end
  end

  def failure
    redirect_to "#{ENV['FRONTEND_URL'] || 'http://localhost:5173'}/auth/callback?success=false"
  end
end
