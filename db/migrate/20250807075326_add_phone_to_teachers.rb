class AddPhoneToTeachers < ActiveRecord::Migration[7.1]
  def change
    add_column :teachers, :phone, :string
  end
end
