class CreateSubjectGrades < ActiveRecord::Migration[7.1]
  def change
    create_table :subject_grades do |t|
      t.references :subject, null: false, foreign_key: true
      t.integer :grade
      t.integer :weekly_sessions

      t.timestamps
    end
  end
end
