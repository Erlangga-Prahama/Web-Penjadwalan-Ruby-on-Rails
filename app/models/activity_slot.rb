class ActivitySlot < ApplicationRecord
  belongs_to :activity
  belongs_to :time_block

  validates :time_block_id, uniqueness: { scope: :activity_id }
end
