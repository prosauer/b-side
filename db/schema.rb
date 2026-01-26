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

ActiveRecord::Schema[8.1].define(version: 2026_01_26_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.string "invite_code"
    t.integer "max_points_per_song", default: 3, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_groups_on_creator_id"
    t.index ["invite_code"], name: "index_groups_on_invite_code", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.datetime "created_at", null: false
    t.bigint "user_id", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id", "user_id"], name: "index_likes_on_submission_id_and_user_id", unique: true
    t.index ["submission_id"], name: "index_likes_on_submission_id"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false
    t.integer "number", null: false
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.index ["group_id", "number"], name: "index_seasons_on_group_id_and_number", unique: true
    t.index ["group_id"], name: "index_seasons_on_group_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.string "album_art_url"
    t.string "artist", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.string "song_title", null: false
    t.string "song_url"
    t.string "spotify_uri"
    t.string "tidal_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "week_id", null: false
    t.index ["user_id"], name: "index_submissions_on_user_id"
    t.index ["week_id", "user_id"], name: "index_submissions_on_week_id_and_user_id", unique: true
    t.index ["week_id"], name: "index_submissions_on_week_id"
  end

  create_table "tidal_accounts", force: :cascade do |t|
    t.string "access_token", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "refresh_token"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_tidal_accounts_on_user_id"
  end

  create_table "user_playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "tidal_url", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "week_id"
    t.index ["user_id", "name"], name: "index_user_playlists_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_user_playlists_on_user_id"
    t.index ["week_id"], name: "index_user_playlists_on_week_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.text "tidal_access_token"
    t.datetime "tidal_expires_at"
    t.text "tidal_refresh_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "score", null: false
    t.bigint "submission_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "voter_id", null: false
    t.index ["submission_id", "voter_id"], name: "index_votes_on_submission_id_and_voter_id", unique: true
    t.index ["submission_id"], name: "index_votes_on_submission_id"
    t.index ["voter_id"], name: "index_votes_on_voter_id"
  end

  create_table "weeks", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.integer "number", null: false
    t.bigint "season_id", null: false
    t.string "spotify_playlist_url"
    t.datetime "submission_deadline", null: false
    t.string "tidal_playlist_url"
    t.datetime "updated_at", null: false
    t.datetime "voting_deadline", null: false
    t.index ["season_id", "number"], name: "index_weeks_on_season_id_and_number", unique: true
    t.index ["season_id"], name: "index_weeks_on_season_id"
  end

  add_foreign_key "groups", "users", column: "creator_id"
  add_foreign_key "likes", "submissions"
  add_foreign_key "likes", "users"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
  add_foreign_key "seasons", "groups"
  add_foreign_key "submissions", "users"
  add_foreign_key "submissions", "weeks"
  add_foreign_key "tidal_accounts", "users"
  add_foreign_key "user_playlists", "users"
  add_foreign_key "user_playlists", "weeks"
  add_foreign_key "votes", "submissions"
  add_foreign_key "votes", "users", column: "voter_id"
  add_foreign_key "weeks", "seasons"
end
