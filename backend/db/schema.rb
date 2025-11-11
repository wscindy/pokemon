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

ActiveRecord::Schema[8.0].define(version: 2025_11_11_095804) do
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "attack_energy_costs", "attacks", name: "attack_energy_costs_attack_id_fkey"
  add_foreign_key "attacks", "cards", column: "card_unique_id", primary_key: "card_unique_id", name: "attacks_card_unique_id_fkey"
  add_foreign_key "card_abilities", "cards", column: "card_unique_id", primary_key: "card_unique_id", name: "card_abilities_card_unique_id_fkey"
  add_foreign_key "card_tags", "cards", column: "card_unique_id", primary_key: "card_unique_id", name: "card_tags_card_unique_id_fkey"
  add_foreign_key "card_types", "cards", column: "card_unique_id", primary_key: "card_unique_id", name: "card_types_card_unique_id_fkey"
  add_foreign_key "user_cards", "cards", column: "card_unique_id", primary_key: "card_unique_id", name: "user_cards_card_unique_id_fkey"
  add_foreign_key "user_cards", "users", name: "user_cards_user_id_fkey"
end
