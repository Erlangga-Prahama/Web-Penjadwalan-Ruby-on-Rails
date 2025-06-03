Rails.application.routes.draw do
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
  get "login", to: "login#index"
  get "guru", to: "teachers#index"
  get "show", to: "teachers#show"

  resources :teachers, only: [:create, :update, :destroy]

  resources :subjects do
    member do
      get :edit # untuk edit via turbo stream
    end
  end

  resources :class_rooms do
    member do
      get :edit # untuk edit via turbo stream
    end
  end

  resources :time_blocks do
    member do
      get :edit # untuk edit via turbo stream
    end
  end

  resources :password_resets, only: [:new, :create, :edit, :update]

  get "mata-pelajaran", to: "subjects#index"
  get "kelas", to: "class_rooms#index"
  get "jam-pelajaran", to: "time_blocks#index"
  

end
