class AddSessionToTimeBlocks < ActiveRecord::Migration[7.1]
  def change
    add_column :time_blocks, :session, :string
  end
end
