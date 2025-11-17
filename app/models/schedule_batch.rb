class ScheduleBatch < ApplicationRecord
    before_create :generate_schedule_code

    has_many :schedules, dependent: :destroy

    validates :name, :year, presence: true
    validates :name, format: { with: /[A-Za-z0-9]/, message: "tidak boleh hanya berisi simbol" }
    validates :year, format: { with: /\A\d{4}([\/-]\d{2,4})?\z/, message: "format tidak valid" }

     private

    def generate_schedule_code
        today = Date.today
        day   = today.day.to_s.rjust(2, '0')
        month = today.month.to_s.rjust(2, '0')
        year  = today.year.to_s

        prefix = "JDWL#{day}#{month}#{year}"

        count_today = ScheduleBatch.where("schedule_code LIKE ?", "#{prefix}%").count
        serial_number = (count_today + 1).to_s.rjust(3, '0')

        self.schedule_code = "#{prefix}#{serial_number}"
    end
end
