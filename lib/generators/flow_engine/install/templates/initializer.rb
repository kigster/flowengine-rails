# frozen_string_literal: true

FlowEngine::Rails.configure do |config|
  # Origins allowed to embed the flow widget via iframe.
  # Use ["*"] to allow all origins, or specify domains:
  # config.embed_allowed_origins = ["https://example.com"]
  config.embed_allowed_origins = []

  # Layout used for regular (non-embedded) flow sessions
  # config.default_layout = "flow_engine/application"

  # Layout used for embedded (iframe) flow sessions
  # config.embed_layout = "flow_engine/embed"

  # Cache parsed DSL definitions in memory (recommended for production)
  config.cache_definitions = Rails.env.production?

  # Callback fired when a session is completed.
  # Receives the completed FlowEngine::Session instance.
  # config.on_session_complete = ->(session) { MyNotifier.flow_completed(session) }

  # Method name to call on ApplicationController for admin authentication.
  # Set to nil to disable (open admin). Example: :authenticate_admin!
  # config.admin_authentication_method = :authenticate_admin!
end
