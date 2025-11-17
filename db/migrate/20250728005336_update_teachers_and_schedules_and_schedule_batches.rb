class UpdateTeachersAndSchedulesAndScheduleBatches < ActiveRecord::Migration[7.1]
  def change
    add_column :schedule_batches, :schedule_code, :string
    add_column :teachers, :teacher_code, :string
    add_column :schedules, :teacher_code, :string
  end
end
