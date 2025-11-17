puts "\n📌 SubjectGrades (Mapel per Tingkat):"
SubjectGrade.includes(:subject).order(:grade).each do |sg|
  puts "  - #{sg.subject.name} (Kelas #{sg.grade}) : #{sg.weekly_sessions} sesi/minggu"
end


puts "\n📌 Jumlah Kelas per Sesi:"
ClassRoom.group(:session).count.each do |session, count|
  puts "  - #{session} : #{count} kelas"
end

puts "\n📌 Cek Aktivitas (Activity):"
Activity.includes(:time_blocks).each do |a|
  sessions = a.time_blocks.map(&:session).uniq
  puts "  - #{a.name} (Kelas #{a.grade}) → #{sessions.join(', ')}"
end

puts "\n📌 Jumlah TimeBlock per Hari & Sesi:"
TimeBlock.joins(:day).group(:session, 'days.name').count.each do |(session, day), count|
  puts "  - #{day} (#{session}) : #{count} blok waktu"
end

puts "\n📌 Sisa blok waktu tersedia per kelas (setelah activity):"
ClassRoom.where(session: 'pagi').each do |cr|
  grade = cr.name[/\d+/].to_i
  activity_blocks = Activity.includes(:time_blocks).where(grade: grade).flat_map(&:time_blocks).select { |tb| tb.session == 'pagi' }.uniq
  total_blocks = TimeBlock.includes(:day).where(session: 'pagi').count
  used = activity_blocks.count
  puts "  - #{cr.name} (kelas #{grade}) : #{total_blocks - used} blok sisa"
end


