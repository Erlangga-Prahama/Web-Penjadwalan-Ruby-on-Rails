class AddSessionToClassRooms < ActiveRecord::Migration[7.1]
  def change
    add_column :class_rooms, :session, :string
  end
end
