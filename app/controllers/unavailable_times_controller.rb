class UnavailableTimesController < ApplicationController
    def index
        @teachers = Teacher.includes(unavailable_times: { time_block: :day })
    end


    def new
        @unavailable_time = UnavailableTime.new
        @teachers = Teacher.order(:nama)
        @days = Day.all
        @time_blocks = TimeBlock.all.includes(:day)
        @selected_time_block_ids = []

        respond_to do |format|
            format.turbo_stream do
            render turbo_stream: turbo_stream.update(
                "new",
                partial: "unavailable_times/new",
                locals: {
                unavailable_time: @unavailable_time,
                teachers: @teachers,
                days: @days,
                time_blocks: @time_blocks,
                selected_time_block_ids: @selected_time_block_ids
                }
            )
            end
            format.html do
            render :new, locals: {
                unavailable_time: @unavailable_time,
                teachers: @teachers,
                days: @days,
                time_blocks: @time_blocks,
                selected_time_block_ids: @selected_time_block_ids
            }
            end
        end
    end


    def create
        teacher_id = params[:unavailable_time][:teacher_id]
        time_block_ids = params[:unavailable_time][:time_block_ids].reject(&:blank?)

        time_block_ids.each do |tb_id|
            UnavailableTime.find_or_create_by(teacher_id: teacher_id, time_block_id: tb_id)
        end
        flash[:success] = "Data berhasil ditambah!"
        redirect_to schedules_path
    end

    def edit
        teacher_id = params[:id] # id di sini adalah teacher_id
        @teacher = Teacher.find(teacher_id)
        @unavailable_time = UnavailableTime.new(teacher_id: teacher_id)
        @teachers = Teacher.order(:nama)
        @days = Day.all
        @time_blocks = TimeBlock.all.includes(:day)
        @selected_time_block_ids = @teacher.unavailable_times.pluck(:time_block_id)

        respond_to do |format|
            format.turbo_stream do
            render turbo_stream: turbo_stream.update(
                "edit",
                partial: "unavailable_times/edit",
                locals: {
                unavailable_time: @unavailable_time,
                teachers: @teachers,
                days: @days,
                time_blocks: @time_blocks,
                selected_time_block_ids: @selected_time_block_ids
                }
            )
            end
            format.html do
            render :edit, locals: {
                unavailable_time: @unavailable_time,
                teachers: @teachers,
                days: @days,
                time_blocks: @time_blocks,
                selected_time_block_ids: @selected_time_block_ids
            }
            end
        end
    end

    def update
        teacher_id = params[:id]
        time_block_ids = params[:unavailable_time][:time_block_ids].reject(&:blank?)

        # Hapus dulu semua yang lama
        UnavailableTime.where(teacher_id: teacher_id).delete_all

        # Buat ulang yang baru
        time_block_ids.each do |tb_id|
            UnavailableTime.create(teacher_id: teacher_id, time_block_id: tb_id)
        end

        flash[:success] = "Data berhasil diperbarui!"
        redirect_to schedules_path
    end

    def destroy
        teacher_id = params[:id]
        UnavailableTime.where(teacher_id: teacher_id).destroy_all

        flash[:success] = "Data berhasil dihapus!"
        redirect_to schedules_path
    end


end
