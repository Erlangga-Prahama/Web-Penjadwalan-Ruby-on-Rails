class CreateTimeBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :time_blocks do |t|
      t.integer :order
      t.string :time

      t.timestamps
    end
  end
end
