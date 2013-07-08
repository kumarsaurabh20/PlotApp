# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130708175336) do

  create_table "plot_images", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "graph_file_name"
    t.string   "graph_content_type"
    t.integer  "graph_file_size"
    t.datetime "graph_updated_at"
    t.integer  "plot_id"
  end

  create_table "plots", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "calibFile"
    t.integer  "explVariable"
    t.integer  "respVariable"
    t.string   "expName"
  end

end
