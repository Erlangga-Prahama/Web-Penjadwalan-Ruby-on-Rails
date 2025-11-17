class SchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role("kepala_sekolah", "waka_kurikulum") }

  def index
    @schedule_batches = ScheduleBatch
      .joins(:schedules)
      .where(schedules: { status: 'generated' })
      .distinct
      .order(created_at: :desc)
      
    @schedule = ScheduleBatch
      .joins(:schedules)
      .where(schedules: { status: 'final' })
      .distinct
      .order(created_at: :desc)

    @draft = ScheduleDraft.first

    @teachers = Teacher.includes(unavailable_times: { time_block: :day })

    render layout: 'dash_layout'
  end

  def generate_all
    failed_sessions = []
    teacher_class_history = Hash.new { |h, k| h[k] = Set.new }

    # =========================
    # Cek resource aktif
    # =========================
    active_class_rooms = ClassRoom.where(is_active: true)
    if active_class_rooms.empty?
      flash[:danger] = "Tidak ada kelas aktif."
      redirect_to schedules_path and return
    end

    active_teachers = Teacher.where(cuti: "false", is_active: true)
    if active_teachers.empty?
      flash[:danger] = "Tidak ada guru aktif."
      redirect_to schedules_path and return
    end

    active_subjects = Subject.joins(:subject_grades)
                            .where(is_active: true)
                            .where('subject_grades.weekly_sessions > 0')
                            .distinct
    if active_subjects.empty?
      flash[:danger] = "Tidak ada mata pelajaran aktif."
      redirect_to schedules_path and return
    end

    active_days = Day.where(is_active: true)
    if active_days.empty?
      flash[:danger] = "Tidak ada hari aktif."
      redirect_to schedules_path and return
    end

    active_time_blocks = TimeBlock.where(is_active: true)
    if active_time_blocks.empty?
      flash[:danger] = "Tidak ada jam pelajaran aktif."
      redirect_to schedules_path and return
    end

    # =========================
    # 🔍 Deteksi infeasibility awal PER SESI & PER GRADE
    # =========================
    problems = []
    active_sessions = active_class_rooms.distinct.pluck(:session)

    active_sessions.each do |session|
      session_class_rooms = active_class_rooms.where(session: session)
      time_blocks_scope = TimeBlock.joins(:day)
                                  .where(session: session, is_active: true, days: { is_active: true })

      if time_blocks_scope.count == 0
        problems << "Sesi #{session} tidak memiliki jam pelajaran aktif."
        next
      end

      session_class_rooms.group_by(&:grade).each do |grade, class_rooms|
        # ambil time_block yang dipakai activity untuk grade ini
        used_time_block_ids_for_grade = ActivitySlot.joins(:activity)
                                                    .where(activities: { grade: grade, is_active: true })
                                                    .where(time_block_id: time_blocks_scope.select(:id))
                                                    .distinct
                                                    .pluck(:time_block_id)
        session_time_blocks_for_grade = time_blocks_scope.where.not(id: used_time_block_ids_for_grade)

        counts_per_day_grade = session_time_blocks_for_grade.group(:day_id).count
        total_slots_per_day_grade = counts_per_day_grade.values.max || 0
        total_days_with_slots_grade = counts_per_day_grade.keys.size
        slots_per_class_grade = counts_per_day_grade.values.sum

        Rails.logger.debug("[generate_all] session=#{session} grade=#{grade} total_timeblocks=#{time_blocks_scope.count} used_for_grade=#{used_time_block_ids_for_grade.size} free_counts=#{counts_per_day_grade.inspect} total_days_with_slots=#{total_days_with_slots_grade} slots_per_class_grade=#{slots_per_class_grade}")

        if slots_per_class_grade == 0
          problems << "Kelas #{grade} tidak memiliki slot pelajaran yang tersedia (semua jam sudah terpakai untuk kegiatan)."
          next
        end

        # jumlah jam yang dibutuhkan tiap kelas di grade ini
        needed_sessions_per_class = SubjectGrade.joins(:subject)
                                                .where(grade: grade)
                                                .where('subject_grades.weekly_sessions > 0')
                                                .where(subjects: { is_active: true })
                                                .sum(:weekly_sessions).to_i

        if needed_sessions_per_class > slots_per_class_grade
          problems << "Kelas #{grade} membutuhkan #{needed_sessions_per_class} pertemuan, tetapi hanya tersedia #{slots_per_class_grade} slot. Jadwal tidak dapat dipenuhi."
        elsif needed_sessions_per_class < slots_per_class_grade
          problems << "Kelas #{grade} hanya membutuhkan #{needed_sessions_per_class} pertemuan, tetapi tersedia #{slots_per_class_grade} slot. Akan ada jam kosong dijadwal."
        end

        # =========================
        # Pengecekan kapasitas guru per mapel (lama)
        # =========================
        active_subjects.each do |subject|
          sg = subject.subject_grades.find_by(grade: grade)
          next unless sg && sg.weekly_sessions.to_i > 0

          class_count_in_session = class_rooms.size
          need_for_grade_and_subject = sg.weekly_sessions.to_i * class_count_in_session

          teachers_for_subject_count = subject.teachers.select { |t| t.cuti == "false" && t.is_active }.size

          if teachers_for_subject_count == 0 && need_for_grade_and_subject > 0
            problems << "Mapel #{subject.name} tidak memiliki guru aktif"
            next
          end

          slots_per_day = total_slots_per_day_grade
          days = total_days_with_slots_grade
          capacity_for_subject_in_grade = teachers_for_subject_count * slots_per_day * days

          # if need_for_grade_and_subject > capacity_for_subject_in_grade
          #   problems << "Mata pelajaran #{subject.name} untuk kelas #{grade} hanya memiliki #{teachers_for_subject_count} guru aktif dan membutuhkan #{need_for_grade_and_subject} pertemuan, tetapi hanya tersedia #{capacity_for_subject_in_grade} slot pertemuan."
          # end
        end

        # =========================
        # 🔹 Tambahan: Cek konsistensi guru per mapel per kelas 🔹
        # =========================
        active_subjects.each do |subject|
          sg = subject.subject_grades.find_by(grade: grade)
          next unless sg && sg.weekly_sessions.to_i > 0

          weekly_sessions = sg.weekly_sessions.to_i
          class_count = class_rooms.size
          teachers_for_subject = subject.teachers.select { |t| t.cuti == "false" && t.is_active }
          teacher_count = teachers_for_subject.size

          next if teacher_count == 0 # sudah dilaporkan di cek lama

          # Minimal slot yang dibutuhkan untuk mapel ini dengan konsistensi guru
          min_required_slots = weekly_sessions * ((class_count.to_f / teacher_count).ceil)

          # if slots_per_class_grade < min_required_slots
          #   problems << "Mata pelajaran #{subject.name} untuk kelas #{grade} memiliki #{teacher_count} guru aktif, sehingga membutuhkan minimal #{min_required_slots} slot pertemuan, tetapi hanya tersedia #{slots_per_class_grade} slot."
          # end
        end

        # =========================
        # 🔹 Tambahan: Cek akumulasi beban per guru lintas mapel 🔹
        # =========================
        active_teachers.each do |teacher|
          # cari semua subject yang diajar guru ini untuk grade tsb
          subjects_for_teacher = active_subjects.select { |subj| subj.teachers.include?(teacher) }

          total_needed_for_teacher = 0
          detail_info = []

          subjects_for_teacher.each do |subject|
            sg = subject.subject_grades.find_by(grade: grade)
            next unless sg && sg.weekly_sessions.to_i > 0

            weekly_sessions = sg.weekly_sessions.to_i
            class_count = class_rooms.size

            # guru ini akan konsisten per kelas
            # hitung berapa kelas yg bisa di-cover oleh guru ini
            teacher_count = subject.teachers.select { |t| t.cuti == "false" && t.is_active }.size
            next if teacher_count == 0

            # alokasi untuk guru ini kira2 (pembagian rata antar guru mapel)
            allocated_classes = (class_count.to_f / teacher_count).ceil
            need_for_teacher = weekly_sessions * allocated_classes

            total_needed_for_teacher += need_for_teacher
            detail_info << "#{subject.name}=#{need_for_teacher}"
          end

          # kapasitas maksimum = jumlah slot tersedia per grade
          if total_needed_for_teacher > slots_per_class_grade
            problems << "#{teacher.nama.downcase.titleize} di kelas #{grade} membutuhkan #{total_needed_for_teacher} slot (#{detail_info.join(', ')}), tetapi hanya tersedia #{slots_per_class_grade} slot."
          end
        end


        
      end
    end

    problems.uniq!
    if problems.any?
      flash[:danger] = "Jadwal tidak bisa digenerate karena masalah berikut:<br>- #{problems.join('<br>- ')}"
      redirect_to schedules_path and return
    end

    # =========================
    # Lanjut generate kalau feasible
    # =========================
    active_sessions.each do |session|
      if session == "siang"
        morning_drafts = ScheduleDraft.where(class_room: ClassRoom.where(session: "pagi"))
        morning_drafts.each do |entry|
          teacher_class_history[entry.teacher_id] << entry.class_room_id
        end
      end

      generator = if session == "siang"
                    ScheduleGenerator.new(session: session, teacher_class_history: teacher_class_history)
                  else
                    ScheduleGenerator.new(session: session)
                  end

      result = generator.run

      if result.blank?
        failed_sessions << session
        next
      end

      ScheduleDraft.where(class_room: ClassRoom.where(session: session)).delete_all

      result.each do |gene|
        ScheduleDraft.create!(
          class_room_id: gene[:class_room_id],
          subject_id:    gene[:subject_id],
          teacher_id:    gene[:teacher_id],
          time_block_id: gene[:time_block_id],
          day:           gene[:day],
          week:          gene[:week],
          locked:        false,
          status:        "draft"
        )
      end

      respond_to do |format|
        format.turbo_stream
      end
    end

    if failed_sessions.any?
      redirect_to preview_schedules_path
    else
      flash[:success] = "Jadwal mata pelajaran berhasil dibuat"
      redirect_to preview_schedules_path, notice: "Jadwal sesi berhasil digenerate!"
    end
  end



  def export_excel
    @batch = ScheduleBatch.find(params[:id])
    @schedules = @batch.schedules
                      .where(status: "final")
                      .order(:class_room_name, :day_name, :time_text)
                      .group_by(&:class_room_name)

    @days = %w[Senin Selasa Rabu Kamis Jumat Sabtu]
    @sorted_class_rooms = ClassRoom.order(:name)
    
    respond_to do |format|
      format.xlsx {
        response.headers['Content-Disposition'] = 'attachment; filename="jadwal_pelajaran.xlsx"'
      }
    end
  end


  def preview
    # Ambil hanya aktivitas yang aktif dan time_blocks aktif
    @activities = Activity.includes(time_blocks: :day).where(is_active: true)

    # Ambil draft yang statusnya 'draft' dan kelas aktif
    active_class_ids = ClassRoom.where(is_active: true).pluck(:id)
    @drafts = ScheduleDraft.includes(:class_room, :subject, :teacher, :time_block)
                          .where(class_room_id: active_class_ids, status: 'draft')
                          .order(:class_room_id, :day, 'time_blocks.order')
                          .group_by(&:class_room_id)

    # Ambil hari aktif saja
    @days = Day.where(is_active: true).order(:id)

    # Ambil kelas aktif
    @class_rooms = ClassRoom.where(is_active: true).order(:name)
    @sorted_class_rooms = @class_rooms.sort_by(&:name)

    # Ambil time_blocks berdasarkan sesi, filter yang aktif saja
    @time_blocks_by_session = {
      'pagi' => TimeBlock.where(session: 'pagi', is_active: true).order(:day_id, :order),
      'siang' => TimeBlock.where(session: 'siang', is_active: true).order(:day_id, :order)
    }
  end


  def new
    @scheduleBatch = ScheduleBatch.new

    respond_to do |format|
        format.turbo_stream do
            render turbo_stream: turbo_stream.update(
                "new",
                partial: "new",
                locals: { scheduleBatch: @scheduleBatch }
            )
        end
    end
  end

  def save_generated
    Schedule.where(status: "generated").delete_all

    batch = ScheduleBatch.new(schedule_batch_params)

    ActiveRecord::Base.transaction do
      batch.save! # <-- Akan trigger before_create juga

      # Simpan jadwal dari draft
      ScheduleDraft
        .includes(:teacher, :subject, class_room: [], time_block: [:activities, :day])
        .find_each do |draft|

        # Skip jika class_room tidak aktif
        next unless draft.class_room&.is_active

        classroom_grade = draft.class_room&.grade

        # Hanya ambil activity yang aktif dan time_block-nya juga aktif, serta grade cocok
        valid_activities = draft.time_block.activities.select do |activity|
          activity.is_active && activity.time_block.is_active &&
          (activity.grade.nil? || activity.grade == classroom_grade)
        end

        if valid_activities.blank?
          Schedule.create!(
            schedule_batch:   batch,
            week:             draft.week,
            locked:           false,
            status:           "generated",
            class_room_name:  draft.class_room&.name,
            subject_name:     draft.subject&.name,
            subject_code:     draft.subject&.code,
            teacher_name:     draft.teacher&.nama,
            teacher_code:     draft.teacher&.teacher_code,
            day_name:         draft.time_block&.day&.name,
            time_text:        draft.time_block&.time,
            session:          draft.time_block&.session,
            activity_names:   nil
          )
        else
          valid_activities.each do |activity|
            Schedule.create!(
              schedule_batch:   batch,
              week:             draft.week,
              locked:           false,
              status:           "generated",
              class_room_name:  draft.class_room&.name,
              subject_name:     draft.subject&.name,
              subject_code:     draft.subject&.code,
              teacher_name:     draft.teacher&.nama,
              teacher_code:     draft.teacher&.teacher_code,
              day_name:         draft.time_block&.day&.name,
              time_text:        draft.time_block&.time,
              session:          draft.time_block&.session,
              activity_names:   activity.name
            )
          end
        end
      end

      # Tambahan untuk activity-based schedule
      ClassRoom.where(is_active: true).find_each do |class_room| # Hanya class aktif
        grade = class_room.grade

        TimeBlock.includes(:day, :activities).find_each do |tb|
          next unless tb.is_active # skip jika time_block tidak aktif

          valid_activities = tb.activities.select do |activity|
            activity.is_active &&
            (activity.grade.blank? || activity.grade == grade) &&
            (activity.day.blank? || activity.day == tb.day&.name)
          end

          valid_activities.each do |activity|
            next if Schedule.exists?(
              schedule_batch:   batch,
              class_room_name:  class_room.name,
              time_text:        tb.time,
              day_name:         tb.day.name,
              activity_names:   activity.name
            )

            Schedule.create!(
              schedule_batch:   batch,
              week:             1,
              locked:           false,
              status:           "generated",
              class_room_name:  class_room.name,
              subject_name:     nil,
              subject_code:     nil,
              teacher_name:     nil,
              teacher_code:     nil,
              day_name:         tb.day.name,
              time_text:        tb.time,
              session:          tb.session,
              activity_names:   activity.name
            )
          end
        end
      end

      ScheduleDraft.delete_all
    end

    flash[:success] = "Jadwal berhasil diajukan!"
    redirect_to schedules_path

    rescue ActiveRecord::RecordInvalid => e
      @bat = batch
      # @activities = Activity.includes(time_blocks: :day)

      # @drafts = ScheduleDraft.includes(:class_room, :subject, :teacher, :time_block)
      #                       .order(:class_room_id, :day, 'time_blocks.order')
      #                       .group_by(&:class_room_id)

      # @days = Day.order(:id).pluck(:name)
      # @class_rooms = ClassRoom.order(:name)
      # @sorted_class_rooms = @class_rooms.sort_by(&:name)

      # @time_blocks_by_session = {
      #   'pagi' => TimeBlock.where(session: 'pagi').order(:day_id, :order),
      #   'siang' => TimeBlock.where(session: 'siang').order(:day_id, :order)
      # }
      # Ambil hanya aktivitas yang aktif dan time_blocks aktif
      @activities = Activity.includes(time_blocks: :day).where(is_active: true)

      # Ambil draft yang statusnya 'draft' dan kelas aktif
      active_class_ids = ClassRoom.where(is_active: true).pluck(:id)
      @drafts = ScheduleDraft.includes(:class_room, :subject, :teacher, :time_block)
                            .where(class_room_id: active_class_ids, status: 'draft')
                            .order(:class_room_id, :day, 'time_blocks.order')
                            .group_by(&:class_room_id)

      # Ambil hari aktif saja
      @days = Day.where(is_active: true).order(:id)

      # Ambil kelas aktif
      @class_rooms = ClassRoom.where(is_active: true).order(:name)
      @sorted_class_rooms = @class_rooms.sort_by(&:name)

      # Ambil time_blocks berdasarkan sesi, filter yang aktif saja
      @time_blocks_by_session = {
        'pagi' => TimeBlock.where(session: 'pagi', is_active: true).order(:day_id, :order),
        'siang' => TimeBlock.where(session: 'siang', is_active: true).order(:day_id, :order)
      }

      flash.now[:danger] = "Semester dan tahun tidak boleh kosong!"
      render :preview, status: :unprocessable_entity
    return
  end

  def finalize
    batch = ScheduleBatch.find(params[:id])

    batch.schedules.where(status: "generated").update_all(status: "final")

    flash[:success] = "Jadwal berhasil disahkan!"
    redirect_to schedules_path
  end

  # Tampilkan detail jadwal dari suatu batch
  def show
    @batch = ScheduleBatch.find(params[:id])

    # Ambil semua jadwal generated
    @schedules = @batch.schedules
                      .where(status: "final")
                      .order(:class_room_name, :day_name, :time_text)
                      .group_by(&:class_room_name)

    # Ambil grade dari nama kelas
    @grades = @schedules.keys.map { |name| [name, name[/\d+/]&.to_i] }.to_h

    # Ambil hari berdasarkan jadwal generated dan berurut
    ordered_days = %w[Senin Selasa Rabu Kamis Jumat Sabtu]
    @days = ordered_days & @schedules.values.flatten.map(&:day_name).uniq

    # Ambil time blocks dari time_text jadwal generated, dikelompokkan per [day_name, session]
    @all_time_blocks = @schedules.values.flatten
                                .group_by { |s| [s.day_name, s.session] }
                                .transform_values { |arr| arr.map { |s| OpenStruct.new(time: s.time_text) }.uniq }

    # Ambil guru-mapel dari jadwal generated
    @guru_mapel_pairs = @schedules.values.flatten
                          .select { |s| s.teacher_name.present? && s.subject_name.present? }
                          .map { |s| [s.teacher_code, s.teacher_name, s.subject_name] }
                          .uniq
                          .sort_by { |code, name, subject| [code, subject] }
  end

  def preview_generated
    @batch = ScheduleBatch.find(params[:id])

    # Ambil semua jadwal generated
    @schedules = @batch.schedules
                      .where(status: "generated")
                      .order(:class_room_name, :day_name, :time_text)
                      .group_by(&:class_room_name)

    # Ambil grade dari nama kelas
    @grades = @schedules.keys.map { |name| [name, name[/\d+/]&.to_i] }.to_h

    # Ambil hari berdasarkan jadwal generated dan berurut
    ordered_days = %w[Senin Selasa Rabu Kamis Jumat Sabtu]
    @days = ordered_days & @schedules.values.flatten.map(&:day_name).uniq

    # Ambil time blocks dari time_text jadwal generated, dikelompokkan per [day_name, session]
    @all_time_blocks = @schedules.values.flatten
                                .group_by { |s| [s.day_name, s.session] }
                                .transform_values { |arr| arr.map { |s| OpenStruct.new(time: s.time_text) }.uniq }

    # Ambil guru-mapel dari jadwal generated
    @guru_mapel_pairs = @schedules.values.flatten
                          .select { |s| s.teacher_name.present? && s.subject_name.present? }
                          .map { |s| [s.teacher_code, s.teacher_name, s.subject_name] }
                          .uniq
                          .sort_by { |code, name, subject| [code, subject] }
  end


  def destroy
    @batch = ScheduleBatch.find(params[:id])
    @batch.destroy

    flash[:success] = "Data berhasil dihapus!"
    redirect_to schedules_path
  end

  def destroy_draft
    ScheduleDraft.delete_all

    flash[:success] = "Data berhasil dihapus!"
    redirect_to schedules_path
  end

  def new_teach
    schedule_batch = ScheduleBatch.find(params[:schedule_batch_id])

    # guru terjadwal diambil langsung dari schedule
    @scheduled_teachers = schedule_batch.schedules
                                        .where.not(teacher_code: nil, teacher_name: nil)
                                        .select(:teacher_code, :teacher_name)
                                        .distinct
                                        .order(:teacher_name)
                                        .map { |s| [s.teacher_code, s.teacher_name] }

    # semua teacher_code yang sudah ada di jadwal
    scheduled_codes = @scheduled_teachers.map(&:first)

    # guru pengganti: semua teacher yang tidak ada di jadwal batch ini
    @replacement_teachers = if scheduled_codes.any?
                              Teacher.where.not(teacher_code: scheduled_codes)
                                    .select(:id, :teacher_code, :nama)
                                    .distinct
                                    .order(:nama)
                            else
                              Teacher.select(:id, :teacher_code, :nama)
                                    .distinct
                                    .order(:nama)
                            end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "new_teach",
          partial: "new_teach",
          locals: { 
            scheduleBatch: schedule_batch, 
            scheduled_teachers: @scheduled_teachers, 
            replacement_teachers: @replacement_teachers 
          }
        )
      end
    end
  end

  def replace_teacher
    old_code = params[:old_teacher_code]
    new_code = params[:new_teacher_code]
    batch_id = params[:schedule_batch_id]

    schedule_batch = ScheduleBatch.find(batch_id)
    new_teacher = Teacher.find_by(teacher_code: new_code)

    if new_teacher.nil?
      flash[:danger] = "Gagal, guru pengganti tidak ditemukan!"
      redirect_to schedule_path(batch_id)
      return
    end

    # update semua jadwal dalam batch tertentu yang pakai old_code
    schedule_batch.schedules.where(teacher_code: old_code).update_all(
      teacher_code: new_teacher.teacher_code,
      teacher_name: new_teacher.nama
    )

    old_teacher = Teacher.find_by(teacher_code: old_code)
    
    if old_teacher.present?
      old_teacher.destroy
    end

    flash[:success] = "Guru berhasil diganti!"
    redirect_to schedule_path(batch_id)
  end




  private
  def generate_by_session(session)
    generator = ScheduleGenerator.new(session: session)
    result = generator.run

    if result.blank?
      redirect_to schedules_path, alert: "Gagal generate jadwal sesi #{session}. Coba lagi atau periksa konfigurasi."
      return
    end

    ScheduleDraft.where(class_room: ClassRoom.where(session: session)).delete_all

    result.each do |gene|
      ScheduleDraft.create!(gene.merge(status: "draft", locked: false))
    end

    redirect_to schedules_path, notice: "Jadwal sesi #{session} berhasil digenerate!"
  end

  def schedule_batch_params
    params.require(:schedule_batch).permit(:name, :year)
  end
end
