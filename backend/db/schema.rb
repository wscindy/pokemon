# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_24_081023) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attack_energy_costs", id: :serial, force: :cascade do |t|
    t.integer "attack_id", null: false
    t.string "energy_type", null: false
    t.integer "energy_count", null: false
    t.index ["attack_id"], name: "idx_attack_energy_attack_id"
  end

  create_table "attacks", id: :serial, force: :cascade do |t|
    t.string "card_unique_id", null: false
    t.string "name", null: false
    t.string "damage"
    t.integer "position"
    t.text "effect_description"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["card_unique_id"], name: "idx_attacks_card_id"
  end

  create_table "card_abilities", id: :serial, force: :cascade do |t|
    t.string "card_unique_id", null: false
    t.string "name", null: false
    t.text "effect"
    t.index ["card_unique_id"], name: "idx_card_abilities_card_id"
  end

  create_table "card_tags", id: :serial, force: :cascade do |t|
    t.string "card_unique_id", null: false
    t.string "tag_name", null: false
    t.index ["card_unique_id"], name: "idx_card_tags_card_id"
  end

  create_table "card_types", id: :serial, force: :cascade do |t|
    t.string "card_unique_id", null: false
    t.string "type_name", null: false
    t.index ["card_unique_id"], name: "idx_card_types_card_id"
  end

  create_table "cards", id: :serial, force: :cascade do |t|
    t.string "card_unique_id", null: false
    t.string "name", null: false
    t.string "img_url"
    t.string "card_type"
    t.integer "hp"
    t.string "stage"
    t.integer "pokedex_number"
    t.string "evolve_from"
    t.string "regulation_mark"
    t.string "set_name"
    t.string "set_full_name"
    t.string "set_number"
    t.text "rule_box"
    t.text "tera_effect"
    t.string "weakness_type"
    t.string "weakness_value"
    t.string "resistance_type"
    t.string "resistance_value"
    t.integer "retreat_cost"
    t.jsonb "raw_json"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["card_type"], name: "idx_cards_type"
    t.index ["name"], name: "idx_cards_name"
    t.unique_constraint ["card_unique_id"], name: "cards_card_unique_id_key"
  end

  create_table "game_actions", force: :cascade do |t|
    t.bigint "game_state_id", null: false
    t.bigint "user_id", null: false
    t.integer "round_number", null: false
    t.string "action_type", null: false
    t.bigint "source_card_id"
    t.bigint "target_card_id"
    t.text "action_description", null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["game_state_id", "round_number"], name: "index_game_actions_on_state_and_round"
    t.index ["game_state_id"], name: "index_game_actions_on_game_state_id"
    t.index ["user_id"], name: "index_game_actions_on_user_id"
  end

  create_table "game_cards", force: :cascade do |t|
    t.bigint "game_state_id", null: false
    t.bigint "user_id", null: false
    t.string "card_unique_id", null: false
    t.string "zone", null: false
    t.integer "zone_position"
    t.bigint "attached_to_game_card_id"
    t.integer "damage_taken", default: 0, null: false
    t.string "special_condition"
    t.boolean "is_evolved_this_turn", default: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "parent_card_id"
    t.integer "stack_order", default: 0
    t.index ["attached_to_game_card_id"], name: "index_game_cards_on_attached_to_game_card_id"
    t.index ["card_unique_id"], name: "index_game_cards_on_card_unique_id"
    t.index ["game_state_id", "user_id", "zone"], name: "index_game_cards_on_state_user_zone"
    t.index ["game_state_id"], name: "index_game_cards_on_game_state_id"
    t.index ["id"], name: "index_game_cards_on_id", unique: true
    t.index ["parent_card_id"], name: "index_game_cards_on_parent_card_id"
    t.index ["user_id", "zone"], name: "index_game_cards_on_user_id_and_zone"
    t.index ["user_id"], name: "index_game_cards_on_user_id"
  end

  create_table "game_states", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "player1_id", null: false
    t.bigint "player2_id"
    t.bigint "current_turn_user_id", null: false
    t.integer "round_number", default: 1, null: false
    t.integer "player1_prizes_remaining", default: 6, null: false
    t.integer "player2_prizes_remaining", default: 6, null: false
    t.string "status", default: "setup", null: false
    t.bigint "winner_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["current_turn_user_id"], name: "index_game_states_on_current_turn_user_id"
    t.index ["player1_id"], name: "index_game_states_on_player1_id"
    t.index ["player2_id"], name: "index_game_states_on_player2_id"
    t.index ["room_id"], name: "index_game_states_on_room_id", unique: true
    t.index ["status"], name: "index_game_states_on_status"
    t.index ["winner_id"], name: "index_game_states_on_winner_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.string "message_type", default: "chat", null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["room_id"], name: "index_messages_on_room_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "room_participants", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "user_id", null: false
    t.string "role", null: false
    t.boolean "ready_status", default: false
    t.datetime "joined_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["room_id", "user_id"], name: "index_room_participants_on_room_id_and_user_id", unique: true
    t.index ["room_id"], name: "index_room_participants_on_room_id"
    t.index ["user_id"], name: "index_room_participants_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name", null: false
    t.string "room_type", null: false
    t.string "password"
    t.bigint "creator_id", null: false
    t.string "status", default: "waiting", null: false
    t.integer "max_players", default: 2, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["creator_id"], name: "index_rooms_on_creator_id"
    t.index ["status"], name: "index_rooms_on_status"
  end

  create_table "user_cards", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "card_unique_id", null: false
    t.boolean "is_in_deck", default: true
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.integer "quantity", default: 0, null: false
    t.index ["card_unique_id"], name: "idx_user_cards_card"
    t.index ["user_id", "card_unique_id"], name: "idx_user_cards_unique", unique: true
    t.index ["user_id"], name: "idx_user_cards_user"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "uid"
    t.string "provider"
    t.string "avatar_url"
    t.string "online_status", default: "offline"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "refresh_token"
    t.datetime "refresh_token_expires_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["refresh_token"], name: "index_users_on_refresh_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "attack_energy_costs", "attacks", name: "attack_energy_costs_attack_id_fkey"
  add_foreign_key "attacks", "cards", column: "card_unique_id", primary_key: "card_unique_id", name: "attacks_card_unique_id_fkey"
  add_foreign_key "card_abilities", "cards", column: "card_unique_id", primary_key: "card_unique_id", name: "card_abilities_card_unique_id_fkey"
  add_foreign_key "card_tags", "cards", column: "card_unique_id", primary_key: "card_unique_id", name: "card_tags_card_unique_id_fkey"
  add_foreign_key "card_types", "cards", column: "card_unique_id", primary_key: "card_unique_id", name: "card_types_card_unique_id_fkey"
  add_foreign_key "game_actions", "game_cards", column: "source_card_id"
  add_foreign_key "game_actions", "game_cards", column: "target_card_id"
  add_foreign_key "game_actions", "game_states"
  add_foreign_key "game_actions", "users"
  add_foreign_key "game_cards", "cards", column: "card_unique_id", primary_key: "card_unique_id"
  add_foreign_key "game_cards", "game_cards", column: "attached_to_game_card_id"
  add_foreign_key "game_cards", "game_cards", column: "parent_card_id"
  add_foreign_key "game_cards", "game_states"
  add_foreign_key "game_cards", "users"
  add_foreign_key "game_states", "rooms"
  add_foreign_key "game_states", "users", column: "current_turn_user_id"
  add_foreign_key "game_states", "users", column: "player1_id"
  add_foreign_key "game_states", "users", column: "player2_id"
  add_foreign_key "game_states", "users", column: "winner_id"
  add_foreign_key "messages", "rooms"
  add_foreign_key "messages", "users"
  add_foreign_key "room_participants", "rooms"
  add_foreign_key "room_participants", "users"
  add_foreign_key "rooms", "users", column: "creator_id"
  add_foreign_key "user_cards", "cards", column: "card_unique_id", primary_key: "card_unique_id", name: "user_cards_card_unique_id_fkey"
  add_foreign_key "user_cards", "users", name: "user_cards_user_id_fkey"
end
