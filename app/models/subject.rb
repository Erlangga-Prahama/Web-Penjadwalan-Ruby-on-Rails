class Subject < ApplicationRecord
    has_many :teaching_assignments, dependent: :destroy
    has_many :teachers, through: :teaching_assignments
    has_many :subject_grades, dependent: :destroy
    accepts_nested_attributes_for :subject_grades, allow_destroy: true

    validates :name, :code, presence: {message: "tidak boleh kosong"}
    validates :name, length: {minimum: 5, message: "minimal terdiri dari lima karakter"}, format: { with: /\A[\p{L}'\-\.\s]+\z/u,
    message: "hanya boleh berisi huruf" }, uniqueness: {message: "mata pelajaran sudah ada"}
    validates :code, length: { in: 2..7, message: "terdiri dari 2 sampai 6 karakter" } , uniqueness: {message: "kode mata pelajaran sudah ada"}

    after_update :sync_teachers_activity, if: :saved_change_to_is_active?
    
    def significant_changes?
        will_save_change_to_name? || will_save_change_to_code?
    end

    private

    def sync_teachers_activity
        # Set semua teacher yang mengajar subject ini sesuai is_active
        teachers.update_all(is_active: self.is_active)
    end
end
