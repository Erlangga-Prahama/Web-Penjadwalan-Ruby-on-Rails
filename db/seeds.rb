# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Definisikan slot pagi: [order, time_range]
# Jumat (day_id: 5) sesi Pagi
monday_pagi = [
  [1, "07:00 - 08:00"],
  [2, "08:00 - 08:35"],
  [3, "08:35 - 09:10"],
  [4, "09:10 - 09:45"],
  [5, "09:45 - 10:20"],
  [6, "10:20 - 10:40"],
  [7, "10:40 - 11:10"],
  [8, "11:10 - 11:40"],
  [9, "11:40 - 12:10"]
]

monday_pagi.each do |order, time_range|
  TimeBlock.find_or_create_by!(day_id: 1, order: order, session: "pagi") do |tb|
    tb.time = time_range
  end
end


time_slots = [
  [1, "07:00 - 07:35"],
  [2, "07:35 - 08:10"],
  [3, "08:10 - 08:45"],
  [4, "08:45 - 09:20"],
  [5, "09:20 - 09:40"],
  [6, "09:40 - 10:15"],
  [7, "10:15 - 10:50"],
  [8, "10:50 - 11:25"],
  [9, "11:25 - 12:00"]
]

# Untuk setiap hari dari Selasa (2) hingga Kamis (4)
(2..4).each do |day_id|
  time_slots.each do |order, time_range|
    TimeBlock.find_or_create_by!(
      day_id:  day_id,
      order:   order,
      time:    time_range,
      session: "pagi"
    )
  end
end

# Jumat (day_id: 5) sesi Pagi
friday_pagi = [
  [1, "07:00 - 08:00"],
  [2, "08:00 - 08:35"],
  [3, "08:35 - 09:10"],
  [4, "09:10 - 09:45"],
  [5, "09:45 - 10:05"],
  [6, "10:05 - 10:40"],
  [7, "10:40 - 11:15"]
]

friday_pagi.each do |order, time_range|
  TimeBlock.find_or_create_by!(day_id: 5, order: order, session: "pagi") do |tb|
    tb.time = time_range
  end
end

# Definisikan slot siang: [order, time_range]
siang_slots = [
  [1, "12:30 - 13:05"],
  [2, "13:05 - 13:40"],
  [3, "13:40 - 14:15"],
  [4, "14:15 - 14:50"],
  [5, "14:50 - 15:25"],
  [6, "15:25 - 15:45"],
  [7, "15:45 - 16:15"],
  [8, "16:15 - 16:45"],
  [9, "16:45 - 17:15"]
]

# Untuk setiap hari dari Senin (1) hingga Kamis (4)
(1..5).each do |day_id|
  siang_slots.each do |order, time_range|
    TimeBlock.find_or_create_by!(
      day_id:  day_id,
      order:   order,
      time:    time_range,
      session: "siang"
    )
  end
end






