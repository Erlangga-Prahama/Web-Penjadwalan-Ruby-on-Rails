class ScheduleGenerator
  DAY_ORDER = {
    "Senin" => 1,
    "Selasa" => 2,
    "Rabu"   => 3,
    "Kamis"  => 4,
    "Jumat"  => 5,
    "Sabtu"  => 6
  }
  MAX_GENERATIONS = 50
  POPULATION_SIZE = 50
  MUTATION_RATE = 0.1
  ELITE_COUNT = 10
  TIME_LIMIT_SECONDS = 180

  def initialize(session:, teacher_class_history: nil)
    @session = session
    @subjects = Subject.where(is_active: true).includes(:subject_grades, :teachers)
    @class_rooms = ClassRoom.where(session: session, is_active: true)
    @time_blocks = TimeBlock
      .where(session: session, is_active: true)
      .includes(:day)
      .select { |tb| tb.day.is_active? }
    @teachers_on_leave = Teacher.where(cuti: "true", is_active: true).pluck(:id).to_set
    all_blocks = TimeBlock.includes(:day).where(session: session)

    @teachers_by_subject = Hash.new { |h, k| h[k] = [] }
    Subject.includes(:teachers).each do |subject|
      @teachers_by_subject[subject.id] = subject.teachers.to_a
    end

    @unavailable_block_ids_by_teacher = UnavailableTime.all.group_by(&:teacher_id).transform_values do |entries|
      entries.map(&:time_block_id).to_set
    end

    @activities  = Activity.where(is_active: true).includes(:time_blocks).select do |a|
      a.time_blocks.any? { |tb| tb.session == session && tb.is_active? && tb.day.is_active? }
    end
    @fixed_teacher_assignments = {}

    @teacher_class_history = teacher_class_history || Hash.new { |h, k| h[k] = Set.new }

    @teacher_class_map = TeacherClassAssigner.new(subjects: @subjects, class_rooms: @class_rooms).assign

    @weekly_sessions_map = {}

    @class_rooms.each do |class_room|
      grade = class_room.grade
      @subjects.each do |subject|
        subject_grade = class_room.subject_grades.find_by(subject_id: subject.id)
        if subject_grade
          @weekly_sessions_map[[class_room.id, subject.id]] = subject_grade.weekly_sessions
        end
      end
    end

    @activity_blocks_by_class = Hash.new { |h, k| h[k] = Set.new }

    @class_rooms.each do |class_room|
      grade = class_room.grade
        @activity_blocks_by_class[class_room.id] = Set.new(
          @activities
            .select { |a| a.grade == grade }
            .flat_map(&:time_blocks)
            .select { |tb| tb.session == @session && tb.is_active? && tb.day.is_active? }
        )
    end

    @available_teachers = Teacher.where.not(id: @teachers_on_leave.to_a).to_a
  end

  def run
    # if @class_rooms.size < 5 || @time_blocks.size < 20
    #   puts "⚡ Data kecil, gunakan greedy scheduler..."
    #   schedule = greedy_schedule
    #   save_schedule(schedule)
    #   return
    # end

    puts "🚀 Memulai proses Genetic Algorithm..."
    start_time = Time.now

    population = []
    while population.size < POPULATION_SIZE
      candidate = generate_random_schedule
      population << candidate unless candidate.empty?
    end

    MAX_GENERATIONS.times do |generation|
      break if Time.now - start_time > TIME_LIMIT_SECONDS

      population = population.sort_by { |s| -fitness(s) }

      best_fitness = fitness(population.first)
      avg_fitness = population.map { |s| fitness(s) }.sum / population.size.to_f

      puts "📊 Generasi #{generation + 1} | Best: #{best_fitness.round(4)} | Avg: #{avg_fitness.round(4)}"

      break if best_fitness >= 1.0

      next_gen = population.first(ELITE_COUNT)
      while next_gen.size < POPULATION_SIZE
        parent1, parent2 = select_parents(population)
        next if parent1.nil? || parent2.nil? || parent1.empty? || parent2.empty?

        child = crossover(parent1, parent2)
        child = mutate(child) if rand < MUTATION_RATE
        next_gen << child unless child.empty?
      end

      population = next_gen
    end

    puts "📝 Menyimpan jadwal terbaik..."
    save_schedule(population.first)
  end

  private

  def greedy_schedule
    schedule = []

    # tracking konflik & kapasitas
    teacher_usage = Hash.new { |h, k| h[k] = Set.new }       # teacher_id -> Set[time_block_id]
    class_usage   = Hash.new { |h, k| h[k] = Set.new }       # class_id   -> Set[time_block_id]
    subject_day_count = Hash.new { |h, k| h[k] = Hash.new(0) } # [class_id, subject_id] -> { "Senin" => n, ... }
    assigned_count = Hash.new(0)                             # [class_id, subject_id] -> jumlah sesi yg sudah terjadwal

    grouped_blocks = @time_blocks.group_by { |tb| tb.day.name }
    remaining_sessions = {}

    # ========== FASE 1: distribusi awal (taati kapasitas) ==========
    @class_rooms.shuffle.each do |class_room|
      @subjects
        .sort_by { |s| [-@weekly_sessions_map[[class_room.id, s.id]].to_i, rand] }
        .each do |subject|

        limit = @weekly_sessions_map[[class_room.id, subject.id]].to_i
        next if limit <= 0

        teacher_id = @teacher_class_map[[subject.id, class_room.id]]
        next unless teacher_id
        next if @teachers_on_leave.include?(teacher_id)

        grouped_blocks.each do |day, blocks|
          blocks.shuffle.each do |block|
            break if assigned_count[[class_room.id, subject.id]] >= limit

            next if @activity_blocks_by_class[class_room.id].include?(block)
            next if @unavailable_block_ids_by_teacher[teacher_id]&.include?(block.id)
            next if teacher_usage[teacher_id].include?(block.id)
            next if class_usage[class_room.id].include?(block.id)
            next if subject_day_count[[class_room.id, subject.id]][day] >= 2

            # assign
            schedule << {
              class_room_id: class_room.id,
              subject_id: subject.id,
              teacher_id: teacher_id,
              time_block_id: block.id
            }

            teacher_usage[teacher_id] << block.id
            class_usage[class_room.id] << block.id
            subject_day_count[[class_room.id, subject.id]][day] += 1
            assigned_count[[class_room.id, subject.id]] += 1
          end
        end

        # simpan sisa jika belum penuh
        if assigned_count[[class_room.id, subject.id]] < limit
          remaining_sessions[[class_room.id, subject.id, teacher_id]] =
            limit - assigned_count[[class_room.id, subject.id]]
        end
      end
    end

    # ========== FASE 2: isi sisa (aturan hari dilonggarkan, tetap taati kapasitas) ==========
    remaining_sessions.each do |(class_id, subject_id, teacher_id), sisa|
      next if sisa <= 0
      limit = @weekly_sessions_map[[class_id, subject_id]].to_i
      next if limit <= 0

      grouped_blocks.each do |day, blocks|
        blocks.shuffle.each do |block|
          break if sisa <= 0
          break if assigned_count[[class_id, subject_id]] >= limit

          next if @activity_blocks_by_class[class_id].include?(block)
          next if @unavailable_block_ids_by_teacher[teacher_id]&.include?(block.id)
          next if teacher_usage[teacher_id].include?(block.id)
          next if class_usage[class_id].include?(block.id)

          schedule << {
            class_room_id: class_id,
            subject_id: subject_id,
            teacher_id: teacher_id,
            time_block_id: block.id
          }

          teacher_usage[teacher_id] << block.id
          class_usage[class_id] << block.id
          subject_day_count[[class_id, subject_id]][day] += 1
          assigned_count[[class_id, subject_id]] += 1
          sisa -= 1
        end
      end
    end

    # ========== FASE 3: isi slot benar-benar kosong TANPA melewati kapasitas ==========
    @class_rooms.each do |class_room|
      grouped_blocks.each do |day, blocks|
        blocks.each do |block|
          # jangan ganggu activity
          next if @activity_blocks_by_class[class_room.id].include?(block)
          # lewati bila slot kelas ini sudah terisi
          next if class_usage[class_room.id].include?(block.id)

          # pilih subject yang masih punya sisa kapasitas
          candidate = @subjects.shuffle.find do |subject|
            limit = @weekly_sessions_map[[class_room.id, subject.id]].to_i
            next false if limit <= 0
            next false if assigned_count[[class_room.id, subject.id]] >= limit

            t_id = @teacher_class_map[[subject.id, class_room.id]]
            t_id &&
              !@teachers_on_leave.include?(t_id) &&
              !@unavailable_block_ids_by_teacher[t_id]&.include?(block.id) &&
              !teacher_usage[t_id].include?(block.id)
          end

          if candidate
            t_id = @teacher_class_map[[candidate.id, class_room.id]]
            schedule << {
              class_room_id: class_room.id,
              subject_id: candidate.id,
              teacher_id: t_id,
              time_block_id: block.id
            }
            teacher_usage[t_id] << block.id
            class_usage[class_room.id] << block.id
            subject_day_count[[class_room.id, candidate.id]][day] += 1
            assigned_count[[class_room.id, candidate.id]] += 1
          end
        end
      end
    end

    # guard final (kalau ada kelebihan karena perubahan data di tengah jalan)
    enforce_weekly_caps(schedule)
  end

  def generate_random_schedule
    schedule = []
    teacher_usage = Hash.new { |h, k| h[k] = Hash.new { |h2, s| h2[s] = Set.new } }
    class_usage = Hash.new { |h, k| h[k] = Set.new }
    subject_day_count = Hash.new { |h, k| h[k] = Hash.new(0) }

    blocks_by_day = @time_blocks.group_by { |tb| tb.day.name }
    pending_sessions = []
    

    @available_teachers.shuffle.each do |teacher|
      class_rooms_by_subject = @teacher_class_map.select { |(subject_id, class_room_id), t_id| t_id == teacher.id }

      sorted_pairs = class_rooms_by_subject.keys.sort_by do |(subject_id, class_room_id)|
        -@weekly_sessions_map[[class_room_id, subject_id]].to_i
      end


      sorted_pairs.each do |(subject_id, class_room_id)|
        class_room = @class_rooms.find { |c| c.id == class_room_id }
        subject = @subjects.find { |s| s.id == subject_id }

        next unless class_room && subject

        key = [class_room.id, subject.id]
        sessions_left = @weekly_sessions_map[key].to_i
        next if sessions_left <= 0

        activity_block_ids = @activity_blocks_by_class[class_room.id].map(&:id).to_set
        used_blocks = class_usage[class_room.id] 

        blocks_by_day.to_a.shuffle.each do |day_name, day_blocks|
          break if sessions_left <= 0
          next if subject_day_count[key][day_name] >= 2

          available_blocks = day_blocks.reject do |block|
            activity_block_ids.include?(block.id) ||
            teacher_usage[teacher.id][block.session].include?(block) ||
            used_blocks.include?(block) ||
            @unavailable_block_ids_by_teacher[teacher.id]&.include?(block.id)
          end



          grouped_blocks = available_blocks.chunk_while { |a, b| b.order == a.order + 1 }.to_a

          grouped_blocks.shuffle.each do |block_group|
            break if sessions_left <= 0

            # if sessions_left == 2
            #   consecutive_pair = block_group.each_cons(2).find { |a, b| b.order == a.order + 1 }
            #   next unless consecutive_pair
            #   blocks_to_use = consecutive_pair
            # else
            #   blocks_to_use = block_group.first([sessions_left, 3].min)
            # end

            #------------
            if sessions_left == 2
              consecutive_pair = block_group.each_cons(2).find { |a, b| b.order == a.order + 1 }

              # CEK KONDISI KAMU
              unique_teacher_for_subject = @available_teachers.select do |t|
                @teacher_class_map[[subject.id, class_room.id]] == t.id
              end.uniq.size == 1

              if consecutive_pair && !(sessions_left > 1 && unique_teacher_for_subject)
                blocks_to_use = consecutive_pair
              else
                # kalau hanya 1 guru aktif, tidak wajib berurutan
                blocks_to_use = block_group.first([sessions_left, 2].min)
              end
            else
              blocks_to_use = block_group.first([sessions_left, 3].min)
            end
            #----------------------------

            if sessions_left > 0
              pending_sessions << {
                class_room_id: class_room.id,
                subject_id: subject.id,
                teacher_id: teacher.id,
                sessions_left: sessions_left
              }
            end

            next if blocks_to_use.empty?

            blocks_to_use.each do |block|
              schedule << {
                class_room_id: class_room.id,
                subject_id: subject.id,
                teacher_id: teacher.id,
                time_block_id: block.id
              }
              teacher_usage[teacher.id][block.session] << block
              used_blocks << block
              sessions_left -= 1
            end

            subject_day_count[key][day_name] += 1
            break
          end
        end
      end
    end

    pending_sessions.each do |entry|
      class_room = @class_rooms.find { |c| c.id == entry[:class_room_id] }
      subject = @subjects.find { |s| s.id == entry[:subject_id] }
      teacher_id = entry[:teacher_id]
      sessions_left = entry[:sessions_left]

      blocks = @time_blocks.shuffle.reject do |block|
        @activity_blocks_by_class[class_room.id].map(&:id).include?(block.id) ||
        teacher_usage[teacher_id][block.session].include?(block) ||
        class_usage[class_room.id].include?(block) ||
        @unavailable_block_ids_by_teacher[teacher_id]&.include?(block.id)
      end


      blocks.first(sessions_left).each do |block|
        schedule << {
          class_room_id: class_room.id,
          subject_id: subject.id,
          teacher_id: teacher_id,
          time_block_id: block.id
        }
        teacher_usage[teacher_id][block.session] << block
        class_usage[class_room.id] << block
        sessions_left -= 1
        break if sessions_left <= 0
      end
    end

    schedule
    if @class_rooms.size < 5 || @time_blocks.size < 20
      enforce_weekly_caps(schedule)
    end
  end


  def fitness(schedule)
    # guard untuk input yang kosong atau nil
    return 0.0 if schedule.nil? || schedule.empty?

    # Hitungan dasar
    total_required = 0
    fulfilled = 0
    penalty = 0.0
    conflict_with_activity = 0

    # Kelompokkan jadwal berdasarkan [kelas, mapel]
    grouped = schedule.group_by { |s| [s[:class_room_id], s[:subject_id]] }

    # Salin histori guru agar tidak mengubah aslinya
    teacher_classes = Hash.new { |h, k| h[k] = Set.new }
    @teacher_class_history.each { |k, v| teacher_classes[k] = v.dup }

    # Pre-compute set id activity per class untuk cek cepat
    activity_ids_by_class = {}
    @class_rooms.each do |cr|
      activity_ids_by_class[cr.id] = @activity_blocks_by_class[cr.id].map(&:id).to_set
    end

    # Evaluasi konflik activity & update kelas yang diajar guru
    schedule.each do |entry|
      teacher_id = entry[:teacher_id]
      class_id = entry[:class_room_id]
      time_block_id = entry[:time_block_id]

      teacher_classes[teacher_id] << class_id

      if activity_ids_by_class[class_id]&.include?(time_block_id)
        conflict_with_activity += 1
      end
    end

    # Penalti untuk guru terlalu sedikit atau terlalu banyak mengajar (berdasarkan jumlah kelas unik)
    teacher_classes.each do |_, class_ids|
      count = class_ids.size
      if count < 4
        penalty += (4 - count) * 2    # guru terlalu nganggur
      elsif count > 12
        penalty += (count - 12)       # guru overload
      end
    end

    # Hitung total_required dan fulfilled (jumlah sesi yang terpenuhi)
    @class_rooms.each do |class_room|
      @subjects.each do |subject|
        sessions_needed = @weekly_sessions_map[[class_room.id, subject.id]].to_i
        next if sessions_needed <= 0

        total_required += sessions_needed
        scheduled = grouped[[class_room.id, subject.id]]&.size.to_i

        # jumlah terpenuhi dikumulasi
        fulfilled += [scheduled, sessions_needed].min

        if scheduled < sessions_needed
          missing = sessions_needed - scheduled
          penalty += missing * 10   # penalti besar untuk kekurangan jam
        end
      end
    end

    # Jika tidak ada requirement sama sekali
    return 0.0 if total_required.zero?

    # Jika semua sesi terpenuhi dan tidak ada konflik activity => sempurna
    if fulfilled == total_required && conflict_with_activity == 0
      return 1.0
    end

    # Normalisasi skor dasar
    base_score = fulfilled.to_f / total_required.to_f

    # Terapkan penalti (dinormalisasi terhadap total_required supaya skala konsisten)
    penalty_norm = (penalty / [total_required, 1].max) * 0.01

    # Penalti untuk konflik activity (lebih berat)
    activity_penalty = (conflict_with_activity.to_f / [total_required, 1].max) * 0.05

    final_score = base_score - penalty_norm - activity_penalty

    final_score.clamp(0.0, 1.0)
  end

  def crossover(parent1, parent2)
    return [] if parent1.empty? || parent2.empty?

    crossover_point = rand([parent1.size, parent2.size].min)
    child = parent1[0...crossover_point] + parent2[crossover_point..]
    child.uniq { |g| [g[:class_room_id], g[:subject_id], g[:time_block_id]] }
  end

  def mutate(schedule)
    return schedule if schedule.empty?

    i = rand(schedule.size)
    mutation = schedule[i].dup

    class_id = mutation[:class_room_id]
    blocked_ids = @activity_blocks_by_class[class_id].map(&:id).to_set
    teacher_id = mutation[:teacher_id]

    # Deteksi pemakaian guru dengan mempertimbangkan sesi
    used_by_teacher_blocks = schedule.select { |s| s[:teacher_id] == teacher_id }.map do |s|
      block = @time_blocks.find { |tb| tb.id == s[:time_block_id] }
      [block.session, block.id] if block
    end.compact.to_set

    used_by_class = schedule.select { |s| s[:class_room_id] == class_id }.map { |s| s[:time_block_id] }

    valid_blocks = @time_blocks.reject do |tb|
      blocked_ids.include?(tb.id) ||
      used_by_teacher_blocks.include?([tb.session, tb.id]) ||
      used_by_class.include?(tb.id) ||
      @unavailable_block_ids_by_teacher[teacher_id]&.include?(tb.id)
    end

    return schedule if valid_blocks.empty?

    mutation[:time_block_id] = valid_blocks.sample.id
    schedule[i] = mutation
    schedule
  end



  def select_parents(population)
    return [nil, nil] if population.size < 2
    population.sample(2)
  end

  def save_schedule(schedule)
    puts "⏳ Menyimpan jadwal hasil genetika..."
    ScheduleDraft.where(class_room: ClassRoom.where(session: @session)).delete_all

    schedule.each do |entry|
      block = TimeBlock.find(entry[:time_block_id])
      ScheduleDraft.create!(
        class_room_id: entry[:class_room_id],
        subject_id: entry[:subject_id],
        teacher_id: entry[:teacher_id],
        time_block_id: entry[:time_block_id],
        week: 1,
        day: block.day.name,
        locked: false,
        status: "draft"
      )
    end

    puts "✅ Jadwal tersimpan!"
  end

  def activity_blocks_for_grade(grade)
    Set.new(
      @activities
        .select { |a| a.grade == grade }
        .flat_map(&:time_blocks)
        .select { |tb| tb.session == @session }
    )
  end

  def assign_fixed_teacher(class_room_id, subject_id, possible_teachers)
    key = [class_room_id, subject_id]
    @fixed_teacher_assignments[key] ||= possible_teachers.sample
  end

  def schedule_valid?(schedule)
    grouped = schedule.group_by { |s| [s[:class_room_id], s[:subject_id]] }

    @class_rooms.all? do |class_room|
      @subjects.all? do |subject|
        expected = @weekly_sessions_map[[class_room.id, subject.id]].to_i
        next true if expected == 0

        scheduled = grouped[[class_room.id, subject.id]]&.size.to_i
        scheduled == expected
      end
    end
  end

  def enforce_weekly_caps(schedule)
    cap = Hash.new(0) # [class_id, subject_id] -> assigned_now
    schedule
      .shuffle # acak agar tidak bias urutan
      .select do |g|
        key = [g[:class_room_id], g[:subject_id]]
        limit = @weekly_sessions_map[key].to_i
        next false if limit <= 0
        if cap[key] < limit
          cap[key] += 1
          true
        else
          false # buang kelebihan
        end
      end
  end

end