class CreateActivitySlots < ActiveRecord::Migration[7.1]
  def change
    create_table :activity_slots do |t|
      t.references :activity, null: false, foreign_key: true
      t.references :time_block, null: false, foreign_key: true

      t.timestamps
    end
  end
end
