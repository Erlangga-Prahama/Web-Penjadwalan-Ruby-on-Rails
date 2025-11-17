class CreateSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :schedules do |t|
      t.references :class_room, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: true
      t.references :time_block, null: false, foreign_key: true
      t.string :day
      t.integer :week
      t.boolean :locked
      t.string :status
      t.references :schedule_batch, null: false, foreign_key: true
      t.timestamps
    end
    # Tambahkan index untuk optimasi dan uniqueness
    add_index :schedules, [:teacher_id, :day, :time_block_id], unique: true, name: 'idx_teacher_availability'
  end
end
