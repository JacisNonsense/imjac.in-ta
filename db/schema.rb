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

ActiveRecord::Schema.define(version: 2019_04_18_203733) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "dev_deploy_tokens", force: :cascade do |t|
    t.bigint "dev_user_id"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.index ["dev_user_id"], name: "index_dev_deploy_tokens_on_dev_user_id"
    t.index ["token"], name: "index_dev_deploy_tokens_on_token", unique: true
  end

  create_table "dev_maven_artifacts", force: :cascade do |t|
    t.string "path"
    t.string "group"
    t.string "artifact"
    t.string "metadata"
    t.string "metadata_md5"
    t.string "metadata_sha1"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group", "artifact"], name: "index_dev_maven_artifacts_on_group_and_artifact", unique: true
  end

  create_table "dev_maven_files", force: :cascade do |t|
    t.bigint "dev_maven_version_id"
    t.string "path"
    t.string "name"
    t.string "md5"
    t.string "sha1"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "download_count", default: 0
    t.index ["dev_maven_version_id", "name"], name: "index_dev_maven_files_on_dev_maven_version_id_and_name", unique: true
    t.index ["dev_maven_version_id"], name: "index_dev_maven_files_on_dev_maven_version_id"
  end

  create_table "dev_maven_frcdeps", force: :cascade do |t|
    t.string "uuid"
    t.string "name"
    t.string "filename"
    t.string "version"
    t.string "json"
  end

  create_table "dev_maven_versions", force: :cascade do |t|
    t.bigint "dev_maven_artifact_id"
    t.string "path"
    t.string "version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dev_maven_artifact_id", "version"], name: "index_dev_maven_versions_on_dev_maven_artifact_id_and_version", unique: true
    t.index ["dev_maven_artifact_id"], name: "index_dev_maven_versions_on_dev_maven_artifact_id"
  end

  create_table "dev_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.string "username"
    t.index ["email"], name: "index_dev_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_dev_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_dev_users_on_username", unique: true
  end

  create_table "on_deck_event_global_dominance_scores", force: :cascade do |t|
    t.string "team"
    t.integer "score"
    t.integer "rank"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team"], name: "index_on_deck_event_global_dominance_scores_on_team", unique: true
  end

  create_table "on_deck_event_past_performance_scores", force: :cascade do |t|
    t.string "team"
    t.integer "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team"], name: "index_on_deck_event_past_performance_scores_on_team", unique: true
  end

  add_foreign_key "dev_deploy_tokens", "dev_users"
  add_foreign_key "dev_maven_files", "dev_maven_versions"
  add_foreign_key "dev_maven_versions", "dev_maven_artifacts"
end
