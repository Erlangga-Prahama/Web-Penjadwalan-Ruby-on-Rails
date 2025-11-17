class ScheduleDraft < ApplicationRecord
  belongs_to :class_room
  belongs_to :subject
  belongs_to :teacher
  belongs_to :time_block
end
