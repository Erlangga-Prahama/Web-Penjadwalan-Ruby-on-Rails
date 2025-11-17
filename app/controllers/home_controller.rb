class HomeController < ApplicationController
    before_action :authenticate_user!

    def index 
        @user = current_user
        @teacher = current_user

        @batch = @batch = ScheduleBatch
           .joins(:schedules)
           .where(schedules: { status: "final" })
           .order(id: :desc)
           .distinct
           .first

        @schedules = @batch.schedules
                            .where(status: "final", teacher_code: @teacher.teacher.teacher_code)
                            .order(:day_name, :time_text) # Berdasarkan kolom yang ada

        @schedules_by_day = @schedules.group_by(&:day_name)

        @today = Date.today.strftime("%A").downcase
        @today_in_indonesian = {
        "monday" => "Senin",
        "tuesday" => "Selasa",
        "wednesday" => "Rabu",
        "thursday" => "Kamis",
        "friday" => "Jumat",
        "saturday" => "Sabtu",
        "sunday" => "Minggu"
        }[@today]

        @todays_schedule = @schedules_by_day[@today_in_indonesian] || []
    end
    
    def jadwal 
        @user = current_user
        @teacher = current_user

        @batch = @batch = ScheduleBatch
           .joins(:schedules)
           .where(schedules: { status: "final" })
           .order(id: :desc)
           .distinct
           .first

        @schedules = @batch.schedules
                            .where(status: "final", teacher_code: @teacher.teacher.teacher_code)
                            .order(:day_name, :time_text) # Berdasarkan kolom yang ada

        @schedules_by_day = @schedules.group_by(&:day_name)

        @today = Date.today.strftime("%A").downcase
        @today_in_indonesian = {
        "monday" => "Senin",
        "tuesday" => "Selasa",
        "wednesday" => "Rabu",
        "thursday" => "Kamis",
        "friday" => "Jumat",
        "saturday" => "Sabtu",
        "sunday" => "Minggu"
        }[@today]

        @todays_schedule = @schedules_by_day[@today_in_indonesian] || []
    end

end
