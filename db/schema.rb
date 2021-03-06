# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180309152600) do

  create_table "users", force: :cascade do |t|
    t.string   "provider",                                null: false
    t.string   "uid",                                     null: false
    t.string   "name"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "username"
    t.string   "encrypted_id",                            null: false
    t.string   "roles"
    t.string   "email"
    t.string   "background_file_name"
    t.string   "background_content_type"
    t.integer  "background_file_size"
    t.datetime "background_updated_at"
    t.string   "token"
    t.boolean  "use_html5",               default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["encrypted_id"], name: "index_users_on_encrypted_id", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["uid"], name: "index_users_on_uid"
  end

  create_table "rails_lti2_provider_lti_launches", force: :cascade do |t|
    t.bigint   "tool_id"
    t.string   "nonce"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rails_lti2_provider_registrations", force: :cascade do |t|
    t.string   "uuid"
    t.text     "registration_request_params"
    t.text     "tool_proxy_json"
    t.string   "workflow_state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint   "tool_id"
    t.text     "correlation_id"
    t.index ["correlation_id"], name: "index_rails_lti2_provider_registrations_on_correlation_id", unique: true, using: :btree
  end

  create_table "rails_lti2_provider_tools", force: :cascade do |t|
    t.string   "uuid"
    t.text     "shared_secret"
    t.text     "tool_settings"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "lti_version"
    t.string   "resource_type",    default: ""
  end

end
