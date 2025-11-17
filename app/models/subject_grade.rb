class SubjectGrade < ApplicationRecord
  belongs_to :subject

  validates :weekly_sessions, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_blank: true

end
