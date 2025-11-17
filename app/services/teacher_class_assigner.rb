class TeacherClassAssigner
  def initialize(subjects:, class_rooms:)
    # ✅ Ambil hanya subject aktif
    @subjects = subjects.where(is_active: true) if subjects.respond_to?(:where)
    @subjects ||= subjects.select { |s| s.respond_to?(:is_active) ? s.is_active : true }

    @class_rooms = class_rooms
  end

  # Output: { [subject_id, class_room_id] => teacher_id }
  def assign
    assignment = {}
    TeacherClassAssignment.delete_all

    @subjects.each do |subject|
      relevant_teachers = subject.teachers
                                .where(is_active: true)
                                .reject { |t| t.cuti == "true" }
                                .shuffle
      next if relevant_teachers.empty?

      class_rooms_for_subject = @class_rooms.select do |class_room|
        grade = class_room.name[/\d+/].to_i
        subject.subject_grades.any? { |sg| sg.grade == grade }
      end
      next if class_rooms_for_subject.empty?

      shuffled_rooms = class_rooms_for_subject.shuffle
      teacher_cycle = relevant_teachers.cycle

      shuffled_rooms.each do |class_room|
        teacher = teacher_cycle.next
        assignment[[subject.id, class_room.id]] = teacher.id

        TeacherClassAssignment.find_or_create_by!(
          teacher_id: teacher.id,
          class_room_id: class_room.id
        )
      end
    end

    @teacher_class_map = assignment
    validate_teacher_assignments
    assignment
  end


  def validate_teacher_assignments
    expected_keys = @subjects.flat_map do |subject|
      @class_rooms.map do |class_room|
        grade = class_room.name[/\d+/].to_i
        if subject.subject_grades.exists?(grade: grade)
          [subject.id, class_room.id]
        end
      end.compact
    end

    missing = expected_keys - @teacher_class_map.keys
    if missing.any?
      puts "🚨 Ada #{missing.size} kombinasi mata pelajaran dan kelas yang tidak dapat guru!"
      missing.each do |subj_id, cls_id|
        subj = Subject.find(subj_id)
        cls = ClassRoom.find(cls_id)
        puts "❌ #{subj.name} di #{cls.name} belum dapat guru!"
      end
    else
      puts "✅ Semua kelas-mata pelajaran berhasil dapat guru."
    end
  end
end
