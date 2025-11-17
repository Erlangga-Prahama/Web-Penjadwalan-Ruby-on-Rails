class ScheduleGeneratorJob
  include Sidekiq::Worker
  sidekiq_options queue: 'scheduling', retry: 3

  def perform(job_id)
    Rails.logger.info "====== MEMULAI GENERASI JADWAL ======"
    Rails.logger.info "Job ID: #{job_id}"
    
    begin
      generator = Scheduling::GeneticAlgorithm.new
      generated_schedule = generator.generate

      if generated_schedule.nil? || generated_schedule.empty?
        raise "Jadwal yang dihasilkan kosong"
      end

      Rails.logger.info "Memeriksa validitas jadwal..."
      unless generator.valid_schedule?(generated_schedule)
        # Debugging: Cetak contoh entry yang tidak valid
        invalid_entry = generated_schedule.find { |e| !generator.entry_valid?(e) }
        if invalid_entry
          Rails.logger.error "Contoh entry tidak valid: #{invalid_entry.inspect}"
        else
          Rails.logger.error "Jadwal tidak valid (konflik tersembunyi)"
        end
        raise "Jadwal tidak valid"
      end

      # Format untuk penyimpanan
      schedules_to_save = generated_schedule.map do |entry|
        {
          class_room_id: entry[:class_room_id],
          subject_id: entry[:subject_id],
          teacher_id: entry[:teacher_id],
          time_block_id: entry[:time_block_id],
          day: entry[:day],
          week: 1,
          locked: false,
          status: 'active',
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # Simpan ke Redis
      Sidekiq.redis do |conn|
        conn.setex("schedule:#{job_id}", 1.hour.to_i, schedules_to_save.to_json)
      end

      Rails.logger.info "====== GENERASI BERHASIL ======"
      Rails.logger.info "Jumlah Entri: #{schedules_to_save.size}"
      Rails.logger.info "Contoh Entri: #{schedules_to_save.first.inspect}"

    rescue => e
      Rails.logger.error "====== ERROR ======"
      Rails.logger.error "Pesan Error: #{e.message}"
      Rails.logger.error "Backtrace:\n#{e.backtrace.join("\n")}"

      # Simpan error ke Redis untuk ditampilkan ke user
      Sidekiq.redis do |conn|
        conn.setex("schedule:#{job_id}", 1.hour.to_i, {error: e.message}.to_json)
      end

      raise
    end
  end
end