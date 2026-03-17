# frozen_string_literal: true

module FlowEngine
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install FlowEngine: copy migrations, create initializer, add mount route"

      def copy_migrations
        rake "flow_engine:install:migrations"
      end

      def create_initializer
        template "initializer.rb", "config/initializers/flow_engine.rb"
      end

      def add_route
        route 'mount FlowEngine::Rails::Engine => "/flow_engine"'
      end

      def show_post_install
        say ""
        say "FlowEngine installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Run migrations:  rails db:migrate"
        say "  2. Edit config/initializers/flow_engine.rb"
        say "  3. Create a flow:   rails generate flow_engine:flow my_intake"
        say ""
      end
    end
  end
end
