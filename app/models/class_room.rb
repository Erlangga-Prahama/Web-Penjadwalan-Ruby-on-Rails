class ClassRoom < ApplicationRecord
    has_many :teacher_class_assignments, dependent: :destroy
    has_many :teachers, through: :teacher_class_assignments

    validates :name, presence: {message: "tidak boleh kosong"}, uniqueness: {message: "kelas sudah ada"}, format: { without: /\A\d+\z/, message: "tidak boleh hanya berisi angka" }
    validates :session, inclusion: { in: %w[pagi siang], message: "harus pagi atau siang" }

    # class_room.rb
    def subject_grades
        SubjectGrade.where(grade: self.grade)
    end

end
