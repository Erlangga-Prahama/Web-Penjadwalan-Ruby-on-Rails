class AddIsActive < ActiveRecord::Migration[7.1]
  def change
    add_column :subjects, :is_active, :boolean, default: true
    add_column :teachers, :is_active, :boolean, default: true
    add_column :class_rooms, :is_active, :boolean, default: true
    add_column :days, :is_active, :boolean, default: true
    add_column :time_blocks, :is_active, :boolean, default: true
    add_column :activities, :is_active, :boolean, default: true
  end
end
