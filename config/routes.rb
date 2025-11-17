Rails.application.routes.draw do

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  
  get 'class_rooms/index'
  get 'class_rooms/create'
  get 'class_rooms/edit'
  get 'class_rooms/update'
  get 'class_rooms/destroy'
  get 'password_resets/new'
  get 'password_resets/cerate'
  get 'password_resets/edit'
  get 'password_resets/update'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "dashboard#index"
  
  get  '/dashboard',  to: 'dashboard#index', as: :dashboard
  get  '/masuk',  to: 'sessions#new'
  post '/masuk',  to: 'sessions#create'
  delete '/keluar', to: 'sessions#destroy', as: :keluar
  
  get '/jadwal-mengajar', to: 'home#index', as: :jadwal_guru
  get '/jadwal-mengajar', to: 'home#jadwal', as: :jadwal_mengajar
  
  get 'unduh/jadwal/:id', to: 'schedules#export_excel', as: 'export_excel_schedule'


  resources :teachers, path: 'guru' do
    collection do
      patch :activate_all
      patch :deactivate_all
      get :by_subject
    end
  end

  resources :activities, path: 'kegiatan' do
    collection do
      get :time_blocks_for_day
      patch :activate_all
      patch :deactivate_all
    end
  end
  resources :days, path: 'hari' do
    collection do
      patch :activate_all
      patch :deactivate_all
    end
  end
  resources :users, path: 'akun'

  resources :subjects, path: 'mata-pelajaran' do
    collection do
      patch :activate_all
      patch :deactivate_all
      get :edit # untuk edit via turbo stream
    end
  end

  resources :class_rooms, path: 'kelas' do
    collection do
      patch :activate_all
      patch :deactivate_all
    end
  end

  resources :time_blocks, path: 'jam-pelajaran' do
    collection do
      patch :activate_all
      patch :deactivate_all
      get :edit # untuk edit via turbo stream
    end
  end

  resources :unavailable_times

  resources :schedules, path: 'jadwal' do
    collection do
      get :preview, path: 'draft-jadwal'
      get :preview_generated, path: 'jadwal-diajukan'
      get :new_teach
      post :replace_teacher
      post :finalize
      post :generate_all
      post :save_generated
      delete :destroy_draft
    end
  end

  resources :schedule_batches do
  member do
    get :preview_generated
  end
end


  
  resources :password_resets
  

end
