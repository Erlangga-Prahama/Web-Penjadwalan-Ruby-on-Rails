class TeachersController < ApplicationController
    before_action :authenticate_user!
    before_action -> { require_role("kepala_sekolah", "waka_kurikulum") }
    
    def index
        load_teachers

        render layout: "dash_layout"
    end

    def new
        @teacher = Teacher.new
        @subjects = Subject.order(:name)

        respond_to do |format|
            format.turbo_stream do
                render turbo_stream: turbo_stream.update(
                    "new",
                    partial: "new",
                    locals: { teacher: @teacher, subjects: @subjects }
                )
            end
        end
    end

    def  create
        @teacher = Teacher.new(teacher_params)

        if @teacher.save
            flash[:success] = "Guru berhasil ditambahkan!"
            redirect_to teachers_path
        else
            load_teachers
            @show_new_modal = true # Flag untuk menampilkan modal
            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end

    def edit
        @teacher = Teacher.find(params[:id])
        @subjects = Subject.order(:name)

        respond_to do |format|
            format.turbo_stream do
                render turbo_stream: turbo_stream.update(
                    "edit",
                    partial: "edit",
                    locals: { teacher: @teacher, subjects: @subjects }
                )
            end
        end
    end

    def  update
        @teacher = Teacher.find(params[:id])

        if @teacher.update(teacher_params)
            flash[:success] = "Guru berhasil diedit!"
            redirect_to teachers_path
        else
            load_teachers
            @show_edit_modal = true # Flag untuk menampilkan modal
            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end

    def destroy
        if ScheduleDraft.first
            flash.now[:danger] = "Guru tidak bisa dihapus, ada draft jadwal yang aktif"
            load_teachers
            render :index, layout: "dash_layout", status: :unprocessable_entity
            return
        end
        @teacher = Teacher.find(params[:id])
        @teacher.destroy

        flash[:success] = "Data berhasil dihapus!"
        redirect_to teachers_path
    end

    def show
        @teacher = Teacher.find(params[:id])

        render layout: "dash_layout"
    end

    def activate_all
        Teacher.update_all(is_active: true)
        flash[:success] = "Semua guru berhasil diaktifkan!"
        redirect_to teachers_path
    end

    def deactivate_all
        Teacher.update_all(is_active: false)
        flash[:success] = "Semua guru berhasil dinonaktifkan!"
        redirect_to teachers_path
    end

    def by_subject
        teacher = Teacher.find_by(teacher_code: params[:teacher_code])
        subject_codes = teacher.subjects.pluck(:code)

        teachers = Teacher.joins(:subjects)
                            .where(subjects: { code: subject_codes })
                            .where.not(id: teacher.id)
                            .distinct

        render json: teachers.select(:id, :nama, :teacher_code)
    end
    
    private
    def teacher_params
        params.require(:teacher).permit(
            :nama, :NIK, :NIP, :tempat_lahir, :tanggal_lahir, :agama, :jk, :alamat, :jenjang, :prodi, :tahun_lulus, :cuti, :is_active, :phone,
            subject_ids: []
        )
    end

    def load_teachers
        @q = params[:q]
        @teachers = if @q.present?
                        Teacher.joins(:subjects).where(
                        "teachers.nama ILIKE :q OR teachers.teacher_code ILIKE :q OR subjects.name ILIKE :q",
                        q: "%#{@q}%"
                        ).distinct
                    else
                        Teacher.includes(:subjects)
                    end

        @teachers = @teachers
            .order(is_active: :desc) # aktif duluan
            .order(:teacher_code)    # lalu urut kode
            .page(params[:page]).per(8)
    end


end
