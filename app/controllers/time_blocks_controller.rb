class TimeBlocksController < ApplicationController
    def index
        @times = TimeBlock.all
        @time = TimeBlock.new
        @editTime = TimeBlock.find(params[:id]) if params[:id].present?

        render layout: "dash_layout"
    end

    def create
        @time = TimeBlock.new(time_block_params)

        if @time.save
            flash[:notice] = "time berhasil dibuat!"
            redirect_to time_blocks_path
        else
            @times = TimeBlock.all # Load data index
            render :index, status: :unprocessable_entity
        end 
    end

    private
    def time_block_params
        params.require(:time_block).permit(:order, :time)
    end
end
