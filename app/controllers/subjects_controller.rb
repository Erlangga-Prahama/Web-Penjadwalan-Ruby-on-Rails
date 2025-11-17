class SubjectsController < ApplicationController
    before_action :authenticate_user!
    before_action -> { require_role("kepala_sekolah", "waka_kurikulum") }
    
    def index
        load_subjects
        render layout: "dash_layout"
    end


    def new
        @subject = Subject.new
                    [7, 8, 9].each { |grade| @subject.subject_grades.build(grade: grade) }

        respond_to do |format|
            format.turbo_stream do
                render turbo_stream: turbo_stream.update(
                    "new",
                    partial: "new",
                    locals: { subject: @subject }
                )
            end
        end
    end

    def create
        @subject = Subject.new(subject_params)

        if @subject.save
            flash[:success] = "Mata Pelajaran berhasil ditambahkan!"
            redirect_to subjects_path
        else
            load_subjects

            [7, 8, 9].each do |grade|
                @subject.subject_grades.build(grade: grade) unless @subject.subject_grades.find { |g| g.grade == grade }
            end
            @show_new_modal = true
            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end


    def edit
        @subject = Subject.find(params[:id])

        respond_to do |format|
            format.turbo_stream do
                render turbo_stream: turbo_stream.update(
                    "edit",
                    partial: "edit_modal",
                    locals: { subject: @subject }
                )
            end
        end
    end

    def update
        @subject = Subject.find(params[:id])

        if @subject.update(subject_params)
            flash[:success] = "Mata Pelajaran berhasil diedit!"
            redirect_to subjects_path
        else
            load_subjects
            @show_edit_modal = true
            @subject.subject_grades.build if @subject.subject_grades.empty?

            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end
    
    def destroy
        if ScheduleDraft.first
            flash.now[:danger] = "Data tidak bisa dihapus, ada draft jadwal yang aktif"
            load_subjects
            render :index, layout: "dash_layout", status: :unprocessable_entity
            return
        end
        @subject = Subject.find(params[:id])
        @subject.destroy
        
        flash[:success] = "Mata Pelajaran berhasil dihapus!"
        redirect_to subjects_path
    end

    def activate_all
        Subject.update_all(is_active: true)
        Teacher.where(
            id: TeachingAssignment.select(:teacher_id)
                .where(subject_id: Subject.where(is_active: true).select(:id))
        ).update_all(is_active: true)
        flash[:success] = "Semua mata pelajaran berhasil diaktifkan!"
        redirect_to subjects_path
    end

    def deactivate_all
        # Nonaktifkan semua subject
        Subject.update_all(is_active: false)

        # Nonaktifkan semua guru yang mengajar subject nonaktif
        Teacher.where(
            id: TeachingAssignment.select(:teacher_id)
                .where(subject_id: Subject.where(is_active: false).select(:id))
        ).update_all(is_active: false)
        flash[:success] = "Semua mata pelajaran berhasil dinonaktifkan!"
        redirect_to subjects_path
    end

    private
    def subject_params
        params.require(:subject).permit(
            :name,
            :code,
            :is_active,
            subject_grades_attributes: [:id, :grade, :weekly_sessions, :_destroy]
        )
    end

    def load_subjects
        @q = params[:q]
        @subjects = if @q.present?
                        Subject.where("name ILIKE :q OR code ILIKE :q", q: "%#{@q}%")
                    else
                        Subject.all
                    end
        @subjects = @subjects.includes(:subject_grades).order(is_active: :desc).order(:name).page(params[:page]).per(8)
    end
end
