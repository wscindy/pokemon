-- 主卡牌資料表
CREATE TABLE cards (
    id SERIAL PRIMARY KEY,
    card_unique_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    card_type VARCHAR(50),
    hp INTEGER,
    image_url TEXT,
    stage VARCHAR(50),
    pokedex_number INTEGER,
    evolve_from VARCHAR(255),
    regulation_mark VARCHAR(10),
    set_name VARCHAR(255),
    set_full_name TEXT,
    set_number VARCHAR(20),
    rule_box TEXT,
    tera_effect TEXT,
    weakness_type VARCHAR(50),
    weakness_value VARCHAR(10),
    resistance_type VARCHAR(50),
    resistance_value VARCHAR(10),
    retreat_cost INTEGER,
    raw_json JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 卡牌屬性表
CREATE TABLE card_types (
    id SERIAL PRIMARY KEY,
    card_unique_id VARCHAR(255) REFERENCES cards(card_unique_id) ON DELETE CASCADE,
    type_name VARCHAR(50)
);

-- 卡牌招式表
CREATE TABLE attacks (
    id SERIAL PRIMARY KEY,
    card_unique_id VARCHAR(255) REFERENCES cards(card_unique_id) ON DELETE CASCADE,
    name VARCHAR(255),
    damage VARCHAR(50),
    effect_description TEXT,
    position INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 招式能量消耗表
CREATE TABLE attack_energy_costs (
    id SERIAL PRIMARY KEY,
    attack_id INTEGER REFERENCES attacks(id) ON DELETE CASCADE,
    energy_type VARCHAR(50),
    energy_count INTEGER DEFAULT 1
);

-- 卡牌特性表
CREATE TABLE card_abilities (
    id SERIAL PRIMARY KEY,
    card_unique_id VARCHAR(255) REFERENCES cards(card_unique_id) ON DELETE CASCADE,
    name VARCHAR(255),
    effect TEXT
);

-- 卡牌標籤表
CREATE TABLE card_tags (
    id SERIAL PRIMARY KEY,
    card_unique_id VARCHAR(255) REFERENCES cards(card_unique_id) ON DELETE CASCADE,
    tag_name VARCHAR(50)
);

-- 建立索引
CREATE INDEX idx_cards_name ON cards(name);
CREATE INDEX idx_cards_pokedex_number ON cards(pokedex_number);
CREATE INDEX idx_cards_card_type ON cards(card_type);

SELECT 'Tables created successfully!' AS status;


---

-- 查詢
SELECT * FROM cards WHERE name LIKE '%烈咬%';  -- 模糊查詢
SELECT COUNT(*) FROM attacks;                   -- 統計
SELECT * FROM attacks WHERE card_unique_id = 'svf.png-001';  -- 特定卡的招式


# 1️⃣ 停止 Homebrew 的 PostgreSQL
brew services stop postgresql@15

# 2️⃣ 或者強制殺死進程
pkill -9 postgres

# 3️⃣ 驗證已停止
ps aux | grep postgres  # 應該看不到 PostgreSQL 進程

---

# macOS 常見的安裝方式
brew install postgresql@15

# 這會自動啟動 PostgreSQL 服務
brew services start postgresql@15

---

# 檢查
brew services list | grep postgres

 PostgreSQL 是官方安裝包版本。不需要用 brew services start 啟動，因為它不是 Homebrew 管理的。
 如果要管理官方版本的 PostgreSQL，應該用官方提供的工具或 pg_ctl 指令，不要用 Homebrew。

# 方法 1️⃣：看進程
ps aux | grep postgres

# 方法 2️⃣：試著連接
psql -U liweixuan -d pokemon_tcg_development -c "SELECT COUNT(*) FROM cards;"

# 如果能執行 SQL，PostgreSQL 肯定在執行！

# 方法 3️⃣：看埠口
lsof -i :5432

# 如果有輸出，代表 PostgreSQL 在監聽埠口 5432






# 啟動前端專案
cd frontend/vue-project 
npm run dev

# 啟動後端
rails server

# 建表
rails generate model User email:string name:string uid:string provider:string avatar_url:string online_status:string

# 備份原檔案
cp config/database.yml config/database.yml.backup


# 用 pg_ctl 停止
sudo -u postgres /Library/PostgreSQL/17/bin/pg_ctl -D /Library/PostgreSQL/17/data stop

# 啟動官方 PostgreSQL
sudo -u postgres /Library/PostgreSQL/17/bin/pg_ctl -D /Library/PostgreSQL/17/data start


# Rails Console 測試
# ═══════════════════════════════════════════════════════════

cd pokemon/backend

# 測試 Rails 能否連接資料庫
rails dbconsole
# 應該直接進入 psql

# 退出
\q

# 測試 Rails Console
rails console

# 在 console 中：
Card.count                  # 應該顯示 10760
Card.first.name            # 顯示第一張卡的名字


創造 controller
# rails generate controller Api::Decks

---

# 1. 檢查 routes
rails routes | grep cards

# 2. 如果沒有 search 路由，修改 config/routes.rb
# 3. 重新啟動伺服器
# 4. 測試 API


# schema location is here: pokemon/backend/db/schema.rb 如果要問目前schema長怎樣


# Rails Console vs Rails DBConsole


| 特性 | `rails console` (rails c) | `rails dbconsole` (rails db) |
|------|---------------------------|------------------------------|
| **用途** | 進入 Ruby/Rails 環境 | 直接進入資料庫 SQL 介面 |
| **語言** | Ruby | SQL (PostgreSQL/MySQL 等) |
| **操作對象** | Model、ActiveRecord、Ruby 代碼 | 資料庫表、索引、原始 SQL |
| **適合場景** | 測試業務邏輯、操作 Model、查詢資料 | 執行 SQL、建立/刪除索引、查看資料庫結構 |
| **退出方式** | `exit` 或 `quit` 或 `Ctrl+D` | `\q` 或 `Ctrl+D` |

---

# 查看目前的router有誰
# rails routes | grep games
會出現這樣：
api_v1_api_games_initialize POST   /api/v1/api/games/initialize(.:format)
api/v1/api/games#initialize_game
api_v1_api POST   /api/v1/api/games/:id/setup(.:format)
api/v1/api/games#setup_game
GET    /api/v1/api/games/:id/state(.:format)
api/v1/api/games#game_state


----

如何在後端加log

      # 移動競技場卡到指定玩家的指定區域
      def move_stadium_card
        # 🔍 看看到底收到什麼參數
        Rails.logger.info "===== move_stadium_card 收到的參數 ====="
        Rails.logger.info "完整 params: #{params.inspect}"
        Rails.logger.info "card_id: #{params[:card_id].inspect}"
        Rails.logger.info "stadium_card_id: #{params[:stadium_card_id].inspect}"
        Rails.logger.info "====================================="
        # ✅ 使用 @game_state 來查找卡片（更安全）
        stadium_card = @game_state.game_cards.find_by(id: params[:card_id])



找出所有含before_action的方法 grep -r "before_action" app/controllers/api/v1/


# rails 測試

rspec spec/models/user_spec.rb


# test 環境執行 seed data
RAILS_ENV=test rails db:seed

# test 環境執行 seed data
RAILS_ENV=development rails db:seed
