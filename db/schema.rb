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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100726124616) do

  create_table "flights", :force => true do |t|
    t.integer  "plane_id"
    t.integer  "pilot_id"
    t.integer  "copilot_id"
    t.string   "type"
    t.string   "mode"
    t.boolean  "departed"
    t.boolean  "landed"
    t.boolean  "towflight_landed"
    t.integer  "launch_method_id"
    t.string   "departure_location"
    t.string   "landing_location"
    t.integer  "num_landings"
    t.datetime "departure_time"
    t.datetime "landing_time"
    t.integer  "towplane_id"
    t.string   "towflight_mode"
    t.string   "towflight_landing_location"
    t.datetime "towflight_landing_time"
    t.integer  "towpilot_id"
    t.string   "pilot_last_name"
    t.string   "pilot_first_name"
    t.string   "copilot_last_name"
    t.string   "copilot_first_name"
    t.string   "towpilot_last_name"
    t.string   "towpilot_first_name"
    t.string   "comments"
    t.string   "accounting_notes"
  end

  add_index "flights", ["accounting_notes"], :name => "accounting_notes_index"
  add_index "flights", ["copilot_id"], :name => "copilot_id_index"
  add_index "flights", ["departed", "landed", "towflight_landed"], :name => "status_index"
  add_index "flights", ["departed"], :name => "departed_index"
  add_index "flights", ["departure_location"], :name => "departure_location_index"
  add_index "flights", ["departure_time"], :name => "departure_time_index"
  add_index "flights", ["landed"], :name => "landed_index"
  add_index "flights", ["landing_location"], :name => "landing_location_index"
  add_index "flights", ["landing_time"], :name => "landing_time_index"
  add_index "flights", ["launch_method_id"], :name => "launch_method_id_index"
  add_index "flights", ["mode"], :name => "mode_index"
  add_index "flights", ["pilot_id"], :name => "pilot_id_index"
  add_index "flights", ["plane_id"], :name => "plane_id_index"
  add_index "flights", ["towflight_landed"], :name => "towflight_landed_index"
  add_index "flights", ["towflight_landing_location"], :name => "towflight_landing_location_index"
  add_index "flights", ["towflight_landing_time"], :name => "towflight_landing_time_index"
  add_index "flights", ["towflight_mode"], :name => "towflight_mode_index"
  add_index "flights", ["towpilot_id"], :name => "towpilot_id_index"
  add_index "flights", ["towplane_id"], :name => "towplane_id_index"
  add_index "flights", ["type"], :name => "type_index"

  create_table "launch_methods", :force => true do |t|
    t.string  "name"
    t.string  "short_name"
    t.string  "log_string"
    t.string  "keyboard_shortcut",     :limit => 1
    t.string  "type"
    t.string  "towplane_registration"
    t.boolean "person_required"
    t.string  "comments"
  end

  create_table "people", :force => true do |t|
    t.string  "last_name"
    t.string  "first_name"
    t.string  "club"
    t.string  "nickname"
    t.string  "club_id"
    t.string  "comments"
    t.date    "medical_validity"
    t.boolean "check_medical_validity"
  end

  add_index "people", ["club"], :name => "club_index"
  add_index "people", ["club_id"], :name => "club_id_index"

  create_table "planes", :force => true do |t|
    t.string  "registration"
    t.string  "club"
    t.integer "num_seats"
    t.string  "type"
    t.string  "category"
    t.string  "callsign"
    t.string  "comments"
  end

  add_index "planes", ["club"], :name => "club_index"
  add_index "planes", ["registration"], :name => "registration_index"

  create_table "users", :force => true do |t|
    t.string  "username",            :null => false
    t.string  "password"
    t.boolean "perm_club_admin"
    t.boolean "perm_read_flight_db"
    t.string  "club"
    t.integer "person_id"
    t.string  "comments"
  end

  add_index "users", ["person_id"], :name => "person_id_index"
  add_index "users", ["username"], :name => "username_index"

end
