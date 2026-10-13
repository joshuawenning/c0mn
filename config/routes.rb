Rails.application.routes.draw do
  get "login", to: "sessions#new", as: :new_session
  post "login", to: "sessions#create", as: :session
  delete "logout", to: "sessions#destroy", as: :logout
  resources :passwords, param: :token, only: %i[new create edit update]
  match "/:status", to: "errors#show", via: :all, constraints: { status: /404|422|500/ }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "about" => "pages#about", as: :about

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  namespace :admin do
    root "entries#index"
    resources :entries
  end

  resources :entries, only: %i[index show]

  root "entries#index"

  match "*unmatched", to: "errors#show", via: :all, defaults: { status: "404" }, constraints: ->(request) {
    !request.path.start_with?("/rails/") &&
      !%w[/recede_historical_location /resume_historical_location /refresh_historical_location].include?(request.path)
  }
end
