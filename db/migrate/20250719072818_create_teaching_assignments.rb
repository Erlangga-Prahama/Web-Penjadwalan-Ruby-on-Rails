class CreateTeachingAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :teaching_assignments do |t|
      t.references :teacher, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true

      t.timestamps
    end
  end
end
