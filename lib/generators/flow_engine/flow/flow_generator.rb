# frozen_string_literal: true

module FlowEngine
  module Generators
    class FlowGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Generate a flow definition file and seed task"

      def create_flow_definition
        template "flow_definition.rb.tt", "db/flow_definitions/#{file_name}.rb"
      end

      def create_seed_task
        template "seed_task.rake.tt", "lib/tasks/flow_engine_#{file_name}.rake"
      end

      def show_next_steps
        say ""
        say "Flow definition created!", :green
        say ""
        say "Next steps:"
        say "  1. Edit db/flow_definitions/#{file_name}.rb"
        say "  2. Seed it:  rails flow_engine:seed:#{file_name}"
        say ""
      end
    end
  end
end
