# frozen_string_literal: true

require "flowengine"
require_relative "rails/version"
require_relative "rails/configuration"
require_relative "rails/dsl_loader"
require_relative "rails/engine"

module FlowEngine
  module Rails
    class Error < StandardError; end

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        @configuration = Configuration.new
      end
    end
  end
end
