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

ActiveRecord::Schema.define(version: 20160205015734) do

  create_table "credit_cards", force: :cascade do |t|
    t.integer  "customer_id", null: false
    t.string   "cc_num",      null: false
    t.string   "cc_exp_mth",  null: false
    t.string   "cc_exp_year", null: false
    t.string   "cc_name"
    t.string   "cc_line1"
    t.string   "cc_city"
    t.string   "cc_state"
    t.string   "cc_zip"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "customers", force: :cascade do |t|
    t.integer  "user_id",                                      null: false
    t.datetime "order_date",   default: '2016-02-18 18:43:45', null: false
    t.string   "cust_num",                                     null: false
    t.string   "ship_to_num"
    t.string   "po_num",       default: "FIRST AID",           null: false
    t.string   "cc_sq_num"
    t.string   "cc_last_four"
    t.string   "cust_name",                                    null: false
    t.string   "cust_line1"
    t.string   "cust_line2"
    t.string   "cust_city"
    t.string   "cust_state"
    t.string   "cust_zip"
    t.boolean  "printed",      default: false,                 null: false
    t.boolean  "edit",         default: false,                 null: false
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  create_table "items", force: :cascade do |t|
    t.integer  "customer_id",     null: false
    t.string   "kit",             null: false
    t.string   "item_num",        null: false
    t.string   "item_desc",       null: false
    t.integer  "item_qty",        null: false
    t.float    "item_price",      null: false
    t.string   "item_price_type", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "first_name",                      null: false
    t.string   "last_name",                       null: false
    t.string   "username",                        null: false
    t.string   "password_digest",                 null: false
    t.integer  "whs_id",                          null: false
    t.boolean  "admin",           default: false, null: false
    t.boolean  "active",          default: true,  null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

end
