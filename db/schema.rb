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

ActiveRecord::Schema[7.1].define(version: 2025_08_26_020730) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.string "name"
    t.string "day"
    t.integer "time_block_ids", default: [], array: true
    t.integer "grade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_active", default: true
  end

  create_table "activity_slots", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.bigint "time_block_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_activity_slots_on_activity_id"
    t.index ["time_block_id"], name: "index_activity_slots_on_time_block_id"
  end

  create_table "class_rooms", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "session"
    t.integer "grade"
    t.boolean "is_active", default: true
  end

  create_table "days", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_active", default: true
  end

  create_table "schedule_batches", force: :cascade do |t|
    t.string "name"
    t.string "year"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "schedule_code"
  end

  create_table "schedule_drafts", force: :cascade do |t|
    t.bigint "class_room_id", null: false
    t.bigint "subject_id", null: false
    t.bigint "teacher_id", null: false
    t.bigint "time_block_id", null: false
    t.string "day"
    t.integer "week"
    t.boolean "locked"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["class_room_id"], name: "index_schedule_drafts_on_class_room_id"
    t.index ["subject_id"], name: "index_schedule_drafts_on_subject_id"
    t.index ["teacher_id"], name: "index_schedule_drafts_on_teacher_id"
    t.index ["time_block_id"], name: "index_schedule_drafts_on_time_block_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.string "day"
    t.integer "week"
    t.boolean "locked"
    t.string "status"
    t.bigint "schedule_batch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "class_room_name"
    t.string "subject_code"
    t.string "subject_name"
    t.string "teacher_name"
    t.string "day_name"
    t.string "session"
    t.string "time_text"
    t.string "activity_names"
    t.string "teacher_code"
    t.index ["schedule_batch_id"], name: "index_schedules_on_schedule_batch_id"
  end

  create_table "subject_grades", force: :cascade do |t|
    t.bigint "subject_id", null: false
    t.integer "grade"
    t.integer "weekly_sessions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id"], name: "index_subject_grades_on_subject_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_active", default: true
  end

  create_table "teacher_class_assignments", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.bigint "class_room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["class_room_id"], name: "index_teacher_class_assignments_on_class_room_id"
    t.index ["teacher_id"], name: "index_teacher_class_assignments_on_teacher_id"
  end

  create_table "teachers", force: :cascade do |t|
    t.string "nama"
    t.string "NIK"
    t.string "NIP"
    t.string "tempat_lahir"
    t.string "tanggal_lahir"
    t.string "agama"
    t.string "jk"
    t.text "alamat"
    t.string "jenjang"
    t.string "prodi"
    t.string "tahun_lulus"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "teacher_code"
    t.string "cuti", default: "false"
    t.string "phone"
    t.boolean "is_active", default: true
  end

  create_table "teaching_assignments", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.bigint "subject_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id"], name: "index_teaching_assignments_on_subject_id"
    t.index ["teacher_id"], name: "index_teaching_assignments_on_teacher_id"
  end

  create_table "time_blocks", force: :cascade do |t|
    t.integer "order"
    t.string "time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "day_id", null: false
    t.string "session"
    t.boolean "is_active", default: true
    t.index ["day_id"], name: "index_time_blocks_on_day_id"
  end

  create_table "unavailable_times", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.bigint "time_block_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["teacher_id"], name: "index_unavailable_times_on_teacher_id"
    t.index ["time_block_id"], name: "index_unavailable_times_on_time_block_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "role"
    t.bigint "teacher_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.index ["teacher_id"], name: "index_users_on_teacher_id"
  end

  add_foreign_key "activity_slots", "activities"
  add_foreign_key "activity_slots", "time_blocks"
  add_foreign_key "schedule_drafts", "class_rooms"
  add_foreign_key "schedule_drafts", "subjects"
  add_foreign_key "schedule_drafts", "teachers"
  add_foreign_key "schedule_drafts", "time_blocks"
  add_foreign_key "schedules", "schedule_batches"
  add_foreign_key "subject_grades", "subjects"
  add_foreign_key "teacher_class_assignments", "class_rooms"
  add_foreign_key "teacher_class_assignments", "teachers"
  add_foreign_key "teaching_assignments", "subjects"
  add_foreign_key "teaching_assignments", "teachers"
  add_foreign_key "time_blocks", "days"
  add_foreign_key "unavailable_times", "teachers"
  add_foreign_key "unavailable_times", "time_blocks"
  add_foreign_key "users", "teachers"
end
