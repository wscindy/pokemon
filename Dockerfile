FROM ruby:3.3-slim

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm git curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 建置前端
COPY frontend/vue-project/package*.json ./frontend/vue-project/
WORKDIR /app/frontend/vue-project
RUN npm install
COPY frontend/vue-project ./
RUN npm run build

# 設定後端
WORKDIR /app/backend
COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install
COPY backend ./

# 複製前端產物到 Rails public
RUN cp -r /app/frontend/vue-project/dist/* ./public/

EXPOSE 8080

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "8080", "-e", "production"]
