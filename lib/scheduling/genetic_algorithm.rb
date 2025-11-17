module Scheduling
  class GeneticAlgorithm
    DAYS = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat"].freeze
    MAX_TEACHER_HOURS = 20
    MIN_TEACHER_HOURS = 10
    TARGET_FITNESS = -100
    MAX_STAGNATION = 50

    def initialize
      @teachers = Teacher.includes(:subject).to_a
      @class_rooms = ClassRoom.all.to_a
      @time_blocks = TimeBlock.order(:order).to_a
      @subjects = Subject.all.to_a
    end

    def generate
      population_size = 200
      elite_size = 40
      max_generations = 500
      base_mutation_rate = 0.2

      population = initialize_population(population_size)
      best_schedule = nil
      best_fitness = -Float::INFINITY
      stagnation = 0

      max_generations.times do |generation|
        population = evolve(population, elite_size, base_mutation_rate)
        current_best = population.max_by { |s| fitness(s) rescue -Float::INFINITY }
        current_fitness = fitness(current_best) rescue -Float::INFINITY

        if current_fitness > best_fitness
          best_schedule = current_best
          best_fitness = current_fitness
          stagnation = 0
        else
          stagnation += 1
        end

        Rails.logger.info "Gen #{generation}: Fitness #{current_fitness} | Best: #{best_fitness} | Stagnation: #{stagnation}"
        break if best_fitness >= TARGET_FITNESS || stagnation >= MAX_STAGNATION
      end

      best_schedule || []
    end

    def valid_schedule?(schedule)
      return false if schedule.nil? || schedule.empty?

      # Cek semua entry memiliki data lengkap
      schedule.each do |entry|
        unless entry_valid?(entry)
          Rails.logger.warn "Entry tidak valid: #{entry.inspect}"
          return false 
        end
      end

      # Cek konflik guru
      teacher_slots = Set.new
      schedule.each do |entry|
        teacher_key = "#{entry[:teacher_id]}-#{entry[:day]}-#{entry[:time_block_id]}"
        if teacher_slots.include?(teacher_key)
          Rails.logger.warn "Konflik guru: #{teacher_key}"
          return false
        end
        teacher_slots.add(teacher_key)
      end

      # Cek konflik kelas
      class_slots = Set.new
      schedule.each do |entry|
        class_key = "#{entry[:class_room_id]}-#{entry[:day]}-#{entry[:time_block_id]}"
        if class_slots.include?(class_key)
          Rails.logger.warn "Konflik kelas: #{class_key}"
          return false
        end
        class_slots.add(class_key)
      end

      # Cek jam mengajar guru
      teacher_hours = Hash.new(0)
      schedule.each do |entry|
        teacher_hours[entry[:teacher_id]] += 1
      end

      teacher_hours.each do |teacher_id, hours|
        if hours > MAX_TEACHER_HOURS
          Rails.logger.warn "Guru #{teacher_id} kelebihan jam: #{hours}/#{MAX_TEACHER_HOURS}"
          return false
        end
      end

      true
    end

    def entry_valid?(entry)
      entry.is_a?(Hash) &&
      entry[:class_room_id].present? &&
      entry[:subject_id].present? &&
      entry[:teacher_id].present? &&
      entry[:time_block_id].present? &&
      entry[:day].present? &&
      DAYS.include?(entry[:day])
    end

    private

    def initialize_population(size)
      size.times.map { build_schedule }.compact
    end

    def build_schedule
      schedule = []
      available_slots = all_possible_slots.shuffle

      available_slots.each do |slot|
        subject = @subjects.sample
        teacher = @teachers.select { |t| t.subject_id == subject.id }.sample
        next unless teacher

        schedule << {
          class_room_id: slot[:class_room_id],
          subject_id: subject.id,
          teacher_id: teacher.id,
          time_block_id: slot[:time_block_id],
          day: slot[:day],
          week: 1
        }
      end

      schedule.empty? ? nil : schedule
    end

    def all_possible_slots
      @class_rooms.flat_map do |cr|
        DAYS.flat_map do |day|
          @time_blocks.map do |tb|
            {
              class_room_id: cr.id,
              time_block_id: tb.id,
              day: day
            }
          end
        end
      end
    end

    def fitness(schedule)
      return -Float::INFINITY unless valid_schedule?(schedule)

      score = 0
      teacher_hours = Hash.new(0)

      # Hitung distribusi jam mengajar
      schedule.each do |entry|
        teacher_hours[entry[:teacher_id]] += 1
      end

      # Beri reward untuk distribusi merata
      teacher_hours.each do |teacher_id, hours|
        ideal_hours = (MIN_TEACHER_HOURS + MAX_TEACHER_HOURS) / 2.0
        deviation = (hours - ideal_hours).abs
        score -= deviation * 10  # Penalty untuk deviasi dari ideal
      end

      # Bonus untuk jumlah entri
      score += schedule.size * 5

      score.round(2)
    end

    def evolve(population, elite_size, mutation_rate)
      # Filter populasi yang valid
      valid_population = population.compact.reject { |s| s.empty? }
      
      # Pertahankan elite
      elites = valid_population.max_by(elite_size) { |s| fitness(s) }

      # Seleksi orang tua
      parents = (valid_population.size - elite_size).times.map do
        tournament_selection(valid_population)
      end.compact

      # Crossover
      offspring = parents.each_slice(2).flat_map do |p1, p2|
        p2 ? [crossover(p1, p2)].compact : [p1]
      end

      # Mutasi
      mutated = offspring.map { |child| mutate(child, mutation_rate) }.compact

      # Gabungkan semua
      (elites + mutated + initialize_population((population.size * 0.1).round)).compact
    end

    def tournament_selection(population, size: 3)
      candidates = population.sample(size)
      candidates.max_by { |s| fitness(s) }
    end

    def crossover(parent1, parent2)
      return parent1 if parent2.nil? || parent2.empty?
      return parent2 if parent1.nil? || parent1.empty?

      point = rand([parent1.size, parent2.size].min)
      child = parent1[0...point] + parent2[point..-1]
      clean_schedule(child)
    rescue => e
      Rails.logger.error "Crossover error: #{e.message}"
      parent1
    end

    def mutate(schedule, rate)
      return schedule if rand >= rate || schedule.empty?

      # Pilih jenis mutasi acak
      case rand(4)
      when 0 then swap_entries(schedule)
      when 1 then change_teacher(schedule)
      when 2 then shift_time(schedule)
      when 3 then add_or_remove(schedule)
      end

      clean_schedule(schedule)
    rescue => e
      Rails.logger.error "Mutation error: #{e.message}"
      schedule
    end

    # Helper methods untuk mutasi
    def swap_entries(schedule)
      i, j = rand(schedule.size), rand(schedule.size)
      schedule[i], schedule[j] = schedule[j], schedule[i]
    end

    def change_teacher(schedule)
      entry = schedule.sample
      return unless entry

      subject_id = entry[:subject_id]
      competent_teachers = @teachers.select { |t| t.subject_id == subject_id }
      return if competent_teachers.empty?

      entry[:teacher_id] = competent_teachers.sample.id
    end

    def shift_time(schedule)
      entry = schedule.sample
      return unless entry

      current_day = DAYS.index(entry[:day]) || 0
      entry[:day] = DAYS[(current_day + 1) % DAYS.size]
    end

    def add_or_remove(schedule)
      rand < 0.5 ? schedule.pop : schedule << random_entry
    end

    def random_entry
      {
        class_room_id: @class_rooms.sample.id,
        subject_id: @subjects.sample.id,
        teacher_id: @teachers.sample.id,
        time_block_id: @time_blocks.sample.id,
        day: DAYS.sample,
        week: 1
      }
    end

    def clean_schedule(schedule)
      return [] if schedule.nil?

      clean = []
      used_teacher = Set.new
      used_class = Set.new

      schedule.each do |entry|
        next unless entry_valid?(entry)

        teacher_key = "#{entry[:teacher_id]}-#{entry[:day]}-#{entry[:time_block_id]}"
        class_key = "#{entry[:class_room_id]}-#{entry[:day]}-#{entry[:time_block_id]}"

        unless used_teacher.include?(teacher_key) || used_class.include?(class_key)
          clean << entry
          used_teacher.add(teacher_key)
          used_class.add(class_key)
        end
      end

      clean
    end

    def entry_valid?(entry)
      entry.is_a?(Hash) &&
      entry[:class_room_id] &&
      entry[:subject_id] &&
      entry[:teacher_id] &&
      entry[:time_block_id] &&
      entry[:day]
    end
  end
end