Rails.application.routes.draw do
  resources :shares
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  get '/current_user', to: 'current_user#index'
  
  resources :users, only: [:index, :show, :destroy] do
    member do
      get :friends
    end
  end

  # Rutas para el sistema de amistades
  resources :friendships, only: [:index, :create, :update, :destroy] do
    get 'status/:user_id', on: :collection, to: 'friendships#status'
  end

  # Rutas para las publicaciones (posts)
  resources :posts, only: [:index, :show, :create, :update, :destroy]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
