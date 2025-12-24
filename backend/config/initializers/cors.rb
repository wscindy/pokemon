# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 🔥 允許的來源 (加入你實際的前端網域)
    origins 'https://pokemonww.zeabur.app', 
            'http://localhost:5173',
            'http://localhost:3000',
            /https:\/\/.*\.zeabur\.app/,
            /https:\/\/.*\.vercel\.app/  # 如果前端用 Vercel

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['Authorization', 'Set-Cookie']
  end
end
