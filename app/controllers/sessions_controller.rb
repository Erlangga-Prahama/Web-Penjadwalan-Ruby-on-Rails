class SessionsController < ApplicationController
    before_action :redirect_if_logged_in, only: [:new, :create]
    
    def new

    end

    def create
        if params[:email].blank? || params[:password].blank?
            flash.now[:danger] = "Email dan kata sandi tidak boleh kosong"
            @entered_email = params[:email]
            render :new, status: :unprocessable_entity
            return
        end

        user = User.find_by(email: params[:email])
        if user&.authenticate(params[:password])
            session[:user_id] = user.id
            flash[:success] = "Login berhasil, Selamat Datang!"
            redirect_to after_login_path_for(user)
        else
            flash.now[:danger] = "Email atau kata sandi anda salah"
            @entered_email = params[:email]
            render :new, status: :unprocessable_entity
        end
    end

    def destroy
        session.delete(:user_id)
        redirect_to masuk_path, notice: "Logout berhasil"
    end

    private

    def after_login_path_for(user)
        case user.role
        when "kepala_sekolah"
            root_path
        when "waka_kurikulum"
            root_path
        else
            jadwal_guru_path
        end
    end

    def redirect_if_logged_in
        if current_user
            redirect_to after_login_path_for(current_user), alert: "Anda sudah login"
        end
    end
end
