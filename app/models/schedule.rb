class Schedule < ApplicationRecord
  belongs_to :schedule_batch
  validates :day_name, inclusion: { in: %w[Senin Selasa Rabu Kamis Jumat] }

  # Jika kamu tetap ingin validasi tambahan untuk field snapshot (string/integer):
end
