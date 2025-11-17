class TimeBlocksController < ApplicationController
    before_action :authenticate_user!
    before_action -> { require_role("kepala_sekolah", "waka_kurikulum") }
    
    def index
        load_times

        render layout: "dash_layout"
    end

    def new
        @timeBlock = TimeBlock.new
        @days = Day.all

        respond_to do |format|
            format.turbo_stream do
                render turbo_stream: turbo_stream.update(
                    "new",
                    partial: "new",
                    locals: { time: @timeBlock }
                )
            end
        end
    end

    def create
        @timeBlock = TimeBlock.new(time_block_params)

        if @timeBlock.save
            flash[:success] = "Jam Pelajaran berhasil dibuat!"
            redirect_to time_blocks_path
        else
            @days = Day.all
            load_times

            @show_new_modal = true # Flag untuk menampilkan modal
            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end

    def edit
        @timeBlock = TimeBlock.find(params[:id])
        @days = Day.order(:id)

        respond_to do |format|
            format.turbo_stream do
                render turbo_stream: turbo_stream.replace(
                    "edit-modal",
                    partial: "edit_modal",
                    locals: { time: @timeBlock }
                )
            end
        end
    end

    def update
        @timeBlock = TimeBlock.find(params[:id])

        if @timeBlock.update(time_block_params)
            flash[:success] = "Jam Pelajaran berhasil diedit!"
            redirect_to time_blocks_path
        else
            @days = Day.all
            load_times

            @show_edit_modal = true # Flag untuk menampilkan modal
            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end

    def destroy
        if ScheduleDraft.first
            flash.now[:danger] = "Data tidak bisa dihapus, ada draft jadwal yang aktif"
            load_times
            render :index, layout: "dash_layout", status: :unprocessable_entity
            return
        end
        @time = TimeBlock.find(params[:id])
        @time.destroy

        flash[:success] = "Data berhasil dihapus!"
        redirect_to time_blocks_path
    end

    def activate_all
        TimeBlock.update_all(is_active: true)
        flash[:success] = "Semua jam pelajaran berhasil diaktifkan!"
        redirect_to time_blocks_path
    end

    def deactivate_all
        TimeBlock.update_all(is_active: false)
        flash[:success] = "Semua jam pelajaran berhasil dinonaktifkan!"
        redirect_to time_blocks_path
    end

    private
    def time_block_params
        params.require(:time_block).permit(:order, :time, :day_id, :session, :is_active)
    end

    def load_times
        @times = TimeBlock
                    .includes(:day)
                    .order(session: :asc, day_id: :asc, order: :asc)

        # Group dulu per session, lalu per day
        @times_grouped = @times.group_by(&:session).transform_values do |blocks|
            blocks.group_by(&:day)
        end
    end
end
