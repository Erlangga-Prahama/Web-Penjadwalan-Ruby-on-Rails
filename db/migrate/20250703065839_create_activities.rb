class CreateActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :activities do |t|
      t.string :name
      t.string :day
      t.integer :time_block_ids, array: true, default: []
      t.integer :grade

      t.timestamps
    end
  end
end
