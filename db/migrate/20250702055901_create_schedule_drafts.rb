class CreateScheduleDrafts < ActiveRecord::Migration[7.1]
  def change
    create_table :schedule_drafts do |t|
      t.references :class_room, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: true
      t.references :time_block, null: false, foreign_key: true
      t.string :day
      t.integer :week
      t.boolean :locked
      t.string :status

      t.timestamps
    end
  end
end
