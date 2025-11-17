class AddGradeToClassRooms < ActiveRecord::Migration[7.1]
  def change
    add_column :class_rooms, :grade, :integer
  end
end
