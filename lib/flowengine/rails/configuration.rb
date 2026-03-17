# frozen_string_literal: true

module FlowEngine
  module Rails
    class Configuration
      attr_accessor :embed_allowed_origins,
                    :default_layout,
                    :embed_layout,
                    :cache_definitions,
                    :on_session_complete,
                    :admin_authentication_method

      def initialize
        @embed_allowed_origins = []
        @default_layout = "flow_engine/application"
        @embed_layout = "flow_engine/embed"
        @cache_definitions = true
        @on_session_complete = nil
        @admin_authentication_method = nil
      end
    end
  end
end
