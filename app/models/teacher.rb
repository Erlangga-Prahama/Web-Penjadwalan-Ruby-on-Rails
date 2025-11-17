class Teacher < ApplicationRecord
    has_one :user, dependent: :destroy
    has_many :teaching_assignments, dependent: :destroy
    has_many :subjects, through: :teaching_assignments

    has_many :teacher_class_assignments, dependent: :destroy
    has_many :class_rooms, through: :teacher_class_assignments

    has_many :unavailable_times, dependent: :destroy
    has_many :unavailable_time_blocks, through: :unavailable_times, source: :time_block
    
    before_create :generate_teacher_code

    # Wajib diisi, kecuali NIP dan subject_ids
    validates :nama, :tempat_lahir, :tanggal_lahir, :agama, :jk, :phone, :alamat, :jenjang, :prodi, presence: {message: "tidak boleh kosong"}

    # Nama harus mengandung huruf
    validates :nama, format: { with: /[A-Za-z]/, message: "harus berisi huruf" }
    
    # Semua field tidak boleh hanya berisi simbol
    validates :nama, :tempat_lahir, :alamat, :prodi, format: { with: /[A-Za-z0-9]/, message: "tidak boleh berisi simbol" }

    validates :NIP,:NIK, :phone, :tahun_lulus, allow_blank: true, format: { with: /\A[\d\s]+\z/, message: "hanya boleh berisi angka" }
    
    private

    def generate_teacher_code
        last_code = Teacher.where("teacher_code LIKE ?", "G%")
                        .order(:teacher_code)
                        .pluck(:teacher_code)
                        .last

        last_number = last_code.present? ? last_code[1..].to_i : 0
        next_number = last_number + 1
        self.teacher_code = "G#{next_number.to_s.rjust(3, '0')}"
    end
end
