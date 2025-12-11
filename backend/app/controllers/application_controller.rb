class ApplicationController < ActionController::API
  include ActionController::Cookies
  
  # 允許 CSRF token（因為用 cookie-based auth）
  # protect_from_forgery with: :null_session, if: -> { request.format.json? }
end
