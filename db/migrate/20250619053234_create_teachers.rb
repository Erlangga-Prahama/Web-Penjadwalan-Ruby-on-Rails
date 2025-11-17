class CreateTeachers < ActiveRecord::Migration[7.1]
  def change
    create_table :teachers do |t|
      t.string :nama
      t.string :NIK
      t.string :NUPTK
      t.string :tempat_lahir
      t.string :tanggal_lahir
      t.string :agama
      t.string :jk
      t.text :alamat
      t.string :jenjang
      t.string :prodi
      t.string :tahun_lulus

      t.timestamps
    end
  end
end
