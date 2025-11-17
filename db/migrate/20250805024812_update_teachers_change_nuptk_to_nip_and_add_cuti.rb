class UpdateTeachersChangeNuptkToNipAndAddCuti < ActiveRecord::Migration[7.1]
  def change
    rename_column :teachers, :NUPTK, :NIP
    add_column :teachers, :cuti, :boolean, default: false
  end
end
