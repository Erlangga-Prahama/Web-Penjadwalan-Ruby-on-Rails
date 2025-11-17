class ChangeSchedulesToArchive < ActiveRecord::Migration[7.1]
  def change
    remove_reference :schedules, :class_room, foreign_key: true
    remove_reference :schedules, :subject, foreign_key: true
    remove_reference :schedules, :teacher, foreign_key: true
    remove_reference :schedules, :time_block, foreign_key: true

    add_column :schedules, :class_room_name, :string
    add_column :schedules, :subject_code, :string
    add_column :schedules, :subject_name, :string
    add_column :schedules, :teacher_name, :string
    add_column :schedules, :day_name, :string
    add_column :schedules, :session, :string
    add_column :schedules, :time_text, :string
    add_column :schedules, :activity_names, :string
  end
end
