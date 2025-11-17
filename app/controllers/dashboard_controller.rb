class DashboardController < ApplicationController
    before_action :authenticate_user!
    before_action -> { require_role("kepala_sekolah", "waka_kurikulum") }
  
    def index 
        render layout: "dash_layout"
    end
end
