# frozen_string_literal: true

FlowEngine::Rails::Engine.routes.draw do
  resources :sessions, only: %i[new create show update] do
    member do
      get :completed
      patch :abandon
    end
  end

  namespace :admin do
    resources :definitions do
      member do
        post :activate
        post :deactivate
        get :mermaid
      end
    end
  end

  root to: "sessions#new"
end
