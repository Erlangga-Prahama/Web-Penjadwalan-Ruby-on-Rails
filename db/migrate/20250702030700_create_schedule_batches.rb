class CreateScheduleBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :schedule_batches do |t|
      t.string :name
      t.string :year
      t.text :description

      t.timestamps
    end
  end
end
