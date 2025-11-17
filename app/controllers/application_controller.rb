class ApplicationController < ActionController::Base
    helper_method :current_user

    def current_user
        @current_user ||= User.find_by(id: session[:user_id])
    end
    
    def authenticate_user!
        unless current_user
            flash[:danger] = "Silahkan login terlebih dahulu!"
            redirect_to masuk_path
        end
    end

    def require_role(*roles)
        unless current_user && roles.include?(current_user.role)
            flash[:danger] = "Anda tidak memiliki akses ke halaman ini"
            redirect_to after_login_path_for(current_user)
        end
    end
end
