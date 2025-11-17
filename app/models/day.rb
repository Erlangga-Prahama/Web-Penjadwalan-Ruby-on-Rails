class Day < ApplicationRecord
  has_many :time_blocks, dependent: :destroy

  validates :name, presence: {message: "tidak boleh kosong"}
  validates :name, length: {minimum: 4, message: "minimal terdiri dari empat karakter"}, format: { with: /\A[\p{L}'\-\.\s]+\z/u,
    message: "hanya boleh mengandung huruf" }, uniqueness: {message: "hari sudah ada"}

  after_update :sync_time_blocks_activity, if: :saved_change_to_is_active?

  private

  def sync_time_blocks_activity
    # Update semua time_blocks yang berelasi sesuai is_active day
    time_blocks.update_all(is_active: self.is_active)
  end
end
