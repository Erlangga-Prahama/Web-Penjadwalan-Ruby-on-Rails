class CreateClassRooms < ActiveRecord::Migration[7.1]
  def change
    create_table :class_rooms do |t|
      t.string :name

      t.timestamps
    end
  end
end
