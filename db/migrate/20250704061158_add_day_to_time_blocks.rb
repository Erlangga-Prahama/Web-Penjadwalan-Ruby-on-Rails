class AddDayToTimeBlocks < ActiveRecord::Migration[7.1]
  def change
    add_reference :time_blocks, :day, null: false, foreign_key: true
  end
end
