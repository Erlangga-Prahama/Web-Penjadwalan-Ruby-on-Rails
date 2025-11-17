class ClassRoomsController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role("kepala_sekolah", "waka_kurikulum") }
  
  def index
    @classRooms_grouped = ClassRoom.all
      .sort_by { |c| [c.name.split('.').first.to_i, c.name.split('.').last] }  # Urutkan angka & huruf
      .group_by { |c| c.name.split('.').first }  # Group by tingkat: "7", "8", dst.

    render layout: "dash_layout"
  end

  def new
    @classRoom = ClassRoom.new

    respond_to do |format|
        format.turbo_stream do
            render turbo_stream: turbo_stream.update(
                "new",
                partial: "new",
                locals: { class_room: @classRoom }
            )
        end
    end
    
  end

  def create
    @classRoom = ClassRoom.new(class_room_params)

    if @classRoom.save
        flash[:success] = "Kelas berhasil dibuat!"
        redirect_to class_rooms_path
    else
      @classRooms_grouped = ClassRoom.all
        .sort_by { |c| [c.name.split('.').first.to_i, c.name.split('.').last] }  # Urutkan angka & huruf
        .group_by { |c| c.name.split('.').first }  # Group by tingkat: "7", "8", dst.

      @show_new_modal = true
      render :index, layout: "dash_layout", status: :unprocessable_entity
    end
  end

  def edit
    @classRoom = ClassRoom.find(params[:id])
    respond_to do |format|
        format.turbo_stream do
            render turbo_stream: turbo_stream.update(
                "edit-modal",
                partial: "edit_modal",
                locals: { class_room: @classRoom }
            )
        end
    end
  end

  def update
    @classRoom = ClassRoom.find(params[:id])

    if @classRoom.update(class_room_params)
      flash[:success] = "Kelas berhasil diedit!"
      redirect_to class_rooms_path
    else
      @classRooms_grouped = ClassRoom.all
        .sort_by { |c| [c.name.split('.').first.to_i, c.name.split('.').last] }  # Urutkan angka & huruf
        .group_by { |c| c.name.split('.').first }  # Group by tingkat: "7", "8", dst.
      @show_edit_modal = true
      
      render :index, layout: "dash_layout", status: :unprocessable_entity
    end
  end

  def destroy
    if ScheduleDraft.first
      flash.now[:danger] = "Data tidak bisa dihapus, ada draft jadwal yang aktif"
      @classRooms_grouped = ClassRoom.all
        .sort_by { |c| [c.name.split('.').first.to_i, c.name.split('.').last] }  # Urutkan angka & huruf
        .group_by { |c| c.name.split('.').first }  # Group by tingkat: "7", "8", dst.

      render :index, layout: "dash_layout", status: :unprocessable_entity
      return
    end
    @classRoom = ClassRoom.find(params[:id])
    @classRoom.destroy

    flash[:success] = "Kelas berhasil dihapus!"
    redirect_to class_rooms_path
  end

  def activate_all
    ClassRoom.update_all(is_active: true)
    flash[:success] = "Semua kelas berhasil diaktifkan!"
    redirect_to class_rooms_path
  end

  def deactivate_all
    ClassRoom.update_all(is_active: false)
    flash[:success] = "Semua kelas berhasil dinonaktifkan!"
    redirect_to class_rooms_path
  end

  private
  def class_room_params
      params.require(:class_room).permit(:name, :session, :is_active)
  end
end
