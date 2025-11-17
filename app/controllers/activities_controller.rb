class ActivitiesController < ApplicationController
    before_action :authenticate_user!
    before_action -> { require_role("kepala_sekolah", "waka_kurikulum") }

    def index
        load_activities

        render layout: "dash_layout"
    end

    def new
        @activity = Activity.new
        @time = TimeBlock.includes(:day).order(:order)

        respond_to do |format|
            format.turbo_stream do
            render turbo_stream: turbo_stream.update(
                "new",
                partial: "new",
                locals: { activity: @activity, time: @time }
            )
            end

            format.html do
            render :new, locals: { activity: @activity, time: @time }
            end
        end
    end

    def  create
        @activity = Activity.new(activity_params)

        if @activity.save
            flash[:success] = "Kegiatan berhasil ditambahkan!"
            update_time_blocks
            redirect_to activities_path
        else
            load_activities
            @time = TimeBlock.includes(:day).order(:order)

            @show_new_modal = true # Flag untuk menampilkan modal
            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end
    
    def edit
        @activity = Activity.find(params[:id])
        @time = TimeBlock.includes(:day).order(:order)

        respond_to do |format|
            format.turbo_stream do
            render turbo_stream: turbo_stream.update(
                "edit",
                partial: "edit",
                locals: { activity: @activity, time: @time }
            )
            end

            format.html do
            render :new, locals: { activity: @activity, time: @time }
            end
        end
    end

    def  update
        @activity = Activity.find(params[:id])

        if @activity.update(activity_params)
            flash[:success] = "Kegiatan berhasil diedit!"
            update_time_blocks
            redirect_to activities_path
        else
            load_activities
            @time = TimeBlock.includes(:day).order(:order)
            
            @show_new_modal = true # Flag untuk menampilkan modal
            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end

    def destroy
        if ScheduleDraft.first
            flash.now[:danger] = "Data tidak bisa dihapus, ada draft jadwal yang aktif"
            load_activities
            render :index, layout: "dash_layout", status: :unprocessable_entity
            return
        end
        @activity = Activity.find(params[:id])
        @activity.destroy

        flash[:success] = "Kegiatan berhasil dihapus!"
        redirect_to activities_path
    end
    
    def time_blocks_for_day
        day = Day.find_by(name: params[:day])
        @time_blocks = day ? day.time_blocks.order(:order) : []

        respond_to do |format|
            format.turbo_stream
        end
    end

    def activate_all
        Activity.update_all(is_active: true)
        flash[:success] = "Semua kegiatan berhasil diaktifkan!"
        redirect_to activities_path
    end

    def deactivate_all
        Activity.update_all(is_active: false)
        flash[:success] = "Semua kegiatan berhasil dinonaktifkan!"
        redirect_to activities_path
    end

    private
    def activity_params
        params.require(:activity).permit(:name, :day, :grade, :is_active, time_block_ids: [])
    end

    def update_time_blocks
        return unless params[:activity][:time_block_ids]

        time_block_ids = params[:activity][:time_block_ids].reject(&:blank?)
        time_block_ids.each do |tb_id|
        @activity.activity_slots.create!(time_block_id: tb_id)
        end
    end

    def load_activities
        # Preload agar tidak N+1
        @activities = Activity.includes(:time_blocks)

        # Group by grade, lalu by day
        @activities_grouped = @activities.group_by(&:grade).transform_values do |acts|
            acts.group_by(&:day)
        end
    end
end
