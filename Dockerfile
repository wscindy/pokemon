FROM ruby:3.4.5-slim

# 安裝必要套件
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm git curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 複製前端並建置
COPY frontend/vue-project/package*.json ./frontend/vue-project/
WORKDIR /app/frontend/vue-project
RUN npm install
COPY frontend/vue-project ./
RUN npm run build

# 複製後端
WORKDIR /app/backend
COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install

COPY backend ./

# 複製前端建置結果到 Rails public
RUN cp -r /app/frontend/vue-project/dist/* ./public/

# Precompile assets（使用假的 SECRET_KEY_BASE）
RUN RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rake assets:precompile

EXPOSE 8080

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "8080", "-e", "production"]
