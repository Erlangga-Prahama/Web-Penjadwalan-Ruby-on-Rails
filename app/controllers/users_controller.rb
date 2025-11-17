class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_access
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    load_users

    render layout: "dash_layout"
  end

  def new
    @user = User.new
    @teachers = Teacher.left_outer_joins(:user).where(users: { id: nil }).order(:nama)

    respond_to do |format|
        format.turbo_stream do
            render turbo_stream: turbo_stream.update(
                "new",
                partial: "new",
                locals: { user: @user, teachers: @teachers }
            )
        end
    end
  end

  def create
    @user = User.new(user_params)

    if @user.save
        flash[:success] = "Akun berhasil dibuat!"
        redirect_to users_path
    else
        load_users
        @teachers = Teacher.left_outer_joins(:user).where(users: { id: nil })
        @show_new_modal = true # Flag untuk menampilkan modal
        render :index, layout: "dash_layout", status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
    @teachers = Teacher.left_outer_joins(:user).or(Teacher.where(id: @user.teacher_id))

    respond_to do |format|
      format.turbo_stream do
          render turbo_stream: turbo_stream.update(
              "edit",
              partial: "edit",
              locals: { user: @user, teachers: @teachers }
          )
      end
    end
  end

  def update
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    if @user.update(user_params)
      flash[:success] = "Akun berhasil diedit!"
      redirect_to users_path
    else
      load_users
      @teachers = Teacher.left_outer_joins(:user).where(users: { id: nil })
      @show_edit_modal = true # Flag untuk menampilkan modal
      render :index, layout: "dash_layout", status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy

    flash[:success] = "Akun berhasil dihapus!"
    redirect_to users_path
  end
  
  def authorize_access
    if current_user.role == "guru" && !%w[edit update].include?(action_name)
        redirect_to root_path, alert: "Guru hanya boleh mengedit akun."
      elsif !%w[waka_kurikulum guru kepala_sekolah].include?(current_user.role)
        redirect_to root_path, alert: "Kamu tidak diizinkan mengakses halaman ini."
      end
  end
  
  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :teacher_id)
  end

  def load_users
    @q = params[:q]
    @users = if @q.present?
                User.joins(:teacher).where(
                  "users.email ILIKE :q OR users.role ILIKE :q OR teachers.nama ILIKE :q",
                  q: "%#{@q}%"
                ).includes(:teacher)
              else
                User.includes(:teacher)
              end

    @users = @users.order(Arel.sql("
                  CASE users.role
                    WHEN 'kepala_sekolah' THEN 1
                    WHEN 'waka_kurikulum' THEN 2
                    ELSE 3
                  END, users.email
                ")).page(params[:page]).per(8)
  end
end
