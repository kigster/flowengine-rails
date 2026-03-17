# frozen_string_literal: true

FlowEngine::Rails.configure do |config|
  config.embed_allowed_origins = ["*"]
  config.cache_definitions = false
end
