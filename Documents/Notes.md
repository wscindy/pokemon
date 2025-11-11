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