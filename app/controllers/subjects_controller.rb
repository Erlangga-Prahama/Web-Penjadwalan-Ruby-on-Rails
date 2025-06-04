class SubjectsController < ApplicationController
    def index
        @subjects = Subject.all
        @editSubject = Subject.find(params[:id]) if params[:id].present?

        render layout: "dash_layout"
    end

    def new
        @subject = Subject.new

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

    def  create
        @subject = Subject.new(subject_params)

        if @subject.save
            flash[:notice] = "Subject berhasil dibuat!"
            redirect_to subjects_path
        else
            @subjects = Subject.all # Load data index
            @show_modal = true # Flag untuk menampilkan modal
            render :index, layout: "dash_layout", status: :unprocessable_entity
        end
    end

    def edit
        @subject = Subject.find(params[:id])
        respond_to do |format|
            format.turbo_stream do
                render turbo_stream: turbo_stream.replace(
                    "edit-modal",
                    partial: "edit_modal",
                    locals: { subject: @subject }
                )
            end
        end
    end

    # app/controllers/subjects_controller.rb
    def update
        @subject = Subject.find(params[:id])

        if @subject.update(subject_params)
            redirect_to subjects_path, 
            notice: "Mata pelajaran berhasil diperbarui!"
        else
            render :edit, status: :unprocessable_entity
        end
    end
    
    def destroy
        @subject = Subject.find(params[:id])
        @subject.destroy

        redirect_to subjects_path
    end
    private
    def subject_params
        params.require(:subject).permit(:name)
    end
end
