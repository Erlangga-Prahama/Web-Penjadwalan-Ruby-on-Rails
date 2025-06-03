class ClassRoomsController < ApplicationController
  def index
    @classRooms = ClassRoom.all
    @classRoom = ClassRoom.new

    render layout: "dash_layout"
  end

  def create
    @classRoom = ClassRoom.new(class_room_params)

    if @classRoom.save
        flash[:notice] = "Kelas berhasil dibuat!"
        redirect_to class_rooms_path
    else
        @classRooms = ClassRoom.all # Load data index
        render :index, status: :unprocessable_entity
    end
  end

  def edit
    @classRoom = ClassRoom.find(params[:id])
    respond_to do |format|
        format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
                "edit-modal",
                partial: "edit",
                locals: { class_room: @classRoom }
            )
        end
    end
  end

  def update
    @classRoom = ClassRoom.find(params[:id])

    if @classRoom.update(class_room_params)
        redirect_to class_rooms_path, 
        notice: "Kelas berhasil diperbarui!"
    else
        render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @classRoom = ClassRoom.find(params[:id])
    @classRoom.destroy

    redirect_to class_rooms_path
  end

  private
  def class_room_params
      params.require(:class_room).permit(:name)
  end
end
