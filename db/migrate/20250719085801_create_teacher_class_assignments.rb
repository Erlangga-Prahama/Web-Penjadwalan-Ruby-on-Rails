class CreateTeacherClassAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :teacher_class_assignments do |t|
      t.references :teacher, null: false, foreign_key: true
      t.references :class_room, null: false, foreign_key: true

      t.timestamps
    end
  end
end
