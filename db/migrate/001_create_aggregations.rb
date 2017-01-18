class CreateAggregations < ActiveRecord::Migration
  def change

    create_table "aggregations", id: false, force: :cascade do |t|
      t.date    "today",                      null: false
      t.integer "issue_id",       limit: 4,   null: false
      t.integer "project_id",     limit: 2,   null: false
      t.integer "tracker_id",     limit: 2,   null: false
      t.integer "status_id",      limit: 2,   null: false
      t.integer "priority_id",    limit: 2,   null: false
      t.integer "assigned_to_id", limit: 2
      t.integer "category_id",    limit: 2
      t.date    "start_date"
      t.date    "due_date"
      t.float   "estimated_hours",      limit: 24
      t.float   "act_value",      limit: 24
      t.float   "plan_value",     limit: 24
      t.float   "progress",       limit: 24
      t.string  "custom_value",   limit: 512
      t.string  "subject",        limit: 255
    end

    add_index "aggregations", ["today", "issue_id"], name: "aggregations_today_issue_id_uindex", unique: true, using: :btree
    add_index "aggregations", ["today"], name: "today", using: :btree

  end
end
