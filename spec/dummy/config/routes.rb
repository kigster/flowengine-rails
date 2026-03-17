# frozen_string_literal: true

Rails.application.routes.draw do
  mount FlowEngine::Rails::Engine => "/flow_engine"
end
