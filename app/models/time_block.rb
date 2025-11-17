class TimeBlock < ApplicationRecord
    belongs_to :day
    has_many :activity_slots, dependent: :destroy
    has_many :activities, through: :activity_slots
    
    validates :order, :time, :day,  presence: {message: "kedua kolom tidak boleh kosong"}
    validates :session, inclusion: { in: %w[pagi siang], message: "harus pagi atau siang" }
    
    validates :order,  format: { 
        with: /\A[\d:-]+\z/,
        message: "kolom waktu hanya boleh berisi angka (0-9), tanda hubung (-), dan titik dua (:)" 
        }
    validates :time,  format: { 
        with: /\A[\d:\-\s]+\z/,
        message: "kolom waktu hanya boleh berisi angka (0-9), tanda hubung (-), dan titik dua (:)" 
    }
end
