# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160517223634) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "columns", force: :cascade do |t|
    t.string   "name"
    t.text     "xpath"
    t.text     "suffix"
    t.integer  "relation_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "columns", ["relation_id"], name: "index_columns_on_relation_id", using: :btree
  add_index "columns", ["xpath", "relation_id"], name: "index_columns_on_xpath_and_relation_id", unique: true, using: :btree
  add_index "columns", ["xpath"], name: "index_columns_on_xpath", using: :btree

  create_table "domains", force: :cascade do |t|
    t.text     "domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "domains", ["domain"], name: "index_domains_on_domain", unique: true, using: :btree

  create_table "relations", force: :cascade do |t|
    t.string   "name"
    t.string   "selector"
    t.integer  "selector_version"
    t.integer  "url_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "num_columns"
    t.integer  "num_rows_in_demonstration"
  end

  add_index "relations", ["selector", "selector_version", "url_id"], name: "index_relations_on_selector_and_selector_version_and_url_id", unique: true, using: :btree
  add_index "relations", ["url_id"], name: "index_relations_on_url_id", using: :btree

  create_table "urls", force: :cascade do |t|
    t.text     "url"
    t.integer  "domain_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "urls", ["domain_id"], name: "index_urls_on_domain_id", using: :btree
  add_index "urls", ["url"], name: "index_urls_on_url", unique: true, using: :btree

  add_foreign_key "columns", "relations"
  add_foreign_key "relations", "urls"
  add_foreign_key "urls", "domains"
end
