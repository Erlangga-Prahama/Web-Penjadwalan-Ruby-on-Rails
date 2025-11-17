class DaysController < ApplicationController
    before_action :authenticate_user!
    before_action -> { require_role("kepala_sekolah", "waka_kurikulum") }

    def index
        @days = Day.all.order(is_active: :desc, id: :asc)

        render layout: "dash_layout"
    end

    def new
        @day = Day.new

        respond_to do |format|
            format.turbo_stream do
                render turbo_stream: turbo_stream.update(
                    "new",
                    partial: "new",
                    locals: {   day: @day}
                )
            end
        end
    end

    def  create
        @day = Day.new(day_params)

        if @day.save
            flash[:success] = "Hari berhasil ditambahkan!"
            redirect_to days_path
        else
            @days = Day.all # Load data index
            @show_new_modal = true # Flag untuk menampilkan modal
            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end

    def edit
        @day = Day.find(params[:id])

        respond_to do |format|
            format.turbo_stream do
                render turbo_stream: turbo_stream.update(
                    "edit",
                    partial: "edit",
                    locals: { day: @day }
                )
            end
        end
    end

    def update
        @day = Day.find(params[:id])

        if @day.update(day_params)
            flash[:success] = "Hari berhasil diedit!"
            redirect_to days_path
        else
            @days = Day.all # Load data index
            @show_edit_modal = true
            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end

    def destroy
        @day = Day.find(params[:id])
        @day.destroy
        
        flash[:success] = "Hari berhasil dihapus!"
        redirect_to days_path
    end

    def activate_all
        # Aktifkan semua hari
        Day.update_all(is_active: true)

        # Aktifkan semua time_blocks sesuai day
        TimeBlock.update_all("is_active = TRUE")

        flash[:success] = "Semua hari dan time block berhasil diaktifkan!"
        redirect_to days_path
    end

    def deactivate_all
        # Nonaktifkan semua hari
        Day.update_all(is_active: false)

        # Nonaktifkan semua time_blocks sesuai day
        TimeBlock.update_all("is_active = FALSE")

        flash[:success] = "Semua hari dan time block berhasil dinonaktifkan!"
        redirect_to days_path
    end

    private
    def day_params
        params.require(:day).permit(:name, :is_active)
    end
end
