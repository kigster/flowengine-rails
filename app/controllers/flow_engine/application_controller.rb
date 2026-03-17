# frozen_string_literal: true

module FlowEngine
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :detect_embed_mode
    before_action :set_cors_headers, if: :embed_mode?

    helper_method :embed_mode?

    private

    def detect_embed_mode
      @embed_mode = params[:embed] == "true"
    end

    def embed_mode?
      @embed_mode
    end

    def set_cors_headers
      allowed_origins = FlowEngine::Rails.configuration.embed_allowed_origins
      origin = request.headers["Origin"]

      return unless origin && (allowed_origins.include?("*") || allowed_origins.include?(origin))

      response.headers["Access-Control-Allow-Origin"] = origin
      response.headers["Access-Control-Allow-Methods"] = "GET, POST, PATCH"
      response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    end

    def current_layout
      if embed_mode?
        FlowEngine::Rails.configuration.embed_layout
      else
        FlowEngine::Rails.configuration.default_layout
      end
    end
  end
end
