class PasswordResetsController < ApplicationController
  def new
  end

  def create
    @user = User.find_by(email: params[:email])
    if @user
      @user.generate_password_reset_token!
      PasswordResetMailer.with(user: @user).reset_email.deliver_now
      flash[:success] = "Link reset kata sandi telah dikirim ke email."
      redirect_to masuk_path
    else
      flash.now[:danger] = "Email tidak ditemukan."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find_by(reset_password_token: params[:id])
    unless @user&.password_token_valid?
      redirect_to new_password_reset_path, danger: "Token tidak valid atau kadaluarsa."
    end
  end

  def update
    @user = User.find_by(reset_password_token: params[:id])
    if @user&.password_token_valid?
      if @user.reset_password!(params[:user][:password], params[:user][:password_confirmation])
        redirect_to masuk_path, notice: "Kata sandi berhasil diubah."
      else
        flash.now[:danger] = "Gagal mengubah kata sandi."
        puts @user.errors.full_messages
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to new_password_reset_path, danger: "Token tidak valid atau kadaluarsa."
    end
  end

  private
  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
