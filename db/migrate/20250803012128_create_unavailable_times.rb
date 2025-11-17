class CreateUnavailableTimes < ActiveRecord::Migration[7.1]
  def change
    create_table :unavailable_times do |t|
      t.references :teacher, null: false, foreign_key: true
      t.references :time_block, null: false, foreign_key: true

      t.timestamps
    end
  end
end
