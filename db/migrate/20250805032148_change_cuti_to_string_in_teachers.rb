class ChangeCutiToStringInTeachers < ActiveRecord::Migration[7.1]
  def change
    change_column :teachers, :cuti, :string
  end
end
