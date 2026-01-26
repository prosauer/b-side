Rails.application.routes.draw do
  devise_for :users

  # Root path - dashboard for logged in users
  root "dashboard#index"

  # Dashboard
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "tidal/connect", to: "tidal_connections#connect", as: :tidal_connect
  get "tidal/callback", to: "tidal_connections#callback", as: :tidal_callback

  # Tidal OAuth
  get  "/auth/tidal",          to: "tidal_connections#connect",    as: :tidal_connections_connect
  get  "/auth/tidal/callback", to: "tidal_connections#callback", as: :tidal_connections_callback


  # Groups
  resources :groups do
    resources :seasons, only: [ :index, :new, :create, :show ] do
      resources :weeks, only: [ :index, :show, :edit, :update ] do
        member do
          post :generate_playlist
        end
        resources :submissions, only: [ :index, :new, :create, :show, :update ] do
          collection do
            get :search
          end
        end
      end
    end
    member do
      get :invite
    end
    # Leaderboards
    get "leaderboard/weekly/:week_id", to: "leaderboards#weekly", as: :weekly_leaderboard
    get "leaderboard/season/:season_id", to: "leaderboards#season", as: :season_leaderboard
    get "leaderboard/all_time", to: "leaderboards#all_time", as: :all_time_leaderboard
  end

  # Invite flow
  get "join/:invite_code", to: "invites#show", as: :join
  post "join/:invite_code", to: "invites#accept", as: :accept_invite

  # Votes (nested under submissions)
  resources :submissions, only: [] do
    resources :votes, only: [ :create ]
  end
  post "weeks/:week_id/votes", to: "votes#bulk_update", as: :week_votes

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
