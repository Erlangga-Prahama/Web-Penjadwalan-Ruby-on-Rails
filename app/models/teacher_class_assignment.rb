class TeacherClassAssignment < ApplicationRecord
  belongs_to :teacher
  belongs_to :class_room
end
