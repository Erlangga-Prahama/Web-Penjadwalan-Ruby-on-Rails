class Activity < ApplicationRecord
  has_many :activity_slots, dependent: :destroy
  has_many :time_blocks, through: :activity_slots
  
  

  validates :name, :day, presence: {message: "tidak boleh kosong"}
  validates :name, format: { without: /\A\d+\z/, message: "tidak boleh hanya berisi angka" }
  validate :time_blocks_must_belong_to_day

  validate :time_blocks_must_be_unique


  def time_blocks_must_belong_to_day
    day_record = Day.find_by(name: day)
    return if day_record.nil?

    invalid_blocks = time_blocks.where.not(day_id: day_record.id)

    if invalid_blocks.exists?
      errors.add(:time_blocks, "hanya boleh dari hari #{day}")
    end
  end

  def time_blocks_must_be_unique
    if time_block_ids.uniq.length != time_block_ids.length
      errors.add(:time_blocks, "tidak boleh duplikat")
    end
  end

  def really_active?
    is_active && time_blocks.joins(:day).where(is_active: true, days: { is_active: true }).exists?
  end
end
