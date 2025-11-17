class UnavailableTime < ApplicationRecord
  belongs_to :teacher
  belongs_to :time_block

  validates :teacher_id, uniqueness: { scope: :time_block_id, message: "sudah tidak tersedia di waktu ini" }
end
